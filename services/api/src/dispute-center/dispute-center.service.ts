import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ReportStatus } from '@prisma/client';

@Injectable()
export class DisputeCenterService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Fetches all dispute tickets with filtering and pagination
   */
  async getDisputeTickets(filters: {
    status?: ReportStatus;
    resourceType?: string;
    search?: string;
    page: number;
    limit: number;
  }) {
    const { status, resourceType, search, page, limit } = filters;
    const skip = (page - 1) * limit;

    const whereCondition: any = {};

    if (status) {
      whereCondition.status = status;
    }

    if (resourceType) {
      whereCondition.resourceType = resourceType;
    }

    if (search) {
      whereCondition.OR = [
        { reason: { contains: search, mode: 'insensitive' } },
        { reporter: { displayName: { contains: search, mode: 'insensitive' } } },
        { reporter: { email: { contains: search, mode: 'insensitive' } } },
        { resolution: { contains: search, mode: 'insensitive' } },
      ];
    }

    const [tickets, totalCount] = await Promise.all([
      this.prisma.report.findMany({
        where: whereCondition,
        include: {
          reporter: { select: { displayName: true, email: true } },
          reviewedBy: { select: { displayName: true, email: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.report.count({ where: whereCondition }),
    ]);

    const items = tickets.map((ticket: any) => ({
      id: ticket.id,
      resourceType: ticket.resourceType,
      resourceId: ticket.resourceId,
      status: ticket.status,
      reason: ticket.reason,
      resolution: ticket.resolution,
      reporter: ticket.reporter.displayName || ticket.reporter.email,
      reviewedBy: ticket.reviewedBy?.displayName || ticket.reviewedBy?.email || null,
      createdAt: ticket.createdAt,
      reviewedAt: ticket.reviewedAt,
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
   * Fetches specific dispute ticket details
   */
  async getDisputeTicketById(id: string) {
    const ticket = await this.prisma.report.findUnique({
      where: { id },
      include: {
        reporter: true,
        reviewedBy: true,
      },
    });

    if (!ticket) throw new NotFoundException('Dispute ticket not found.');

    return ticket as any;
  }

  /**
   * Updates dispute ticket status and resolution
   */
  async updateDisputeTicket(
    id: string,
    adminProfileId: string,
    data: {
      status: ReportStatus;
      resolution?: string;
    }
  ) {
    const ticket = await this.prisma.report.findUnique({ where: { id } });
    if (!ticket) throw new NotFoundException('Dispute ticket not found.');

    return this.prisma.$transaction(async (tx) => {
      // Update the ticket
      const updatedTicket = await tx.report.update({
        where: { id },
        data: {
          status: data.status,
          resolution: data.resolution,
          reviewedByProfileId: adminProfileId,
          reviewedAt: new Date(),
        },
      });

      // Log admin action
      await tx.adminAction.create({
        data: {
          adminProfileId,
          actionType: 'ADMIN_ACTION',
          targetResourceType: 'REPORT',
          targetResourceId: id,
          reason: `Dispute ticket ${data.status}`,
          metadataJson: {
            originalStatus: ticket.status,
            newStatus: data.status,
            resolution: data.resolution,
          },
        },
      });

      return updatedTicket;
    });
  }

  /**
   * Pauses deal progression for disputed contracts
   */
  async pauseDealForDispute(dealId: string, adminProfileId: string, reason: string) {
    const deal = await this.prisma.deal.findUnique({ where: { id: dealId } });
    if (!deal) throw new NotFoundException('Deal not found.');

    return this.prisma.$transaction(async (tx) => {
      // Update deal status to indicate dispute pause
      const updatedDeal = await tx.deal.update({
        where: { id: dealId },
        data: {
          status: 'CHANGES_REQUESTED', // Using existing status to indicate pause
        },
      });

      // Log admin action
      await tx.adminAction.create({
        data: {
          adminProfileId,
          actionType: 'ADMIN_ACTION',
          targetResourceType: 'DEAL',
          targetResourceId: dealId,
          reason: `Deal paused due to dispute: ${reason}`,
          metadataJson: {
            originalStatus: deal.status,
            pausedForDispute: true,
          },
        },
      });

      return updatedDeal;
    });
  }

  /**
   * Suspends user account due to fraud reports
   */
  async suspendProfileForFraud(profileId: string, adminProfileId: string, reason: string) {
    const profile = await this.prisma.profile.findUnique({ where: { id: profileId } });
    if (!profile) throw new NotFoundException('Profile not found.');

    return this.prisma.$transaction(async (tx) => {
      // Archive profile (soft delete)
      const updatedProfile = await tx.profile.update({
        where: { id: profileId },
        data: {
          archivedAt: new Date(),
        },
      });

      // Log admin action
      await tx.adminAction.create({
        data: {
          adminProfileId,
          actionType: 'ADMIN_ACTION',
          targetResourceType: 'PROFILE',
          targetResourceId: profileId,
          reason: `Profile suspended for fraud: ${reason}`,
          metadataJson: {
            suspendedForFraud: true,
          },
        },
      });

      return updatedProfile;
    });
  }

  /**
   * Creates a new dispute ticket (for users)
   */
  async createDisputeTicket(data: {
    reporterProfileId: string;
    resourceType: string;
    resourceId: string;
    reason: string;
  }) {
    return this.prisma.report.create({
      data: {
        reporterProfileId: data.reporterProfileId,
        resourceType: data.resourceType,
        resourceId: data.resourceId,
        reason: data.reason,
        status: ReportStatus.OPEN,
      },
    });
  }
}
