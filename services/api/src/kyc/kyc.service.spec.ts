import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { AuditActionType, KycStatus } from '@prisma/client';
import { KycService } from './kyc.service';
import {
  PendingUploadRegistry,
  PendingUpload,
} from './storage/pending-upload.registry';
import { KycStorageService } from './storage/kyc-storage.service';
import { KycProvider } from './providers/kyc-provider.interface';
import { SubmitKycDto } from './dto/submit-kyc.dto';

type TxMock = {
  kycSubmission: { create: jest.Mock; update: jest.Mock };
  profile: { update: jest.Mock };
  auditLog: { create: jest.Mock };
};

describe('KycService', () => {
  let service: KycService;
  let prisma: {
    kycSubmission: { findFirst: jest.Mock };
    profile: { findUnique: jest.Mock };
    $transaction: jest.Mock;
  };
  let tx: TxMock;
  let registry: jest.Mocked<Pick<PendingUploadRegistry, 'peek' | 'consume'>>;
  let storage: jest.Mocked<Pick<KycStorageService, 'persistDocuments'>>;
  let provider: jest.Mocked<KycProvider>;

  const profileId = 'profile-1';
  const submitDto: SubmitKycDto = {
    documentType: 'passport',
    storagePathFront: 'profile-1/front/aaa',
    storagePathBack: 'profile-1/back/bbb',
    storagePathSelfie: 'profile-1/selfie/ccc',
  };

  const authorizedRef = (side: PendingUpload['side']): PendingUpload => ({
    profileId,
    side,
    storagePath: `${profileId}/${side}`,
    mimeType: 'image/jpeg',
    sizeBytes: 1000,
    expiresAt: Date.now() + 60_000,
  });

  beforeEach(() => {
    tx = {
      kycSubmission: {
        create: jest.fn().mockResolvedValue({ id: 'sub-1', profileId }),
        update: jest.fn().mockResolvedValue({ id: 'sub-1', profileId }),
      },
      profile: { update: jest.fn().mockResolvedValue({}) },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };

    prisma = {
      kycSubmission: { findFirst: jest.fn() },
      profile: { findUnique: jest.fn() },
      $transaction: jest.fn(async (cb: (t: TxMock) => unknown) => cb(tx)),
    };

    registry = {
      peek: jest.fn().mockReturnValue(authorizedRef('front')),
      consume: jest.fn(),
    };
    storage = { persistDocuments: jest.fn().mockResolvedValue(undefined) };
    provider = {
      submitForVerification: jest.fn().mockResolvedValue(undefined),
      getVerificationStatus: jest.fn(),
      revokeVerification: jest.fn(),
    };

    service = new KycService(
      prisma as never,
      registry as never,
      storage as never,
      provider,
    );
  });

  describe('submit', () => {
    it('blocks a duplicate submission when one is SUBMITTED or UNDER_REVIEW', async () => {
      prisma.kycSubmission.findFirst.mockResolvedValue({ id: 'existing' });

      await expect(
        service.submit(profileId, submitDto, {}),
      ).rejects.toBeInstanceOf(ConflictException);
      expect(prisma.$transaction).not.toHaveBeenCalled();
    });

    it('rejects when a referenced storage path was not pre-authorized', async () => {
      prisma.kycSubmission.findFirst.mockResolvedValue(null);
      registry.peek.mockReturnValue(null);

      await expect(
        service.submit(profileId, submitDto, {}),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.$transaction).not.toHaveBeenCalled();
    });

    it('creates the submission and writes a KYC_SUBMITTED audit record (happy path)', async () => {
      prisma.kycSubmission.findFirst.mockResolvedValue(null);

      await service.submit(profileId, submitDto, { ipAddress: '1.2.3.4' });

      expect(tx.kycSubmission.create).toHaveBeenCalled();
      expect(storage.persistDocuments).toHaveBeenCalled();
      expect(tx.profile.update).toHaveBeenCalledWith({
        where: { id: profileId },
        data: { kycStatus: KycStatus.SUBMITTED },
      });
      expect(tx.auditLog.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            actionType: AuditActionType.KYC_SUBMITTED,
            resourceType: 'KycSubmission',
          }),
        }),
      );
      expect(provider.submitForVerification).toHaveBeenCalledWith('sub-1');
    });
  });

  describe('resubmit', () => {
    it('blocks resubmission when status is not REJECTED or RESUBMISSION_REQUIRED', async () => {
      prisma.kycSubmission.findFirst.mockResolvedValue({
        id: 'sub-1',
        status: KycStatus.UNDER_REVIEW,
      });

      await expect(
        service.resubmit(profileId, submitDto, {}),
      ).rejects.toBeInstanceOf(BadRequestException);
      expect(prisma.$transaction).not.toHaveBeenCalled();
    });

    it('updates the submission and writes an audit record (happy path)', async () => {
      prisma.kycSubmission.findFirst.mockResolvedValue({
        id: 'sub-1',
        status: KycStatus.REJECTED,
      });

      await service.resubmit(profileId, submitDto, {});

      expect(tx.kycSubmission.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'sub-1' },
          data: expect.objectContaining({
            status: KycStatus.SUBMITTED,
            rejectionReason: null,
          }),
        }),
      );
      expect(tx.auditLog.create).toHaveBeenCalled();
      expect(provider.submitForVerification).toHaveBeenCalledWith('sub-1');
    });
  });
});
