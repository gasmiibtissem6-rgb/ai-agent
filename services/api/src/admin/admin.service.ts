// admin.service.ts
import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  // 1. User Directory Data
  async getUsersDirectory(page = 1, limit = 10) {
    const skip = (page - 1) * limit;

    const [users, total] = await Promise.all([
      this.prisma.profile.findMany({
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          displayName: true,
          email: true,
          kycStatus: true,
          isAdmin: true,
          adminRole: true,
          createdAt: true,
          trustCounter: {
            select: {
              successfulDeals: true,
              ongoingDeals: true,
              breachedDeals: true,
            },
          },
        },
      }),
      this.prisma.profile.count(),
    ]);

    return {
      users,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  // 2. Trust Metrics Override
  async overrideTrustCounters(
    targetProfileId: string,
    adminId: string,
    metrics: { successfulDeals: number; ongoingDeals: number; breachedDeals: number },
    reason: string,
  ) {
    if (!reason) {
      throw new BadRequestException('An explicit reason is required to override system metrics.');
    }

    return this.prisma.$transaction(async (tx) => {
      // Upsert trust counter record if it doesn't exist yet
      const updatedCounter = await tx.trustCounter.upsert({
        where: { profileId: targetProfileId },
        update: {
          successfulDeals: metrics.successfulDeals,
          ongoingDeals: metrics.ongoingDeals,
          breachedDeals: metrics.breachedDeals,
        },
        create: {
          profileId: targetProfileId,
          successfulDeals: metrics.successfulDeals,
          ongoingDeals: metrics.ongoingDeals,
          breachedDeals: metrics.breachedDeals,
        },
      });

      // Log trace block
      await tx.adminAction.create({
        data: {
          adminProfileId: adminId,
          actionType: 'ADMIN_ACTION',
          targetResourceType: 'TrustCounter',
          targetResourceId: updatedCounter.id,
          reason,
          metadataJson: { modifications: metrics },
        },
      });

      return updatedCounter;
    });
  }
}
