import { ForbiddenException } from '@nestjs/common';
import { AuditActionType, DealStatus, PartyStatus } from '@prisma/client';
import { DealsService } from './deals.service';
import { CreateDealDto } from './dto/create-deal.dto';

/**
 * All Prisma access is mocked. `$transaction(cb)` invokes the callback with the same mock
 * object used for direct access, so both `this.prisma.x` and `tx.x` calls land on one place.
 */
type PrismaMock = ReturnType<typeof buildPrisma>;

function buildPrisma() {
  const prisma = {
    subscription: { findFirst: jest.fn() },
    plan: { findUnique: jest.fn() },
    deal: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
    dealVersion: {
      create: jest.fn(),
      aggregate: jest.fn(),
      findUnique: jest.fn(),
      deleteMany: jest.fn(),
    },
    dealParty: {
      count: jest.fn(),
      createMany: jest.fn(),
      upsert: jest.fn(),
      deleteMany: jest.fn(),
    },
    dealApproval: { deleteMany: jest.fn() },
    dealFile: { deleteMany: jest.fn() },
    message: { deleteMany: jest.fn() },
    dealInviteLink: {
      create: jest.fn(),
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
      deleteMany: jest.fn(),
    },
    auditLog: { create: jest.fn(), findMany: jest.fn() },
    $transaction: jest.fn(),
  };
  prisma.$transaction.mockImplementation((cb: (tx: typeof prisma) => unknown) =>
    cb(prisma),
  );
  return prisma;
}

const CREATOR = 'creator-profile-1';
const OTHER = 'other-profile-2';
const DEAL_ID = '11111111-1111-1111-1111-111111111111';

function auditActions(prisma: PrismaMock): AuditActionType[] {
  const calls = prisma.auditLog.create.mock.calls as Array<
    [{ data: { actionType: AuditActionType } }]
  >;
  return calls.map((call) => call[0].data.actionType);
}

