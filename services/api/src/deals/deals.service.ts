// src/deals/deals.service.ts
import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import {
  AuditActionType,
  DealStatus,
  PartyStatus,
  Prisma,
  SubscriptionStatus,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  FREE_PLAN_CODE,
  getFreePlanDealLimit,
  getInviteBaseUrl,
} from './deal-quota.constants';
import { CreateDealDto } from './dto/create-deal.dto';
import { UpdateDealDto } from './dto/update-deal.dto';
import { UpdateDealStatusDto } from './dto/update-deal-status.dto';
import { ListDealsQueryDto } from './dto/list-deals-query.dto';
import { CreateDealVersionDto } from './dto/create-deal-version.dto';
import { ShareDealDto } from './dto/share-deal.dto';

/** Request context captured on audit records (never contains personal data or paths). */
export interface AuditContext {
  ipAddress?: string;
  userAgent?: string;
}

/** Deal statuses whose current version is immutable and blocks new-version creation. */
const IMMUTABLE_DEAL_STATUSES: DealStatus[] = [
  DealStatus.APPROVED,
  DealStatus.LOCKED,
];

/** Deal statuses that can never transition again. */
const TERMINAL_DEAL_STATUSES: DealStatus[] = [
  DealStatus.LOCKED,
  DealStatus.ARCHIVED,
];

@Injectable()
export class DealsService {
  constructor(private readonly prisma: PrismaService) {}

  // ---------------------------------------------------------------------------
  // Quota (must run BEFORE any create transaction opens)
  // ---------------------------------------------------------------------------

  /**
   * Resolves the caller's monthly deal limit. `null` means unlimited. The value is never
   * hardcoded: it comes from the active subscription's Plan, then the free Plan row, then a
   * configurable app constant — so admins can change limits without touching this code.
   */
  private async resolveDealLimit(profileId: string): Promise<number | null> {
    const now = new Date();
    const activeSubscription = await this.prisma.subscription.findFirst({
      where: {
        profileId,
        status: SubscriptionStatus.ACTIVE,
        OR: [{ currentPeriodEnd: null }, { currentPeriodEnd: { gt: now } }],
      },
      orderBy: { createdAt: 'desc' },
      include: { plan: true },
    });

    if (activeSubscription?.plan) {
      // Paid plan: null monthlyDealLimit means unlimited.
      return activeSubscription.plan.monthlyDealLimit;
    }

    // Free tier: prefer an admin-configurable Plan row, else the configurable constant.
    const freePlan = await this.prisma.plan.findUnique({
      where: { code: FREE_PLAN_CODE },
    });
    if (freePlan) {
      return freePlan.monthlyDealLimit;
    }
    return getFreePlanDealLimit();
  }

