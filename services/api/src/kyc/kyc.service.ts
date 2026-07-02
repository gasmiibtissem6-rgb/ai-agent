// kyc.service.ts
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { AuditActionType, KycStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { PendingUploadRegistry } from './storage/pending-upload.registry';
import { KycStorageService } from './storage/kyc-storage.service';
import { KYC_PROVIDER } from './providers/kyc-provider.interface';
import type { KycProvider } from './providers/kyc-provider.interface';
import { AuthorizeUploadDto } from './dto/authorize-upload.dto';
import { SubmitKycDto } from './dto/submit-kyc.dto';
import { ResubmitKycDto } from './dto/resubmit-kyc.dto';

/** Request context captured on audit records (never contains personal data or paths). */
export interface AuditContext {
  ipAddress?: string;
  userAgent?: string;
}

/** Statuses that block a brand-new submission (one active review at a time). */
const ACTIVE_STATUSES: KycStatus[] = [
  KycStatus.SUBMITTED,
  KycStatus.UNDER_REVIEW,
];

/** Statuses from which a user is allowed to resubmit. */
const RESUBMITTABLE_STATUSES: KycStatus[] = [
  KycStatus.REJECTED,
  KycStatus.RESUBMISSION_REQUIRED,
];

/** Signed upload URL lifetime (seconds). */
const UPLOAD_URL_TTL_SECONDS = 600;

@Injectable()
export class KycService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly registry: PendingUploadRegistry,
    private readonly storage: KycStorageService,
    @Inject(KYC_PROVIDER) private readonly provider: KycProvider,
  ) {}

  // ---------------------------------------------------------------------------
  // Document upload authorization
  // ---------------------------------------------------------------------------

  /**
   * Issues a signed upload URL for a single document and registers a pending file
   * reference. The client uploads the binary straight to private Storage; NestJS never
   * touches the file itself. Only pre-authorized paths may later back a submission.
   */
  async authorizeUpload(profileId: string, dto: AuthorizeUploadDto) {
    // Deterministic, per-user, non-guessable object path. Never derived from client input
    // beyond the side, so a client cannot target another user's namespace.
    const storagePath = `${profileId}/${dto.documentSide}/${randomUUID()}`;

    const uploadUrl = await this.storage.createSignedUploadUrl(
      storagePath,
      UPLOAD_URL_TTL_SECONDS,
    );

    this.registry.register({
      profileId,
      side: dto.documentSide,
      storagePath,
      mimeType: dto.mimeType,
      sizeBytes: dto.sizeBytes,
      expiresAt: Date.now() + UPLOAD_URL_TTL_SECONDS * 1000,
    });

    return {
      storagePath,
      uploadUrl,
      documentSide: dto.documentSide,
      expiresInSeconds: UPLOAD_URL_TTL_SECONDS,
    };
  }

  // ---------------------------------------------------------------------------
  // User submission flow
  // ---------------------------------------------------------------------------

  /** Creates a new KYC submission from pre-authorized document paths. */
  async submit(profileId: string, dto: SubmitKycDto, audit: AuditContext) {
    const active = await this.prisma.kycSubmission.findFirst({
      where: { profileId, status: { in: ACTIVE_STATUSES } },
    });
    if (active) {
      throw new ConflictException(
        'You already have a KYC submission awaiting review.',
      );
    }

    this.assertAuthorizedPaths(profileId, dto);

    const submission = await this.prisma.$transaction(async (tx) => {
      const created = await tx.kycSubmission.create({
        data: {
          profileId,
          status: KycStatus.SUBMITTED,
          submittedAt: new Date(),
        },
      });

      await this.storage.persistDocuments(tx, created.id, {
        documentType: dto.documentType,
        front: dto.storagePathFront,
        back: dto.storagePathBack ?? null,
        selfie: dto.storagePathSelfie,
      });

      // TODO(ranine): dto.personalInfo has no confirmed column/table yet — not persisted.

      await tx.profile.update({
        where: { id: profileId },
        data: { kycStatus: KycStatus.SUBMITTED },
      });

      await this.writeAudit(tx, {
        actorProfileId: profileId,
        actionType: AuditActionType.KYC_SUBMITTED,
        resourceId: created.id,
        metadata: { action: 'SUBMITTED', documentType: dto.documentType },
        audit,
      });

      return created;
    });

    this.consumePaths(profileId, dto);
    await this.provider.submitForVerification(submission.id);
    return submission;
  }

  /** Returns the caller's current verification status. Never exposes other users' data. */
  async getMyStatus(profileId: string) {
    const latest = await this.prisma.kycSubmission.findFirst({
      where: { profileId },
      orderBy: { createdAt: 'desc' },
      select: {
        status: true,
        submittedAt: true,
        reviewedAt: true,
        rejectionReason: true,
      },
    });

    if (!latest) {
      const profile = await this.prisma.profile.findUnique({
        where: { id: profileId },
        select: { kycStatus: true },
      });
      return {
        status: profile?.kycStatus ?? KycStatus.NOT_STARTED,
        submittedAt: null,
        reviewedAt: null,
        rejectionReason: null,
      };
    }

    return {
      status: latest.status,
      submittedAt: latest.submittedAt,
      reviewedAt: latest.reviewedAt,
      rejectionReason: latest.rejectionReason,
    };
  }

  /** Updates an existing REJECTED / RESUBMISSION_REQUIRED submission with fresh documents. */
  async resubmit(profileId: string, dto: ResubmitKycDto, audit: AuditContext) {
    const latest = await this.prisma.kycSubmission.findFirst({
      where: { profileId },
      orderBy: { createdAt: 'desc' },
    });

    if (!latest) {
      throw new NotFoundException('No existing KYC submission to resubmit.');
    }
    if (!RESUBMITTABLE_STATUSES.includes(latest.status)) {
      throw new BadRequestException(
        'Resubmission is only allowed after a rejection or a resubmission request.',
      );
    }

    this.assertAuthorizedPaths(profileId, dto);

    const updated = await this.prisma.$transaction(async (tx) => {
      const result = await tx.kycSubmission.update({
        where: { id: latest.id },
        data: {
          status: KycStatus.SUBMITTED,
          rejectionReason: null,
          submittedAt: new Date(),
          reviewedAt: null,
          reviewedByProfileId: null,
        },
      });

      await this.storage.persistDocuments(tx, latest.id, {
        documentType: dto.documentType,
        front: dto.storagePathFront,
        back: dto.storagePathBack ?? null,
        selfie: dto.storagePathSelfie,
      });

      await tx.profile.update({
        where: { id: profileId },
        data: { kycStatus: KycStatus.SUBMITTED },
      });

      await this.writeAudit(tx, {
        actorProfileId: profileId,
        actionType: AuditActionType.KYC_SUBMITTED,
        resourceId: latest.id,
        metadata: { action: 'RESUBMITTED', documentType: dto.documentType },
        audit,
      });

      return result;
    });

    this.consumePaths(profileId, dto);
    await this.provider.submitForVerification(updated.id);
    return updated;
  }

  // ---------------------------------------------------------------------------
  // Legacy manual + external-provider flow (kept active, unchanged behavior)
  // ---------------------------------------------------------------------------

  async initiateSubmission(profileId: string, providerReference?: string) {
    const existingActive = await this.prisma.kycSubmission.findFirst({
      where: { profileId, status: { in: ACTIVE_STATUSES } },
    });

    if (existingActive) {
      throw new ConflictException(
        'You already have an active verification submission pending review.',
      );
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

  async handleWebhookStatusUpdate(
    providerReference: string,
    externalStatus: string,
    rejectionReason?: string,
  ) {
    const submission = await this.prisma.kycSubmission.findFirst({
      where: { providerReference },
    });

    if (!submission) {
      throw new NotFoundException(
        `KYC submission tracing reference ${providerReference} not found.`,
      );
    }

    let targetStatus: KycStatus = KycStatus.UNDER_REVIEW;
    if (externalStatus === 'verified' || externalStatus === 'approved') {
      targetStatus = KycStatus.APPROVED;
    }
    if (externalStatus === 'requires_input' || externalStatus === 'rejected') {
      targetStatus = KycStatus.REJECTED;
    }

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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  private assertAuthorizedPaths(profileId: string, dto: SubmitKycDto): void {
    this.assertAuthorized(profileId, dto.storagePathFront);
    this.assertAuthorized(profileId, dto.storagePathSelfie);
    if (dto.storagePathBack) {
      this.assertAuthorized(profileId, dto.storagePathBack);
    }
  }

  private assertAuthorized(profileId: string, storagePath: string): void {
    const pending = this.registry.peek(profileId, storagePath);
    if (!pending) {
      throw new ForbiddenException(
        'A referenced document was not pre-authorized by the API. Call /kyc/storage/authorize first.',
      );
    }
  }

  private consumePaths(profileId: string, dto: SubmitKycDto): void {
    this.registry.consume(profileId, dto.storagePathFront);
    this.registry.consume(profileId, dto.storagePathSelfie);
    if (dto.storagePathBack) {
      this.registry.consume(profileId, dto.storagePathBack);
    }
  }

  private async writeAudit(
    tx: Prisma.TransactionClient,
    params: {
      actorProfileId: string;
      actionType: AuditActionType;
      resourceId: string;
      metadata: Prisma.InputJsonValue;
      audit: AuditContext;
    },
  ): Promise<void> {
    await tx.auditLog.create({
      data: {
        actorProfileId: params.actorProfileId,
        actionType: params.actionType,
        resourceType: 'KycSubmission',
        resourceId: params.resourceId,
        metadataJson: params.metadata,
        ipAddress: params.audit.ipAddress ?? null,
        userAgent: params.audit.userAgent ?? null,
      },
    });
  }
}