describe('DealsService', () => {
  let service: DealsService;
  let prisma: PrismaMock;
  const audit = { ipAddress: '127.0.0.1', userAgent: 'jest' };

  const createDto: CreateDealDto = {
    title: 'Acme supply agreement',
    description: 'desc',
    dealType: 'nda',
    parties: [{ email: 'Party@Example.com', role: 'buyer' }],
    terms: { price: 100 },
  };

  beforeEach(() => {
    prisma = buildPrisma();
    // Notifications are a fire-and-forget side effect in these unit tests.
    const notifications = {
      create: jest.fn().mockResolvedValue({}),
      createMany: jest.fn().mockResolvedValue(undefined),
    };
    service = new DealsService(prisma as never, notifications as never);

    // Default resolvable references.
    prisma.deal.create.mockResolvedValue({ id: DEAL_ID });
    prisma.dealVersion.create.mockResolvedValue({ id: 'version-1' });
    prisma.deal.update.mockResolvedValue({});
    prisma.dealParty.createMany.mockResolvedValue({ count: 1 });
    prisma.auditLog.create.mockResolvedValue({});
    prisma.deal.findUnique.mockResolvedValue({ id: DEAL_ID });
  });

  // --- Quota -----------------------------------------------------------------

  describe('createDeal quota', () => {
    it('blocks creation with 403 once the free limit is reached (no transaction opened)', async () => {
      prisma.subscription.findFirst.mockResolvedValue(null);
      prisma.plan.findUnique.mockResolvedValue({ monthlyDealLimit: 5 });
      prisma.deal.count.mockResolvedValue(5);

      await expect(
        service.createDeal(CREATOR, createDto, audit),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.$transaction).not.toHaveBeenCalled();
    });

    it('treats null Plan.monthlyDealLimit as unlimited', async () => {
      prisma.subscription.findFirst.mockResolvedValue({
        plan: { monthlyDealLimit: null },
      });

      await service.createDeal(CREATOR, createDto, audit);
      expect(prisma.deal.count).not.toHaveBeenCalled();
      expect(prisma.$transaction).toHaveBeenCalledTimes(1);
    });
  });

  // --- Creation --------------------------------------------------------------

  describe('createDeal', () => {
    beforeEach(() => {
      prisma.subscription.findFirst.mockResolvedValue(null);
      prisma.plan.findUnique.mockResolvedValue({ monthlyDealLimit: 5 });
      prisma.deal.count.mockResolvedValue(0);
    });

    it('creates the deal and its first version inside a single transaction', async () => {
      await service.createDeal(CREATOR, createDto, audit);

      expect(prisma.$transaction).toHaveBeenCalledTimes(1);
      expect(prisma.deal.create).toHaveBeenCalledTimes(1);
      expect(prisma.dealVersion.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            versionNumber: 1,
            status: DealStatus.DRAFT,
            createdByProfileId: CREATOR,
          }),
        }),
      );
      expect(prisma.deal.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ currentVersionId: 'version-1' }),
        }),
      );
      expect(auditActions(prisma)).toContain(AuditActionType.DEAL_CREATED);
    });
  });

  // --- Read authorization ----------------------------------------------------

  describe('getDealById', () => {
    it('forbids a user with no relation to the deal', async () => {
      prisma.deal.findUnique.mockResolvedValue({
        id: DEAL_ID,
        creatorProfileId: OTHER,
        parties: [],
        versions: [],
        creator: {},
      });

      await expect(
        service.getDealById(CREATOR, DEAL_ID),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });
  });

  // --- Update ----------------------------------------------------------------

  describe('updateDeal', () => {
    it('forbids a non-creator from editing', async () => {
      prisma.deal.findUnique.mockResolvedValue({
        id: DEAL_ID,
        creatorProfileId: OTHER,
        status: DealStatus.DRAFT,
      });

      await expect(
        service.updateDeal(CREATOR, DEAL_ID, { title: 'x' }, audit),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('forbids editing a non-DRAFT (approved/locked) deal', async () => {
      prisma.deal.findUnique.mockResolvedValue({
        id: DEAL_ID,
        creatorProfileId: CREATOR,
        status: DealStatus.APPROVED,
      });

      await expect(
        service.updateDeal(CREATOR, DEAL_ID, { title: 'x' }, audit),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('updates a DRAFT deal and writes a DEAL_UPDATED audit record', async () => {
      prisma.deal.findUnique.mockResolvedValue({
        id: DEAL_ID,
        creatorProfileId: CREATOR,
        status: DealStatus.DRAFT,
        currentVersionId: 'version-1',
      });

      await service.updateDeal(CREATOR, DEAL_ID, { title: 'new' }, audit);
      expect(auditActions(prisma)).toContain(AuditActionType.DEAL_UPDATED);
    });
  });

  // --- Versions --------------------------------------------------------------

  describe('createVersion', () => {
    it('forbids a non-creator from creating a version', async () => {
      prisma.deal.findUnique.mockResolvedValue({
        id: DEAL_ID,
        creatorProfileId: OTHER,
        status: DealStatus.DRAFT,
      });

      await expect(
        service.createVersion(CREATOR, DEAL_ID, { terms: {} }, audit),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('forbids creating a version on an approved/locked deal', async () => {
      prisma.deal.findUnique.mockResolvedValue({
        id: DEAL_ID,
        creatorProfileId: CREATOR,
        status: DealStatus.LOCKED,
      });

      await expect(
        service.createVersion(CREATOR, DEAL_ID, { terms: {} }, audit),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('creates a new version and writes a DEAL_VERSION_CREATED audit record', async () => {
      prisma.deal.findUnique.mockResolvedValue({
        id: DEAL_ID,
        creatorProfileId: CREATOR,
        status: DealStatus.NEGOTIATION,
        title: 'Acme',
        currentVersionId: 'version-1',
      });
      prisma.dealVersion.aggregate.mockResolvedValue({
        _max: { versionNumber: 2 },
      });
      prisma.dealVersion.create.mockResolvedValue({ id: 'version-3' });

      await service.createVersion(CREATOR, DEAL_ID, { terms: { a: 1 } }, audit);

      expect(prisma.dealVersion.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ versionNumber: 3 }),
        }),
      );
      expect(auditActions(prisma)).toContain(
        AuditActionType.DEAL_VERSION_CREATED,
      );
    });
  });

  // --- Delete ----------------------------------------------------------------

  describe('deleteDeal', () => {
    it('deletes a DRAFT deal with no confirmed parties and audits DEAL_DELETED', async () => {
      prisma.deal.findUnique.mockResolvedValue({
        id: DEAL_ID,
        creatorProfileId: CREATOR,
        status: DealStatus.DRAFT,
      });
      prisma.dealParty.count.mockResolvedValue(0);

      await service.deleteDeal(CREATOR, DEAL_ID, audit);

      expect(prisma.deal.delete).toHaveBeenCalledWith({
        where: { id: DEAL_ID },
      });
      expect(auditActions(prisma)).toContain(AuditActionType.DEAL_DELETED);
    });

    it('forbids deletion when confirmed parties exist', async () => {
      prisma.deal.findUnique.mockResolvedValue({
        id: DEAL_ID,
        creatorProfileId: CREATOR,
        status: DealStatus.DRAFT,
      });
      prisma.dealParty.count.mockResolvedValue(1);

      await expect(
        service.deleteDeal(CREATOR, DEAL_ID, audit),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.deal.delete).not.toHaveBeenCalled();
    });
  });

  // --- Sharing ---------------------------------------------------------------

  describe('createShareLink', () => {
    it('creates a link and audits DEAL_SHARED (creator only)', async () => {
      prisma.deal.findUnique.mockResolvedValue({
        id: DEAL_ID,
        creatorProfileId: CREATOR,
      });
      prisma.dealInviteLink.create.mockResolvedValue({
        id: 'link-1',
        maxUses: null,
        expiresAt: new Date(),
      });

      const result = await service.createShareLink(
        CREATOR,
        DEAL_ID,
        { expiresInHours: 48, permissions: ['VIEW'] },
        audit,
      );

      expect(result.inviteUrl).toContain(result.token);
      expect(result.qrCodeData).toBe(result.inviteUrl);
      expect(auditActions(prisma)).toContain(AuditActionType.DEAL_SHARED);
    });
  });

  describe('invitation link validation', () => {
    const base = {
      id: 'link-1',
      dealId: DEAL_ID,
      createdByProfileId: CREATOR,
      permissions: ['VIEW'],
      usedCount: 0,
      maxUses: null as number | null,
      revokedAt: null as Date | null,
    };

    it('rejects an expired link with 403', async () => {
      prisma.dealInviteLink.findUnique.mockResolvedValue({
        ...base,
        expiresAt: new Date(Date.now() - 1000),
        deal: { title: 't' },
        createdBy: { displayName: 'n' },
      });

      await expect(service.getInviteByToken('tok')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });

    it('rejects a revoked link with 403', async () => {
      prisma.dealInviteLink.findUnique.mockResolvedValue({
        ...base,
        revokedAt: new Date(),
        expiresAt: new Date(Date.now() + 100000),
        deal: { title: 't' },
        createdBy: { displayName: 'n' },
      });

      await expect(service.getInviteByToken('tok')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });

    it('rejects acceptance once maxUses is exceeded (403), without adding a party', async () => {
      prisma.dealInviteLink.findUnique.mockResolvedValue({
        ...base,
        maxUses: 1,
        usedCount: 1,
        expiresAt: new Date(Date.now() + 100000),
      });

      await expect(
        service.acceptInvite(OTHER, 'x@y.com', 'tok', audit),
      ).rejects.toBeInstanceOf(ForbiddenException);
      expect(prisma.dealParty.upsert).not.toHaveBeenCalled();
    });
  });

  describe('acceptInvite', () => {
    it('adds the caller as an ACCEPTED party, consumes a use, and audits', async () => {
      prisma.dealInviteLink.findUnique.mockResolvedValue({
        id: 'link-1',
        dealId: DEAL_ID,
        createdByProfileId: CREATOR,
        permissions: ['SIGN'],
        usedCount: 0,
        maxUses: null,
        revokedAt: null,
        expiresAt: new Date(Date.now() + 100000),
      });
      prisma.dealInviteLink.update.mockResolvedValue({});
      prisma.dealParty.upsert.mockResolvedValue({});

      await service.acceptInvite(OTHER, 'New@Example.com', 'tok', audit);

      expect(prisma.dealParty.upsert).toHaveBeenCalledWith(
        expect.objectContaining({
          create: expect.objectContaining({
            profileId: OTHER,
            email: 'new@example.com',
            partyStatus: PartyStatus.ACCEPTED,
            requiredApproval: true,
          }),
        }),
      );
      expect(prisma.dealInviteLink.update).toHaveBeenCalledWith(
        expect.objectContaining({
          data: { usedCount: { increment: 1 } },
        }),
      );
      expect(auditActions(prisma)).toContain(
        AuditActionType.DEAL_INVITE_ACCEPTED,
      );
    });
  });

  describe('revokeShareLink', () => {
    it('forbids a non-creator from revoking', async () => {
      prisma.deal.findUnique.mockResolvedValue({
        id: DEAL_ID,
        creatorProfileId: OTHER,
      });

      await expect(
        service.revokeShareLink(CREATOR, DEAL_ID, 'tok', audit),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('revokes a link and audits DEAL_INVITE_REVOKED', async () => {
      prisma.deal.findUnique.mockResolvedValue({
        id: DEAL_ID,
        creatorProfileId: CREATOR,
      });
      prisma.dealInviteLink.findFirst.mockResolvedValue({
        id: 'link-1',
        token: 'abcdef123456',
        revokedAt: null,
      });
      prisma.dealInviteLink.update.mockResolvedValue({});

      await service.revokeShareLink(CREATOR, DEAL_ID, 'abcdef123456', audit);
      expect(auditActions(prisma)).toContain(
        AuditActionType.DEAL_INVITE_REVOKED,
      );
    });
  });
});
