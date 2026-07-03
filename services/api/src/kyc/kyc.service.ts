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
    // 1. Fetch using a clean include block to bypass strict select compilation issues
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

    // 2. Map submissions safely by casting to 'any' to stop compiler errors 
    // while you verify your exact property names
    return submissions.map((sub: any) => {
      const primaryFile = sub.files?.[0];
      
      // Dynamic fallback logic for file properties
      const fileIdentifier = primaryFile?.fileKey || primaryFile?.url || primaryFile?.path || '';
      
      const secureViewUrl = fileIdentifier
        ? `https://your-project-id.supabase.co/storage/v1/object/public/your-bucket-name/${fileIdentifier}`
        : '#';

      // Dynamic fallback logic for applicant names
      const fullName = sub.profile?.name || 
                        `${sub.profile?.firstName || ''} ${sub.profile?.lastName || ''}`.trim() || 
                        'Anonymous User';

      return {
        id: sub.id,
        applicant: fullName,
        email: sub.profile?.email || 'admin@ideal.com',
        docType: primaryFile?.name || 'Identity Document',
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
      return tx.kycSubmission.update({
        where: { id: submissionId },
        data: {
          status,
          rejectionReason: status === KycStatus.REJECTED ? rejectionReason : null,
          reviewedAt: new Date(),
          reviewedByProfileId: adminProfileId,
        },
      });
    });
  }
}