import { BadRequestException } from '@nestjs/common';
import { AuditActionType, KycStatus } from '@prisma/client';
import { AdminKycService } from './admin-kyc.service';
import { KycProvider } from '../kyc/providers/kyc-provider.interface';

type TxMock = {
  kycSubmission: { update: jest.Mock };
  profile: { update: jest.Mock };
  auditLog: { create: jest.Mock };
};

describe('AdminKycService', () => {
  let service: AdminKycService;
  let prisma: {
    kycSubmission: { findUnique: jest.Mock };
    $transaction: jest.Mock;
  };
  let tx: TxMock;
  let provider: jest.Mocked<KycProvider>;

  const id = 'sub-1';
  const reviewerId = 'admin-1';

  const lastAudit = (): Record<string, unknown> =>
    tx.auditLog.create.mock.calls.at(-1)?.[0]?.data as Record<string, unknown>;

  const mockSubmission = (status: KycStatus) =>
    prisma.kycSubmission.findUnique.mockResolvedValue({ id, status, profileId: 'p-1' });

  beforeEach(() => {
    tx = {
      kycSubmission: {
        update: jest.fn().mockResolvedValue({ id, profileId: 'p-1' }),
      },
      profile: { update: jest.fn().mockResolvedValue({}) },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };

    prisma = {
      kycSubmission: { findUnique: jest.fn() },
      $transaction: jest.fn(async (cb: (t: TxMock) => unknown) => cb(tx)),
    };

    provider = {
      submitForVerification: jest.fn(),
      getVerificationStatus: jest.fn(),
      revokeVerification: jest.fn().mockResolvedValue(undefined),
    };

    service = new AdminKycService(prisma as never, {} as never, provider);
  });

  describe('approve', () => {
    it('approves and writes a KYC_APPROVED audit record (happy path)', async () => {
      mockSubmission(KycStatus.SUBMITTED);

      await service.approve(id, reviewerId, {});

      expect(tx.kycSubmission.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ status: KycStatus.APPROVED }),
        }),
      );
      expect(tx.profile.update).toHaveBeenCalledWith({
        where: { id: 'p-1' },
        data: { kycStatus: KycStatus.APPROVED },
      });
      expect(lastAudit()).toEqual(
        expect.objectContaining({ actionType: AuditActionType.KYC_APPROVED }),
      );
    });

    it('rejects approving a submission that is already APPROVED', async () => {
      mockSubmission(KycStatus.APPROVED);

      await expect(service.approve(id, reviewerId, {})).rejects.toBeInstanceOf(
        BadRequestException,
      );
      expect(prisma.$transaction).not.toHaveBeenCalled();
    });
  });

  describe('reject', () => {
    it('rejects and writes a KYC_REJECTED audit record (happy path)', async () => {
      mockSubmission(KycStatus.SUBMITTED);

      await service.reject(id, reviewerId, 'blurry document', {});

      expect(tx.kycSubmission.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            status: KycStatus.REJECTED,
            rejectionReason: 'blurry document',
          }),
        }),
      );
      expect(lastAudit()).toEqual(
        expect.objectContaining({ actionType: AuditActionType.KYC_REJECTED }),
      );
    });
  });

  describe('requestResubmission', () => {
    it('sets RESUBMISSION_REQUIRED and writes an audit record (happy path)', async () => {
      mockSubmission(KycStatus.UNDER_REVIEW);

      await service.requestResubmission(id, reviewerId, 'need clearer selfie', {});

      expect(tx.kycSubmission.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            status: KycStatus.RESUBMISSION_REQUIRED,
          }),
        }),
      );
      expect(lastAudit()).toEqual(
        expect.objectContaining({
          actionType: AuditActionType.ADMIN_ACTION,
          metadataJson: expect.objectContaining({ action: 'RESUBMISSION_REQUIRED' }),
        }),
      );
    });
  });

  describe('revoke', () => {
    it('blocks revoke unless current status is APPROVED', async () => {
      mockSubmission(KycStatus.SUBMITTED);

      await expect(service.revoke(id, reviewerId, 'fraud', {})).rejects.toBeInstanceOf(
        BadRequestException,
      );
      expect(prisma.$transaction).not.toHaveBeenCalled();
    });

    it('revokes an APPROVED submission and writes an audit record (happy path)', async () => {
      mockSubmission(KycStatus.APPROVED);

      await service.revoke(id, reviewerId, 'fraud detected', {});

      expect(tx.kycSubmission.update).toHaveBeenCalled();
      expect(lastAudit()).toEqual(
        expect.objectContaining({
          actionType: AuditActionType.ADMIN_ACTION,
          metadataJson: expect.objectContaining({ action: 'REVOKED' }),
        }),
      );
      expect(provider.revokeVerification).toHaveBeenCalledWith(id);
    });
  });

  describe('recheck', () => {
    it('moves the submission to UNDER_REVIEW and writes an audit record (happy path)', async () => {
      mockSubmission(KycStatus.APPROVED);

      await service.recheck(id, reviewerId, 'periodic re-verification', {});

      expect(tx.kycSubmission.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ status: KycStatus.UNDER_REVIEW }),
        }),
      );
      expect(lastAudit()).toEqual(
        expect.objectContaining({
          actionType: AuditActionType.ADMIN_ACTION,
          metadataJson: expect.objectContaining({ action: 'RECHECK' }),
        }),
      );
    });
  });
});
