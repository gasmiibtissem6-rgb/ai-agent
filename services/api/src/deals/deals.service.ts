// src/deals/deals.service.ts
import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import {
  ApprovalStatus,
  AuditActionType,
  DealStatus,
  NotificationType,
  PartyStatus,
  Prisma,
  SubscriptionStatus,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { AddPartyDto } from './dto/add-party.dto';
import { RespondDealDto } from './dto/respond-deal.dto';
import { DecideVersionDto } from './dto/decide-version.dto';
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

/** Deal statuses that can never transition again. */
const TERMINAL_DEAL_STATUSES: DealStatus[] = [
  DealStatus.LOCKED,
  DealStatus.ARCHIVED,
];

@Injectable()
export class DealsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
  ) {}

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
    // A brand-new version (e.g. V1 after the locked V0) is allowed while the
    // deal is APPROVED — it starts a fresh negotiation round. Only truly
    // terminal deals (LOCKED / ARCHIVED) can never spawn a new version.
    if (TERMINAL_DEAL_STATUSES.includes(deal.status)) {
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

  // ---------------------------------------------------------------------------
  // Participation & approval workflow
  // ---------------------------------------------------------------------------

  /** Standard include used when returning a deal to the client. */
  private static readonly DEAL_INCLUDE = {
    versions: { orderBy: { versionNumber: 'asc' } },
    parties: true,
  } as const;

  /**
   * Attaches a counterparty to a deal by username OR email (creator only) and
   * notifies them if they already have an IDEAL profile.
   */
  async addParty(
    profileId: string,
    dealId: string,
    dto: AddPartyDto,
    audit: AuditContext,
  ) {
    const deal = await this.getDealOrThrow(dealId);
    this.assertCreator(deal, profileId);

    const identifier = dto.identifier.trim().toLowerCase();
    const target = await this.prisma.profile.findFirst({
      where: { OR: [{ email: identifier }, { username: identifier }] },
      select: { id: true, email: true },
    });

    const email = target?.email ?? (identifier.includes('@') ? identifier : null);
    if (!email) {
      throw new NotFoundException('No user found with that username.');
    }
    if (target?.id === profileId) {
      throw new ForbiddenException('You cannot add yourself as a counterparty.');
    }

    return this.prisma.$transaction(async (tx) => {
      await tx.dealParty.upsert({
        where: { dealId_email: { dealId, email } },
        create: {
          dealId,
          profileId: target?.id ?? null,
          email,
          role: dto.role ?? 'PARTICIPANT',
          requiredApproval: true,
          invitedByProfileId: profileId,
          partyStatus: PartyStatus.INVITED,
        },
        update: {
          profileId: target?.id ?? undefined,
          role: dto.role ?? undefined,
        },
      });

      if (target) {
        await this.notifications.create(
          {
            profileId: target.id,
            type: NotificationType.DEAL_INVITATION,
            title: 'New deal invitation',
            body: `You have been invited to "${deal.title}".`,
            payload: { dealId },
          },
          tx,
        );
      }

      await this.writeAudit(tx, {
        actorProfileId: profileId,
        actionType: AuditActionType.DEAL_UPDATED,
        resourceId: dealId,
        metadata: { action: 'PARTY_ADDED', email },
        audit,
      });

      return tx.deal.findUnique({
        where: { id: dealId },
        include: DealsService.DEAL_INCLUDE,
      });
    });
  }

  /**
   * The invited party accepts or refuses the deal. On a decision the deal
   * creator is notified. Accepting a deal opens the chat between the parties.
   */
  async respondToInvite(
    profileId: string,
    email: string,
    dealId: string,
    dto: RespondDealDto,
    audit: AuditContext,
  ) {
    return this.prisma.$transaction(async (tx) => {
      const deal = await tx.deal.findUnique({ where: { id: dealId } });
      if (!deal) {
        throw new NotFoundException('Deal not found.');
      }

      const party = await tx.dealParty.findFirst({
        where: {
          dealId,
          OR: [{ profileId }, { email: email.toLowerCase() }],
        },
      });
      if (!party) {
        throw new ForbiddenException('You were not invited to this deal.');
      }

      const now = new Date();
      await tx.dealParty.update({
        where: { id: party.id },
        data: {
          profileId,
          partyStatus: dto.accept ? PartyStatus.ACCEPTED : PartyStatus.DECLINED,
          acceptedAt: dto.accept ? now : party.acceptedAt,
          declinedAt: dto.accept ? party.declinedAt : now,
        },
      });

      await this.notifications.create(
        {
          profileId: deal.creatorProfileId,
          type: dto.accept
            ? NotificationType.APPROVED
            : NotificationType.REJECTED,
          title: dto.accept
            ? 'Deal invitation accepted'
            : 'Deal invitation declined',
          body: `${email} ${dto.accept ? 'accepted' : 'declined'} "${deal.title}".`,
          payload: { dealId, partyId: party.id },
        },
        tx,
      );

      await this.writeAudit(tx, {
        actorProfileId: profileId,
        actionType: AuditActionType.DEAL_UPDATED,
        resourceId: dealId,
        metadata: { action: dto.accept ? 'INVITE_ACCEPTED' : 'INVITE_DECLINED' },
        audit,
      });

      return tx.deal.findUnique({
        where: { id: dealId },
        include: DealsService.DEAL_INCLUDE,
      });
    });
  }

  /**
   * Creator submits a version for the accepted parties to approve. This is the
   * creator's own approval; it moves the deal to PENDING_APPROVAL and asks each
   * required, accepted party to decide.
   */
  async submitVersion(
    profileId: string,
    dealId: string,
    versionId: string,
    audit: AuditContext,
  ) {
    const deal = await this.getDealOrThrow(dealId);
    this.assertCreator(deal, profileId);

    return this.prisma.$transaction(async (tx) => {
      const version = await tx.dealVersion.findUnique({
        where: { id: versionId },
      });
      if (!version || version.dealId !== dealId) {
        throw new NotFoundException('Version not found for this deal.');
      }
      if (version.lockedAt) {
        throw new ForbiddenException(
          'This version is locked and cannot be resubmitted.',
        );
      }

      const approvers = await tx.dealParty.findMany({
        where: {
          dealId,
          requiredApproval: true,
          partyStatus: PartyStatus.ACCEPTED,
          profileId: { not: null },
        },
      });
      if (approvers.length === 0) {
        throw new ForbiddenException(
          'No party has accepted this deal yet, so there is nobody to approve it.',
        );
      }

      await tx.dealVersion.update({
        where: { id: versionId },
        data: { status: DealStatus.PENDING_APPROVAL, submittedAt: new Date() },
      });
      await tx.deal.update({
        where: { id: dealId },
        data: {
          status: DealStatus.PENDING_APPROVAL,
          currentVersionId: versionId,
        },
      });

      for (const party of approvers) {
        await tx.dealApproval.upsert({
          where: { versionId_partyId: { versionId, partyId: party.id } },
          create: {
            versionId,
            partyId: party.id,
            profileId: party.profileId!,
            approvalStatus: ApprovalStatus.PENDING,
          },
          update: {
            approvalStatus: ApprovalStatus.PENDING,
            reason: null,
            decidedAt: null,
          },
        });
      }

      await this.notifications.createMany(
        approvers.map((party) => ({
          profileId: party.profileId!,
          type: NotificationType.APPROVAL_REQUESTED,
          title: 'Approval requested',
          body: `Please review version ${version.versionNumber} of "${deal.title}".`,
          payload: { dealId, versionId },
        })),
        tx,
      );

      await this.writeAudit(tx, {
        actorProfileId: profileId,
        actionType: AuditActionType.DEAL_UPDATED,
        resourceId: dealId,
        metadata: { action: 'VERSION_SUBMITTED', versionId },
        audit,
      });

      return tx.deal.findUnique({
        where: { id: dealId },
        include: DealsService.DEAL_INCLUDE,
      });
    });
  }

  /**
   * A required party approves or rejects a submitted version. Once every
   * required, accepted party has approved the SAME version, that version is
   * locked (immutable) and the deal becomes APPROVED. The first locked version
   * is the official V0 and can never be modified afterwards.
   */
  async decideVersion(
    profileId: string,
    dealId: string,
    versionId: string,
    dto: DecideVersionDto,
    audit: AuditContext,
  ) {
    return this.prisma.$transaction(async (tx) => {
      const deal = await tx.deal.findUnique({ where: { id: dealId } });
      if (!deal) {
        throw new NotFoundException('Deal not found.');
      }
      const version = await tx.dealVersion.findUnique({
        where: { id: versionId },
      });
      if (!version || version.dealId !== dealId) {
        throw new NotFoundException('Version not found for this deal.');
      }
      if (version.lockedAt) {
        throw new ForbiddenException('This version is already locked.');
      }

      const party = await tx.dealParty.findFirst({
        where: {
          dealId,
          profileId,
          requiredApproval: true,
          partyStatus: PartyStatus.ACCEPTED,
        },
      });
      if (!party) {
        throw new ForbiddenException(
          'You are not a required approver on this deal.',
        );
      }

      const now = new Date();
      const decision = dto.approve
        ? ApprovalStatus.APPROVED
        : ApprovalStatus.REJECTED;

      await tx.dealApproval.upsert({
        where: { versionId_partyId: { versionId, partyId: party.id } },
        create: {
          versionId,
          partyId: party.id,
          profileId,
          approvalStatus: decision,
          reason: dto.reason ?? null,
          decidedAt: now,
        },
        update: {
          approvalStatus: decision,
          reason: dto.reason ?? null,
          decidedAt: now,
        },
      });

      if (!dto.approve) {
        await tx.dealVersion.update({
          where: { id: versionId },
          data: { status: DealStatus.CHANGES_REQUESTED },
        });
        await tx.deal.update({
          where: { id: dealId },
          data: { status: DealStatus.CHANGES_REQUESTED },
        });
        await this.notifications.create(
          {
            profileId: deal.creatorProfileId,
            type: NotificationType.CHANGES_REQUESTED,
            title: 'Changes requested',
            body: `A party requested changes on "${deal.title}".`,
            payload: { dealId, versionId, reason: dto.reason ?? null },
          },
          tx,
        );
        await this.writeAudit(tx, {
          actorProfileId: profileId,
          actionType: AuditActionType.DEAL_UPDATED,
          resourceId: dealId,
          metadata: { action: 'VERSION_REJECTED', versionId },
          audit,
        });
        return tx.deal.findUnique({
          where: { id: dealId },
          include: DealsService.DEAL_INCLUDE,
        });
      }

      // Approved: has every required, accepted party approved this version?
      const requiredParties = await tx.dealParty.findMany({
        where: {
          dealId,
          requiredApproval: true,
          partyStatus: PartyStatus.ACCEPTED,
        },
      });
      const approvals = await tx.dealApproval.findMany({
        where: { versionId },
      });
      const allApproved =
        requiredParties.length > 0 &&
        requiredParties.every((p) =>
          approvals.some(
            (a) =>
              a.partyId === p.id &&
              a.approvalStatus === ApprovalStatus.APPROVED,
          ),
        );

      if (allApproved) {
        // Lock this version (V0/V1/...) and mark the deal approved.
        await tx.dealVersion.update({
          where: { id: versionId },
          data: { status: DealStatus.APPROVED, lockedAt: now },
        });
        await tx.deal.update({
          where: { id: dealId },
          data: { status: DealStatus.APPROVED, lockedVersionId: versionId },
        });

        const recipients = [
          deal.creatorProfileId,
          ...requiredParties
            .map((p) => p.profileId)
            .filter((id): id is string => Boolean(id)),
        ];
        await this.notifications.createMany(
          recipients.map((pid) => ({
            profileId: pid,
            type: NotificationType.APPROVED,
            title: 'Deal approved',
            body: `Version ${version.versionNumber} of "${deal.title}" is approved and locked.`,
            payload: { dealId, versionId },
          })),
          tx,
        );
      } else {
        await this.notifications.create(
          {
            profileId: deal.creatorProfileId,
            type: NotificationType.APPROVED,
            title: 'A party approved',
            body: `A party approved version ${version.versionNumber} of "${deal.title}".`,
            payload: { dealId, versionId },
          },
          tx,
        );
      }

      await this.writeAudit(tx, {
        actorProfileId: profileId,
        actionType: AuditActionType.DEAL_UPDATED,
        resourceId: dealId,
        metadata: { action: 'VERSION_APPROVED', versionId, locked: allApproved },
        audit,
      });

      return tx.deal.findUnique({
        where: { id: dealId },
        include: DealsService.DEAL_INCLUDE,
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Party discussion (deal chat — NOT the AI assistant)
  // ---------------------------------------------------------------------------

  /** Lists the deal's discussion messages for a participant (creator or party). */
  async getMessages(profileId: string, dealId: string) {
    await this.assertParticipant(profileId, dealId);
    return this.prisma.message.findMany({
      where: { dealId, deletedAt: null },
      orderBy: { createdAt: 'asc' },
      include: {
        sender: { select: { id: true, displayName: true, email: true } },
      },
      take: 200,
    });
  }

  /** Posts a discussion message and notifies the other side of the deal. */
  async sendMessage(profileId: string, dealId: string, body: string) {
    const deal = await this.assertParticipant(profileId, dealId);

    const message = await this.prisma.message.create({
      data: { dealId, senderProfileId: profileId, body },
      include: {
        sender: { select: { id: true, displayName: true, email: true } },
      },
    });

    // Notify everyone on the deal except the sender.
    const recipients = new Set<string>();
    if (deal.creatorProfileId !== profileId) {
      recipients.add(deal.creatorProfileId);
    }
    for (const party of deal.parties) {
      if (party.profileId && party.profileId !== profileId) {
        recipients.add(party.profileId);
      }
    }
    await this.notifications.createMany(
      [...recipients].map((pid) => ({
        profileId: pid,
        type: NotificationType.CHANGES_REQUESTED,
        title: 'New message',
        body: `New message on "${deal.title}".`,
        payload: { dealId, messageId: message.id },
      })),
    );

    return message;
  }

  /** Loads the deal (with parties) and asserts the caller participates in it. */
  private async assertParticipant(profileId: string, dealId: string) {
    const deal = await this.prisma.deal.findUnique({
      where: { id: dealId },
      include: { parties: true },
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
    return deal;
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
