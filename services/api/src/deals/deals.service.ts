// src/deals/deals.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class DealsService {
  constructor(private readonly prisma: PrismaService) {}

  async getDealsByUserId(authUserId: string) {
    // 1. Find the internal profile associated with the Supabase auth UUID
    const profile = await this.prisma.profile.findUnique({
      where: { authUserId: authUserId }, // Maps the 'sub' from your JWT
    });

    if (!profile) {
      throw new NotFoundException('Profile not found for this account.');
    }

    // 2. Fetch the deals belonging to this profile ID
    const deals = await this.prisma.deal.findMany({
      where: {
        creatorProfileId: profile.id, // Ensure this matches your Prisma schema relation field
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return deals;
  }
}
