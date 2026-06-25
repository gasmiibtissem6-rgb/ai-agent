// kyc.service.ts
import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service'; // Adjust relative path
import { KycStatus } from '@prisma/client';

@Injectable()
export class KycService {
  constructor(private readonly prisma: PrismaService) {}

  // 1. Triggered by a user when they initialize a verification attempt
  async initiateSubmission(profileId: string, providerReference?: string) {
    const existingActive = await this.prisma.kycSubmission.findFirst({
      where: {
        profileId,
        status: { in: [KycStatus.SUBMITTED, KycStatus.UNDER_REVIEW] },
      },
    });

    if (existingActive) {
      throw new ConflictException('You already have an active verification submission pending review.');
    }

    return this.prisma.$transaction(async (tx) => {
      const submission = await tx.kycSubmission.create({
        data: {
          profileId,
          status: KycStatus.SUBMITTED,
          providerReference,
          submittedAt: new Date(),
        },
      });

      await tx.profile.update({
        where: { id: profileId },
        data: { kycStatus: KycStatus.SUBMITTED },
      });

      return submission;
    });
  }

  // 2. Automated processing engine for 3rd-party Webhook updates
  async handleWebhookStatusUpdate(providerReference: string, externalStatus: string, rejectionReason?: string) {
    const submission = await this.prisma.kycSubmission.findFirst({
      where: { providerReference },
    });

    if (!submission) {
      throw new NotFoundException(`KYC submission tracing reference ${providerReference} not found.`);
    }

    // Map external vendor string payloads cleanly to your database Prisma Enums
    let targetStatus: KycStatus = KycStatus.UNDER_REVIEW;
    if (externalStatus === 'verified' || externalStatus === 'approved') targetStatus = KycStatus.APPROVED;
    if (externalStatus === 'requires_input' || externalStatus === 'rejected') targetStatus = KycStatus.REJECTED;

    return this.prisma.$transaction(async (tx) => {
      const updatedSubmission = await tx.kycSubmission.update({
        where: { id: submission.id },
        data: {
          status: targetStatus,
          rejectionReason: rejectionReason || null,
          updatedAt: new Date(),
        },
      });

      await tx.profile.update({
        where: { id: submission.profileId },
        data: { kycStatus: targetStatus },
      });

      // Handle automatic system notifications for changes
      await tx.notification.create({
        data: {
          profileId: submission.profileId,
          notificationType: 'KYC_UPDATED',
          title: `Identity Verification Status Update`,
          body: `Your identity verification status has shifted to ${targetStatus.toLowerCase()}.`,
          payloadJson: { submissionId: submission.id, status: targetStatus },
        },
      });

      return updatedSubmission;
    });
  }
}