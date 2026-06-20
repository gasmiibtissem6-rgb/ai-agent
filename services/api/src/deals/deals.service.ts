// services/api/src/deals/deals.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class DealsService {
  constructor(private prisma: PrismaService) {}

  async getAllDeals(authUserId: string) {
    // 1. Find the local profile ID belonging to this Supabase Auth ID
    const profile = await this.prisma.profile.findUnique({
      where: { authUserId },
      select: { id: true }, // We only need the ID to save memory
    });

    if (!profile) {
      throw new NotFoundException('Profile not found.');
    }

    // 2. Query the deals table using the creator's profile ID
    return this.prisma.deal.findMany({
      where: { creatorProfileId: profile.id },
      orderBy: { updatedAt: 'desc' },
    });
  }
}