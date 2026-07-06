import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { KycStatus } from '@prisma/client';

@Injectable()
export class KycService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Fetches the queue data tailored precisely for your Next.js Table view
   */
  async getPendingSubmissions() {
    // 1. Fetch using clear relation include blocks matching your exact schema models
    const submissions = await this.prisma.kycSubmission.findMany({
      where: {
        status: KycStatus.SUBMITTED,
      },
      include: {
        profile: true,
        files: true,
      },
      orderBy: { createdAt: 'asc' },
    });

    // 2. Map submissions cleanly utilizing exact schema properties
    return submissions.map((sub) => {
      const primaryFile = sub.files?.[0];
      
      // Map to your precise schema keys: storagePath and storageBucket
      const path = primaryFile?.storagePath || '';
      const bucket = primaryFile?.storageBucket || 'kyc-documents';
      
      const secureViewUrl = path
        ? `https://your-project-id.supabase.co/storage/v1/object/public/${bucket}/${path}`
        : '#';

      // Map to your precise schema key: displayName (with email fallback)
      const applicantName = sub.profile?.displayName || sub.profile?.email || 'Anonymous User';

      return {
        id: sub.id,
        applicant: applicantName,
        email: sub.profile?.email || 'admin@ideal.com',
        docType: primaryFile?.originalFileName || 'Identity Document', // Maps to your schema's originalFileName
        idNumber: sub.providerReference || 'N/A', 
        fileLink: secureViewUrl,
        submittedAt: sub.submittedAt,
      };
    });
  }

  /**
   * Commits state changes matching your schema constraints
   */
  async processReview(
    submissionId: string,
    adminProfileId: string,
    status: KycStatus,
    rejectionReason?: string
  ) {
    const submission = await this.prisma.kycSubmission.findUnique({
      where: { id: submissionId },
    });

    if (!submission) {
      throw new NotFoundException('Target KYC submission details record not found.');
    }

    if (submission.status !== KycStatus.SUBMITTED) {
      throw new BadRequestException('This submission has already been processed.');
    }

    return this.prisma.$transaction(async (tx) => {
      // 1. Update the KYC Submission state record
      const updatedSubmission = await tx.kycSubmission.update({
        where: { id: submissionId },
        data: {
          status,
          rejectionReason: status === KycStatus.REJECTED ? rejectionReason : null,
          reviewedAt: new Date(),
          reviewedByProfileId: adminProfileId,
        },
      });

      // 2. Cascade update the corresponding status enum directly on the User Profile table
      await tx.profile.update({
        where: { id: submission.profileId },
        data: {
          kycStatus: status, // Syncs 'APPROVED' or 'REJECTED' to profile.kyc_status
        },
      });

      return updatedSubmission;
    });
  }
}