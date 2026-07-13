import { Injectable } from '@nestjs/common';
import { NotificationType, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

/** Payload for emitting a single in-app notification. */
export interface CreateNotificationInput {
  profileId: string;
  type: NotificationType;
  title: string;
  body?: string | null;
  payload?: Prisma.InputJsonValue;
}

/**
 * In-app notifications. Deals/KYC call `create`/`createMany` to emit events;
 * the mobile app reads them through the endpoints on NotificationsController.
 */
@Injectable()
export class NotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  /** Emits one notification. Uses the caller's transaction client when provided. */
  async create(
    input: CreateNotificationInput,
    tx?: Prisma.TransactionClient,
  ) {
    const client = tx ?? this.prisma;
    return client.notification.create({
      data: {
        profileId: input.profileId,
        notificationType: input.type,
        title: input.title,
        body: input.body ?? null,
        payloadJson: input.payload ?? {},
      },
    });
  }

  /** Emits the same notification to several recipients (skips empty lists). */
  async createMany(
    inputs: CreateNotificationInput[],
    tx?: Prisma.TransactionClient,
  ): Promise<void> {
    if (inputs.length === 0) return;
    const client = tx ?? this.prisma;
    await client.notification.createMany({
      data: inputs.map((input) => ({
        profileId: input.profileId,
        notificationType: input.type,
        title: input.title,
        body: input.body ?? null,
        payloadJson: (input.payload ?? {}) as Prisma.InputJsonValue,
      })),
    });
  }

  /** Lists the caller's notifications, newest first. */
  async listForProfile(profileId: string, limit = 50) {
    return this.prisma.notification.findMany({
      where: { profileId },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }

  /** Count of unread notifications for the badge. */
  async unreadCount(profileId: string): Promise<{ count: number }> {
    const count = await this.prisma.notification.count({
      where: { profileId, readAt: null },
    });
    return { count };
  }

  /** Marks a single notification read (only if it belongs to the caller). */
  async markRead(profileId: string, id: string): Promise<{ updated: number }> {
    const result = await this.prisma.notification.updateMany({
      where: { id, profileId, readAt: null },
      data: { readAt: new Date() },
    });
    return { updated: result.count };
  }

  /** Marks every unread notification for the caller as read. */
  async markAllRead(profileId: string): Promise<{ updated: number }> {
    const result = await this.prisma.notification.updateMany({
      where: { profileId, readAt: null },
      data: { readAt: new Date() },
    });
    return { updated: result.count };
  }
}
