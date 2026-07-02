// admin-kyc.service.ts
import {
  BadRequestException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { AuditActionType, KycStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { KycStorageService } from '../kyc/storage/kyc-storage.service';
import { KYC_PROVIDER } from '../kyc/providers/kyc-provider.interface';
import type { KycProvider } from '../kyc/providers/kyc-provider.interface';
import { KycQueueQueryDto } from './dto/kyc-queue-query.dto';

/** Request context captured on audit records (never contains personal data or paths). */
export interface AuditContext {
  ipAddress?: string;
  userAgent?: string;
}

/** Signed download URL lifetime for admin document viewing (seconds). */
const DOWNLOAD_URL_TTL_SECONDS = 300;

@Injectable()
export class AdminKycService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: KycStorageService,
    @Inject(KYC_PROVIDER) private readonly provider: KycProvider,
  ) {}

  // ---------------------------------------------------------------------------
  // Read views
  // ---------------------------------------------------------------------------

  async getQueue(query: KycQueueQueryDto) {
    const { page, limit, status } = query;
    const skip = (page - 1) * limit;
    const where: Prisma.KycSubmissionWhereInput = status ? { status } : {};

    const [items, total] = await Promise.all([
      this.prisma.kycSubmission.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'asc' },
        select: {
          id: true,
          status: true,
          submittedAt: true,
          createdAt: true,
          profile: {
            select: { id: true, displayName: true, email: true },
          },
        },
      }),
      this.prisma.kycSubmission.count({ where }),
    ]);

    const ids = items.map((item) => item.id);
    const [documentTypes, auditCounts] = await Promise.all([
      this.storage.getDocumentTypes(ids),
      this.countAuditActions(ids),
    ]);

    return {
      items: items.map((item) => ({
        id: item.id,
        applicant: item.profile,
        documentType: documentTypes.get(item.id) ?? null,
        status: item.status,
        submittedAt: item.submittedAt ?? item.createdAt,
        previousAuditActions: auditCounts.get(item.id) ?? 0,
      })),
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getById(id: string) {
    const submission = await this.prisma.kycSubmission.findUnique({
      where: { id },
      include: {
        profile: {
          select: { id: true, displayName: true, email: true, kycStatus: true },
        },
      },
    });

    if (!submission) {
      throw new NotFoundException('KYC submission not found.');
    }

    const documents = await this.storage.getDocuments(id);

    // Return temporary signed URLs only — never raw storage paths or public URLs.
    const [front, back, selfie] = await Promise.all([
      this.toSignedUrl(documents?.front ?? null),
      this.toSignedUrl(documents?.back ?? null),
      this.toSignedUrl(documents?.selfie ?? null),
    ]);

    const auditHistory = await this.prisma.auditLog.findMany({
      where: { resourceType: 'KycSubmission', resourceId: id },
      orderBy: { createdAt: 'desc' },
      include: {
        actor: {
          select: { id: true, displayName: true, email: true, adminRole: true },
        },
      },
    });

    return {
      id: submission.id,
      applicant: submission.profile,
      status: submission.status,
      documentType: documents?.document_type ?? null,
      submittedAt: submission.submittedAt,
      reviewedAt: submission.reviewedAt,
      rejectionReason: submission.rejectionReason,
      documents: { front, back, selfie },
      auditHistory,
    };
  }

  // ---------------------------------------------------------------------------
  // State-changing decisions
  // ---------------------------------------------------------------------------

  async approve(id: string, reviewerId: string, audit: AuditContext) {
    const submission = await this.getOrThrow(id);
    if (submission.status === KycStatus.APPROVED) {
      throw new BadRequestException('This submission is already approved.');
    }

    return this.applyDecision({
      id,
      reviewerId,
      newStatus: KycStatus.APPROVED,
      profileStatus: KycStatus.APPROVED,
      actionType: AuditActionType.KYC_APPROVED,
      metadata: { action: 'APPROVED' },
      audit,
    });
  }

  async reject(id: string, reviewerId: string, reason: string, audit: AuditContext) {
    await this.getOrThrow(id);

    return this.applyDecision({
      id,
      reviewerId,
      newStatus: KycStatus.REJECTED,
      profileStatus: KycStatus.REJECTED,
      rejectionReason: reason,
      actionType: AuditActionType.KYC_REJECTED,
      metadata: { action: 'REJECTED', reason },
      audit,
    });
  }

  async requestResubmission(
    id: string,
    reviewerId: string,
    reason: string,
    audit: AuditContext,
  ) {
    await this.getOrThrow(id);

    return this.applyDecision({
      id,
      reviewerId,
      newStatus: KycStatus.RESUBMISSION_REQUIRED,
      profileStatus: KycStatus.RESUBMISSION_REQUIRED,
      rejectionReason: reason,
      // No dedicated AuditActionType enum value exists — see TO VALIDATE WITH RANINE.
      actionType: AuditActionType.ADMIN_ACTION,
      metadata: { action: 'RESUBMISSION_REQUIRED', reason },
      audit,
    });
  }

  async revoke(id: string, reviewerId: string, reason: string, audit: AuditContext) {
    const submission = await this.getOrThrow(id);
    if (submission.status !== KycStatus.APPROVED) {
      throw new BadRequestException('Only an APPROVED submission can be revoked.');
    }

    // NOTE: KycStatus has no REVOKED value (see TO VALIDATE WITH RANINE). We map the
    // effective state to REJECTED so the profile loses verified access, and record the
    // true intent (REVOKED) in the audit metadata.
    const result = await this.applyDecision({
      id,
      reviewerId,
      newStatus: KycStatus.REJECTED,
      profileStatus: KycStatus.REJECTED,
      rejectionReason: reason,
      actionType: AuditActionType.ADMIN_ACTION,
      metadata: { action: 'REVOKED', reason },
      audit,
    });

    await this.provider.revokeVerification(id);
    return result;
  }

  async recheck(id: string, reviewerId: string, reason: string, audit: AuditContext) {
    await this.getOrThrow(id);

    return this.applyDecision({
      id,
      reviewerId,
      newStatus: KycStatus.UNDER_REVIEW,
      profileStatus: KycStatus.UNDER_REVIEW,
      actionType: AuditActionType.ADMIN_ACTION,
      metadata: { action: 'RECHECK', reason },
      audit,
    });
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  private async getOrThrow(id: string) {
    const submission = await this.prisma.kycSubmission.findUnique({
      where: { id },
      select: { id: true, status: true, profileId: true },
    });
    if (!submission) {
      throw new NotFoundException('KYC submission not found.');
    }
    return submission;
  }

  private async applyDecision(params: {
    id: string;
    reviewerId: string;
    newStatus: KycStatus;
    profileStatus: KycStatus;
    rejectionReason?: string;
    actionType: AuditActionType;
    metadata: Prisma.InputJsonValue;
    audit: AuditContext;
  }) {
    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.kycSubmission.update({
        where: { id: params.id },
        data: {
          status: params.newStatus,
          rejectionReason: params.rejectionReason ?? null,
          reviewedAt: new Date(),
          reviewedByProfileId: params.reviewerId,
        },
      });

      await tx.profile.update({
        where: { id: updated.profileId },
        data: { kycStatus: params.profileStatus },
      });

      await tx.auditLog.create({
        data: {
          actorProfileId: params.reviewerId,
          actionType: params.actionType,
          resourceType: 'KycSubmission',
          resourceId: params.id,
          metadataJson: params.metadata,
          ipAddress: params.audit.ipAddress ?? null,
          userAgent: params.audit.userAgent ?? null,
        },
      });

      return updated;
    });
  }

  private async countAuditActions(ids: string[]): Promise<Map<string, number>> {
    if (ids.length === 0) {
      return new Map();
    }
    const grouped = await this.prisma.auditLog.groupBy({
      by: ['resourceId'],
      where: { resourceType: 'KycSubmission', resourceId: { in: ids } },
      _count: { _all: true },
    });
    return new Map(
      grouped
        .filter((row): row is typeof row & { resourceId: string } => row.resourceId !== null)
        .map((row) => [row.resourceId, row._count._all]),
    );
  }

  private async toSignedUrl(storagePath: string | null): Promise<string | null> {
    if (!storagePath) {
      return null;
    }
    return this.storage.createSignedDownloadUrl(storagePath, DOWNLOAD_URL_TTL_SECONDS);
  }
}
