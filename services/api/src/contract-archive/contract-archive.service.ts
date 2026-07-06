import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { DealStatus } from '@prisma/client';

@Injectable()
export class ContractArchiveService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Fetches all archived/locked contracts for the read-only historical repository
   */
  async getArchivedContracts(filters: {
    status?: DealStatus;
    search?: string;
    page: number;
    limit: number;
  }) {
    const { status, search, page, limit } = filters;
    const skip = (page - 1) * limit;

    const whereCondition: any = {
      status: {
        in: [DealStatus.APPROVED, DealStatus.LOCKED, DealStatus.ARCHIVED],
      },
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

    const [contracts, totalCount] = await Promise.all([
      this.prisma.deal.findMany({
        where: whereCondition,
        include: {
          creator: { select: { displayName: true, email: true } },
          company: { select: { legalName: true } },
          parties: { select: { id: true, partyStatus: true } },
          versions: {
            select: {
              id: true,
              versionNumber: true,
              status: true,
              lockedAt: true,
            },
            orderBy: { versionNumber: 'desc' },
          },
        },
        orderBy: { updatedAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.deal.count({ where: whereCondition }),
    ]);

    const items = contracts.map((contract) => ({
      id: contract.id,
      title: contract.title,
      company: (contract as any).company?.legalName || 'Individual',
      creator:
        (contract as any).creator.displayName ||
        (contract as any).creator.email,
      status: contract.status,
      participantsCount: (contract as any).parties.length,
      versionsCount: (contract as any).versions.length,
      lockedAt: contract.lockedVersionId
        ? (contract as any).versions.find(
            (v: any) => v.id === contract.lockedVersionId,
          )?.lockedAt
        : null,
      createdAt: contract.createdAt,
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
   * Fetches complete version history tree for a specific contract
   */
  async getContractVersionHistory(dealId: string) {
    const deal = await this.prisma.deal.findUnique({
      where: { id: dealId },
      include: {
        creator: { select: { displayName: true, email: true } },
        company: { select: { legalName: true } },
        versions: {
          include: {
            createdBy: { select: { displayName: true, email: true } },
            approvals: {
              include: {
                profile: { select: { displayName: true, email: true } },
                party: { select: { email: true, role: true } },
              },
              orderBy: { decidedAt: 'desc' },
            },
            files: {
              select: { id: true, originalFileName: true, storagePath: true },
            },
          },
          orderBy: { versionNumber: 'asc' },
        },
      },
    });

    if (!deal)
      throw new NotFoundException('Contract record not found in archive.');

    // Build version history tree structure
    const versionTree = (deal as any).versions.map((version: any) => ({
      id: version.id,
      versionNumber: version.versionNumber,
      status: version.status,
      title: version.title,
      summary: version.summary,
      termsJson: version.termsJson,
      sourceVersionId: version.sourceVersionId,
      submittedAt: version.submittedAt,
      lockedAt: version.lockedAt,
      createdAt: version.createdAt,
      createdBy: version.createdBy,
      approvals: version.approvals,
      files: version.files,
      isLockedVersion: deal.lockedVersionId === version.id,
    }));

    return {
      contract: {
        id: deal.id,
        title: deal.title,
        description: deal.description,
        status: deal.status,
        creator: (deal as any).creator,
        company: (deal as any).company,
        lockedVersionId: deal.lockedVersionId,
        createdAt: deal.createdAt,
      },
      versionHistory: versionTree,
    };
  }

  /**
   * Fetches a specific version's full details for compliance inspection
   */
  async getVersionDetails(versionId: string) {
    const version = await this.prisma.dealVersion.findUnique({
      where: { id: versionId },
      include: {
        deal: {
          include: {
            creator: { select: { displayName: true, email: true } },
            company: { select: { legalName: true } },
          },
        },
        createdBy: { select: { displayName: true, email: true } },
        approvals: {
          include: {
            profile: { select: { displayName: true, email: true } },
            party: { select: { email: true, role: true } },
          },
          orderBy: { decidedAt: 'desc' },
        },
        files: true,
        sourceVersion: {
          select: { id: true, versionNumber: true, title: true },
        },
      },
    });

    if (!version)
      throw new NotFoundException('Version record not found in archive.');

    return version as any;
  }
}