  /** Throws 403 if the caller has reached their deal quota for the current month. */
  private async assertUnderDealLimit(profileId: string): Promise<void> {
    const limit = await this.resolveDealLimit(profileId);
    if (limit === null) {
      return; // unlimited
    }

    const periodStart = new Date(
      Date.UTC(new Date().getUTCFullYear(), new Date().getUTCMonth(), 1),
    );
    const used = await this.prisma.deal.count({
      where: { creatorProfileId: profileId, createdAt: { gte: periodStart } },
    });

    if (used >= limit) {
      throw new ForbiddenException(
        `Deal quota reached: you have created ${used} of ${limit} deals allowed this period. ` +
          'An active subscription is required to create additional deals.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Deal CRUD
  // ---------------------------------------------------------------------------

  /** Creates a deal and its initial draft version atomically, after enforcing quota. */
  async createDeal(
    creatorProfileId: string,
    dto: CreateDealDto,
    audit: AuditContext,
  ) {
    await this.assertUnderDealLimit(creatorProfileId);

    return this.prisma.$transaction(async (tx) => {
      const deal = await tx.deal.create({
        data: {
          creatorProfileId,
          title: dto.title,
          description: dto.description ?? null,
          dealType: dto.dealType ?? null,
          status: DealStatus.DRAFT,
        },
      });

      const version = await tx.dealVersion.create({
        data: {
          dealId: deal.id,
          versionNumber: 1,
          status: DealStatus.DRAFT,
          title: dto.title,
          termsJson: dto.terms as Prisma.InputJsonValue,
          summary: 'Initial draft',
          createdByProfileId: creatorProfileId,
        },
      });

      await tx.deal.update({
        where: { id: deal.id },
        data: { currentVersionId: version.id },
      });

      if (dto.parties?.length) {
        await tx.dealParty.createMany({
          data: dto.parties.map((party) => ({
            dealId: deal.id,
            email: party.email.toLowerCase(),
            role: party.role,
            requiredApproval: party.requiredApproval ?? true,
            invitedByProfileId: creatorProfileId,
          })),
          skipDuplicates: true,
        });
      }

      await this.writeAudit(tx, {
        actorProfileId: creatorProfileId,
        actionType: AuditActionType.DEAL_CREATED,
        resourceId: deal.id,
        metadata: {
          versionId: version.id,
          dealType: dto.dealType ?? null,
          partyCount: dto.parties?.length ?? 0,
        },
        audit,
      });

      return tx.deal.findUnique({
        where: { id: deal.id },
        include: {
          versions: { orderBy: { versionNumber: 'asc' } },
          parties: true,
        },
      });
    });
  }

  /** Lists deals where the caller is the creator OR a participant, paginated + filterable. */
  async listDeals(profileId: string, query: ListDealsQueryDto) {
    const { page, limit, status, dealType } = query;
    const where: Prisma.DealWhereInput = {
      OR: [
        { creatorProfileId: profileId },
        { parties: { some: { profileId } } },
      ],
      ...(status ? { status } : {}),
      ...(dealType ? { dealType } : {}),
    };

    const [items, total] = await Promise.all([
      this.prisma.deal.findMany({
        where,
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          parties: {
            select: { id: true, email: true, role: true, partyStatus: true },
          },
        },
      }),
      this.prisma.deal.count({ where }),
    ]);

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  /** Returns full deal detail (versions, parties, audit history) for an authorized user. */
  async getDealById(profileId: string, dealId: string) {
    const deal = await this.prisma.deal.findUnique({
      where: { id: dealId },
      include: {
        versions: { orderBy: { versionNumber: 'asc' } },
        parties: true,
        creator: { select: { id: true, displayName: true, email: true } },
      },
    });
    if (!deal) {
      throw new NotFoundException('Deal not found.');
    }

    const isParticipant =
      deal.creatorProfileId === profileId ||
      deal.parties.some((party) => party.profileId === profileId);
    if (!isParticipant) {
      throw new ForbiddenException('You do not have access to this deal.');
    }

    const auditHistory = await this.prisma.auditLog.findMany({
      where: { resourceType: 'Deal', resourceId: dealId },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });

    return { ...deal, auditHistory };
  }

  /** Updates a DRAFT deal (creator only). Approved/locked deals are never modifiable. */
  async updateDeal(
    profileId: string,
    dealId: string,
    dto: UpdateDealDto,
    audit: AuditContext,
  ) {
    const deal = await this.getDealOrThrow(dealId);
    this.assertCreator(deal, profileId);
    if (deal.status !== DealStatus.DRAFT) {
      throw new ForbiddenException('Only deals in DRAFT status can be edited.');
    }

    return this.prisma.$transaction(async (tx) => {
      await tx.deal.update({
        where: { id: dealId },
        data: {
          title: dto.title ?? undefined,
          description: dto.description ?? undefined,
          dealType: dto.dealType ?? undefined,
        },
      });

      if (dto.terms !== undefined) {
        const currentVersion = deal.currentVersionId
          ? await tx.dealVersion.findUnique({
              where: { id: deal.currentVersionId },
            })
          : null;
        if (
          !currentVersion ||
          currentVersion.status !== DealStatus.DRAFT ||
          currentVersion.lockedAt
        ) {
          throw new ForbiddenException(
            'The current version is locked and its terms cannot be modified.',
          );
        }
        await tx.dealVersion.update({
          where: { id: currentVersion.id },
          data: {
            termsJson: dto.terms as Prisma.InputJsonValue,
            title: dto.title ?? undefined,
          },
        });
      }

      await this.writeAudit(tx, {
        actorProfileId: profileId,
        actionType: AuditActionType.DEAL_UPDATED,
        resourceId: dealId,
        metadata: {
          fields: Object.keys(dto),
          termsChanged: dto.terms !== undefined,
        },
        audit,
      });

      return tx.deal.findUnique({
        where: { id: dealId },
        include: {
          versions: { orderBy: { versionNumber: 'asc' } },
          parties: true,
        },
      });
    });
  }

  /**
   * Sets the deal's status (creator only) to one of the creator-settable states.
   *
   * A LOCKED or ARCHIVED deal is terminal and cannot be moved again. `cancelledAt`
   * is stamped when the deal is cancelled so the column stops being dead weight.
   */
  async updateDealStatus(
    profileId: string,
    dealId: string,
    dto: UpdateDealStatusDto,
    audit: AuditContext,
  ) {
    const deal = await this.getDealOrThrow(dealId);
    this.assertCreator(deal, profileId);

    if (TERMINAL_DEAL_STATUSES.includes(deal.status)) {
      throw new ForbiddenException(
        `A ${deal.status} deal can no longer change status.`,
      );
    }

    if (deal.status === dto.status) {
      return deal;
    }

    return this.prisma.$transaction(async (tx) => {
      await tx.deal.update({
        where: { id: dealId },
        data: {
          status: dto.status,
          cancelledAt:
            dto.status === DealStatus.CANCELLED ? new Date() : deal.cancelledAt,
        },
      });

      await this.writeAudit(tx, {
        actorProfileId: profileId,
        actionType: AuditActionType.DEAL_UPDATED,
        resourceId: dealId,
        metadata: {
          previousStatus: deal.status,
          newStatus: dto.status,
          reason: dto.reason ?? null,
        },
        audit,
      });

      return tx.deal.findUnique({
        where: { id: dealId },
        include: {
          versions: { orderBy: { versionNumber: 'asc' } },
          parties: true,
        },
      });
    });
  }

  /**
   * Creates a new deal version (creator only) unless the deal is approved/locked.
   * NOTE: the deal's chat thread lifecycle is intentionally left untouched here — that
   * decision is pending product confirmation and must not be made silently.
   */
  async createVersion(
    profileId: string,
    dealId: string,
    dto: CreateDealVersionDto,
    audit: AuditContext,
  ) {
    const deal = await this.getDealOrThrow(dealId);
    this.assertCreator(deal, profileId);
    if (IMMUTABLE_DEAL_STATUSES.includes(deal.status)) {
      throw new ForbiddenException(
        `A new version cannot be created while the deal is ${deal.status}.`,
      );
    }

    return this.prisma.$transaction(async (tx) => {
      const max = await tx.dealVersion.aggregate({
        where: { dealId },
        _max: { versionNumber: true },
      });
      const nextVersionNumber = (max._max.versionNumber ?? 0) + 1;

      const version = await tx.dealVersion.create({
        data: {
          dealId,
          versionNumber: nextVersionNumber,
          status: DealStatus.DRAFT,
          title: dto.title ?? deal.title,
          termsJson: dto.terms as Prisma.InputJsonValue,
          summary: dto.summary ?? null,
          sourceVersionId: deal.currentVersionId ?? null,
          createdByProfileId: profileId,
        },
      });

      await tx.deal.update({
        where: { id: dealId },
        data: { currentVersionId: version.id },
      });

      await this.writeAudit(tx, {
        actorProfileId: profileId,
        actionType: AuditActionType.DEAL_VERSION_CREATED,
        resourceId: dealId,
        metadata: { versionId: version.id, versionNumber: nextVersionNumber },
        audit,
      });

      return version;
    });
  }

  /** Deletes a DRAFT deal with no confirmed parties (creator only). */
  async deleteDeal(profileId: string, dealId: string, audit: AuditContext) {
    const deal = await this.getDealOrThrow(dealId);
    this.assertCreator(deal, profileId);
    if (deal.status !== DealStatus.DRAFT) {
      throw new ForbiddenException(
        'Only deals in DRAFT status can be deleted.',
      );
    }

    const confirmedParties = await this.prisma.dealParty.count({
      where: { dealId, partyStatus: PartyStatus.ACCEPTED },
    });
    if (confirmedParties > 0) {
      throw new ForbiddenException(
        'This deal has confirmed participants and cannot be deleted.',
      );
    }

    await this.prisma.$transaction(async (tx) => {
      // FK-safe teardown of a draft deal's dependent rows.
      await tx.dealApproval.deleteMany({ where: { version: { dealId } } });
      await tx.dealFile.deleteMany({
        where: { OR: [{ dealId }, { version: { dealId } }] },
      });
      await tx.message.deleteMany({ where: { dealId } });
      await tx.dealInviteLink.deleteMany({ where: { dealId } });
      await tx.dealParty.deleteMany({ where: { dealId } });
      await tx.deal.update({
        where: { id: dealId },
        data: { currentVersionId: null, lockedVersionId: null },
      });
      await tx.dealVersion.deleteMany({ where: { dealId } });
      await tx.deal.delete({ where: { id: dealId } });

      await this.writeAudit(tx, {
        actorProfileId: profileId,
        actionType: AuditActionType.DEAL_DELETED,
        resourceId: dealId,
        metadata: { previousStatus: deal.status },
        audit,
      });
    });

    return { id: dealId, deleted: true };
  }

  // ---------------------------------------------------------------------------
  // Deal sharing (invitation links)
  // ---------------------------------------------------------------------------

  /** Generates a secure single-token invitation link (creator only). */
  async createShareLink(
    profileId: string,
    dealId: string,
    dto: ShareDealDto,
    audit: AuditContext,
  ) {
    const deal = await this.getDealOrThrow(dealId);
    this.assertCreator(deal, profileId);

    const token = randomUUID();
    const expiresAt = new Date(Date.now() + dto.expiresInHours * 3_600_000);

    const link = await this.prisma.$transaction(async (tx) => {
      const created = await tx.dealInviteLink.create({
        data: {
          dealId,
          token,
          createdByProfileId: profileId,
          permissions: dto.permissions,
          expiresAt,
          maxUses: dto.maxUses ?? null,
        },
      });

      await this.writeAudit(tx, {
        actorProfileId: profileId,
        actionType: AuditActionType.DEAL_SHARED,
        resourceId: dealId,
        metadata: {
          linkId: created.id,
          permissions: dto.permissions,
          maxUses: dto.maxUses ?? null,
          expiresAt: expiresAt.toISOString(),
        },
        audit,
      });

      return created;
    });

    const inviteUrl = `${getInviteBaseUrl()}/${token}`;
    return {
      inviteUrl,
      qrCodeData: inviteUrl,
      token,
      permissions: dto.permissions,
      maxUses: link.maxUses,
      expiresAt: link.expiresAt,
    };
  }

  /** Public metadata for an invitation token. Never returns sensitive deal content. */
  async getInviteByToken(token: string) {
    const link = await this.prisma.dealInviteLink.findUnique({
      where: { token },
      include: {
        deal: { select: { title: true } },
        createdBy: { select: { displayName: true } },
      },
    });
    if (!link) {
      throw new NotFoundException('Invitation link not found.');
    }
    this.assertLinkUsable(link);

    return {
      dealTitle: link.deal.title,
      creatorName: link.createdBy.displayName ?? null,
      permissions: link.permissions,
      expiresAt: link.expiresAt,
      maxUses: link.maxUses,
      usedCount: link.usedCount,
    };
  }

  /** Accepts an invitation: adds the caller as a participant and consumes one use. */
  async acceptInvite(
    profileId: string,
    email: string,
    token: string,
    audit: AuditContext,
  ) {
    return this.prisma.$transaction(async (tx) => {
      const link = await tx.dealInviteLink.findUnique({ where: { token } });
      if (!link) {
        throw new NotFoundException('Invitation link not found.');
      }
      this.assertLinkUsable(link);

      const permissions = Array.isArray(link.permissions)
        ? link.permissions
        : [];
      const requiredApproval = permissions.includes('SIGN');
      const normalizedEmail = email.toLowerCase();

      await tx.dealParty.upsert({
        where: {
          dealId_email: { dealId: link.dealId, email: normalizedEmail },
        },
        create: {
          dealId: link.dealId,
          profileId,
          email: normalizedEmail,
          role: 'PARTICIPANT',
          requiredApproval,
          invitedByProfileId: link.createdByProfileId,
          partyStatus: PartyStatus.ACCEPTED,
          acceptedAt: new Date(),
        },
        update: {
          profileId,
          partyStatus: PartyStatus.ACCEPTED,
          acceptedAt: new Date(),
        },
      });

      await tx.dealInviteLink.update({
        where: { id: link.id },
        data: { usedCount: { increment: 1 } },
      });

      await this.writeAudit(tx, {
        actorProfileId: profileId,
        actionType: AuditActionType.DEAL_INVITE_ACCEPTED,
        resourceId: link.dealId,
        metadata: { linkId: link.id },
        audit,
      });

      return tx.deal.findUnique({
        where: { id: link.dealId },
        include: {
          versions: { orderBy: { versionNumber: 'asc' } },
          parties: true,
        },
      });
    });
  }

  /** Revokes an invitation link (creator only). Idempotent. */
  async revokeShareLink(
    profileId: string,
    dealId: string,
    token: string,
    audit: AuditContext,
  ) {
    const deal = await this.getDealOrThrow(dealId);
    this.assertCreator(deal, profileId);

    const link = await this.prisma.dealInviteLink.findFirst({
      where: { token, dealId },
    });
    if (!link) {
      throw new NotFoundException('Invitation link not found for this deal.');
    }
    if (link.revokedAt) {
      return {
        token: this.maskToken(token),
        revoked: true,
        revokedAt: link.revokedAt,
      };
    }

    const revokedAt = new Date();
    await this.prisma.$transaction(async (tx) => {
      await tx.dealInviteLink.update({
        where: { id: link.id },
        data: { revokedAt },
      });
      await this.writeAudit(tx, {
        actorProfileId: profileId,
        actionType: AuditActionType.DEAL_INVITE_REVOKED,
        resourceId: dealId,
        metadata: { linkId: link.id },
        audit,
      });
    });

    return { token: this.maskToken(token), revoked: true, revokedAt };
  }

  /** Lists invitation links for a deal (creator only). Tokens are masked for display. */
  async listShareLinks(profileId: string, dealId: string) {
    const deal = await this.getDealOrThrow(dealId);
    this.assertCreator(deal, profileId);

    const links = await this.prisma.dealInviteLink.findMany({
      where: { dealId },
      orderBy: { createdAt: 'desc' },
    });

    return links.map((link) => ({
      id: link.id,
      tokenPreview: this.maskToken(link.token),
      permissions: link.permissions,
      expiresAt: link.expiresAt,
      usedCount: link.usedCount,
      maxUses: link.maxUses,
      revokedAt: link.revokedAt,
      createdAt: link.createdAt,
    }));
  }

 // ---------------------------------------------------------------------------
  // Admin dashboard (Next.js) — reintroduced from dev
  // ---------------------------------------------------------------------------

  /** Global deals overview for the admin table (pagination + status/search filter). */
  async getGlobalDealsDashboard(filters: {
    status?: DealStatus;
    search?: string;
    page: number;
    limit: number;
  }) {
    const { status, search, page, limit } = filters;
    const skip = (page - 1) * limit;

    const whereCondition: any = {
      archivedAt: null,
    };

    if (status) {
      whereCondition.status = status;
    }

    if (search) {
      whereCondition.OR = [
        { title: { contains: search, mode: 'insensitive' } },
        { creator: { displayName: { contains: search, mode: 'insensitive' } } },
        { creator: { email: { contains: search, mode: 'insensitive' } } },
        { company: { legalName: { contains: search, mode: 'insensitive' } } },
      ];
    }

    const [deals, totalCount] = await Promise.all([
      this.prisma.deal.findMany({
        where: whereCondition,
        include: {
          creator: { select: { displayName: true, email: true } },
          company: { select: { legalName: true } },
          parties: { select: { id: true, partyStatus: true } },
          files: { select: { id: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.deal.count({ where: whereCondition }),
    ]);

    const items = deals.map((deal) => ({
      id: deal.id,
      title: deal.title,
      company: deal.company?.legalName || 'Individual Creator / Freelance',
      creator: deal.creator.displayName || deal.creator.email,
      status: deal.status,
      participantsCount: deal.parties.length,
      attachmentsCount: deal.files.length,
      createdAt: deal.createdAt,
    }));

    return {
      items,
      meta: {
        totalItems: totalCount,
        currentPage: page,
        totalPages: Math.ceil(totalCount / limit),
      },
    };
  }

  /** Deep deal detail for the admin inspector. */
  async getAdminDealById(id: string) {
    const deal = await this.prisma.deal.findUnique({
      where: { id },
      include: {
        creator: true,
        company: true,
        parties: { include: { profile: true } },
        versions: { orderBy: { versionNumber: 'desc' } },
        files: true,
        messages: { orderBy: { createdAt: 'asc' }, take: 50 },
      },
    });

    if (!deal)
      throw new NotFoundException(
        'Requested deal reference record could not be found.',
      );
    return deal;
  }

  /** Force-override a deal's status to resolve a deadlock (audited). */
  async overrideDealStatus(id: string, status: DealStatus, reason: string) {
    const deal = await this.prisma.deal.findUnique({ where: { id } });
    if (!deal)
      throw new NotFoundException('Target contract system reference missing.');

    return this.prisma.$transaction(async (tx) => {
      const updatedDeal = await tx.deal.update({
        where: { id },
        data: { status },
      });

      await tx.adminAction.create({
        data: {
          adminProfileId: 'placeholder-profile-id',
          actionType: 'ADMIN_ACTION',
          targetResourceType: 'DEAL',
          targetResourceId: id,
          reason: reason,
          metadataJson: { originalStatus: deal.status, overriddenTo: status },
        },
      });

      return updatedDeal;
    });
  }
  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  private async getDealOrThrow(dealId: string) {
    const deal = await this.prisma.deal.findUnique({ where: { id: dealId } });
    if (!deal) {
      throw new NotFoundException('Deal not found.');
    }
    return deal;
  }

  private assertCreator(
    deal: { creatorProfileId: string },
    profileId: string,
  ): void {
    if (deal.creatorProfileId !== profileId) {
      throw new ForbiddenException(
        'Only the deal creator can perform this action.',
      );
    }
  }

  private assertLinkUsable(link: {
    revokedAt: Date | null;
    expiresAt: Date;
    maxUses: number | null;
    usedCount: number;
  }): void {
    if (link.revokedAt) {
      throw new ForbiddenException('This invitation link has been revoked.');
    }
    if (link.expiresAt.getTime() <= Date.now()) {
      throw new ForbiddenException('This invitation link has expired.');
    }
    if (link.maxUses !== null && link.usedCount >= link.maxUses) {
      throw new ForbiddenException(
        'This invitation link has reached its maximum number of uses.',
      );
    }
  }

  private maskToken(token: string): string {
    return `••••${token.slice(-6)}`;
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
        resourceType: 'Deal',
        resourceId: params.resourceId,
        metadataJson: params.metadata,
        ipAddress: params.audit.ipAddress ?? null,
        userAgent: params.audit.userAgent ?? null,
      },
    });
  }
}
