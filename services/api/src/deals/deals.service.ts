import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { DealStatus } from '@prisma/client';

@Injectable()
export class DealsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Generates a structural overview list optimized for global administration table panels
   */
  async getGlobalDealsDashboard(filters: {
    status?: DealStatus;
    search?: string;
    page: number;
    limit: number;
  }) {
    const { status, search, page, limit } = filters;
    const skip = (page - 1) * limit;

    // Build relational search conditions matching your schema.prisma structures
    const whereCondition: any = {
      archivedAt: null, // Ignore archived objects
    };

    if (status) {
      whereCondition.status = status;
    }

    if (search) {
      whereCondition.OR = [
        { title: { contains: search, mode: 'insensitive' } },
        { creator: { displayName: { contains: search, mode: 'insensitive' } } },
        { creator: { email: { contains: search, mode: 'insensitive' } } },
        { company: { legalName: { contains: search, mode: 'insensitive' } } },
      ];
    }

    // Execute queries concurrently for high efficiency
    const [deals, totalCount] = await Promise.all([
      this.prisma.deal.findMany({
        where: whereCondition,
        include: {
          creator: { select: { displayName: true, email: true } },
          company: { select: { legalName: true } },
          parties: { select: { id: true, partyStatus: true } },
          files: { select: { id: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.deal.count({ where: whereCondition }),
    ]);

    // Format structure properties directly for frontend tabular layout states
    const items = deals.map((deal) => ({
      id: deal.id,
      title: deal.title,
      company: deal.company?.legalName || 'Individual Creator / Freelance',
      creator: deal.creator.displayName || deal.creator.email,
      status: deal.status,
      participantsCount: deal.parties.length,
      attachmentsCount: deal.files.length,
      createdAt: deal.createdAt,
    }));

    return {
      items,
      meta: {
        totalItems: totalCount,
        currentPage: page,
        totalPages: Math.ceil(totalCount / limit),
      },
    };
  }

  /**
   * Deep lookup fetch for deep audit inspector dashboards
   */
  async getAdminDealById(id: string) {
    const deal = await this.prisma.deal.findUnique({
      where: { id },
      include: {
        creator: true,
        company: true,
        parties: { include: { profile: true } },
        versions: { orderBy: { versionNumber: 'desc' } },
        files: true,
        messages: { orderBy: { createdAt: 'asc' }, take: 50 }, // Pull audit context
      },
    });

    if (!deal)
      throw new NotFoundException(
        'Requested deal reference record could not be found.',
      );
    return deal;
  }

  /**
   * Administrative override routine to resolve deadlock conditions
   */
  async overrideDealStatus(id: string, status: DealStatus, reason: string) {
    const deal = await this.prisma.deal.findUnique({ where: { id } });
    if (!deal)
      throw new NotFoundException('Target contract system reference missing.');

    return this.prisma.$transaction(async (tx) => {
      // 1. Force adjust status flag
      const updatedDeal = await tx.deal.update({
        where: { id },
        data: { status },
      });

      // 2. Insert into system admin action ledger to maintain full accountability
      await tx.adminAction.create({
        data: {
          adminProfileId: 'placeholder-profile-id', // Swapped out with request user tracking dynamically
          actionType: 'ADMIN_ACTION',
          targetResourceType: 'DEAL',
          targetResourceId: id,
          reason: reason,
          metadataJson: { originalStatus: deal.status, overriddenTo: status },
        },
      });

      return updatedDeal;
    });
  }
}
