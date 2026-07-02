import { Injectable, NotFoundException } from '@nestjs/common';
import { KycStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { KycProvider } from './kyc-provider.interface';

/**
 * Manual, human-review KYC provider — the current in-house flow. Verification decisions
 * are taken by administrators through the /admin/kyc/* endpoints, so there is no external
 * system to notify. This keeps KycService provider-agnostic: a future third-party provider
 * only has to implement {@link KycProvider} and be bound to the KYC_PROVIDER token.
 */
@Injectable()
export class ManualKycProvider implements KycProvider {
  constructor(private readonly prisma: PrismaService) {}

  async submitForVerification(): Promise<void> {
    // Manual review: nothing to dispatch to an external provider.
  }

  async getVerificationStatus(submissionId: string): Promise<KycStatus> {
    const submission = await this.prisma.kycSubmission.findUnique({
      where: { id: submissionId },
      select: { status: true },
    });

    if (!submission) {
      throw new NotFoundException('KYC submission not found.');
    }

    return submission.status;
  }

  async revokeVerification(): Promise<void> {
    // Manual review: revocation is recorded by the admin endpoint; no external call.
  }
}
