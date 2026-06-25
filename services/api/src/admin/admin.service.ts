// admin.service.ts
import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service'; // Adjust path to your PrismaService
import { KycStatus } from '@prisma/client';

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

  // 2. Identity Verification Queue
  async getPendingKycQueue() {
    return this.prisma.kycSubmission.findMany({
      where: {
        status: { in: [KycStatus.SUBMITTED, KycStatus.UNDER_REVIEW] },
      },
      include: {
        profile: {
          select: {
            id: true,
            displayName: true,
            email: true,
          },
        },
        files: {
          where: { fileType: 'KYC_DOCUMENT' },
        },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async reviewKycSubmission(
    submissionId: string,
    adminId: string,
    status: 'APPROVED' | 'REJECTED',
    reason?: string,
  ) {
    const submission = await this.prisma.kycSubmission.findUnique({
      where: { id: submissionId },
    });

    if (!submission) {
      throw new NotFoundException('KYC submission record not found.');
    }

    return this.prisma.$transaction(async (tx) => {
      // Update submission record
      const updatedSubmission = await tx.kycSubmission.update({
        where: { id: submissionId },
        data: {
          status: status as KycStatus,
          rejectionReason: reason || null,
          reviewedAt: new Date(),
          reviewedByProfileId: adminId,
        },
      });

      // Update global profile validation state
      await tx.profile.update({
        where: { id: submission.profileId },
        data: { kycStatus: status as KycStatus },
      });

      // Log action to operational ledger
      await tx.adminAction.create({
        data: {
          adminProfileId: adminId,
          actionType: status === 'APPROVED' ? 'KYC_APPROVED' : 'KYC_REJECTED',
          targetResourceType: 'KycSubmission',
          targetResourceId: submissionId,
          reason,
          metadataJson: { processedAt: new Date() },
        },
      });

      return updatedSubmission;
    });
  }

  // 3. Trust Metrics Override
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