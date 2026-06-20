// services/api/src/profiles/profiles.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ProfilesService {
  constructor(private prisma: PrismaService) {}

  async getProfileByUserId(userId: string) {
    // 💡 We use 'this.prisma.profile' and look up by 'authUserId'
    const profile = await this.prisma.profile.findUnique({
      where: { authUserId: userId }, 
    });
    
    if (!profile) {
      throw new NotFoundException('Profile configuration not found for this account.');
    }
    return profile;
  }

  async getSessionMetadata(userPayload: any) {
    return {
      authenticated: true,
      user: {
        id: userPayload.sub,
        email: userPayload.email,
        role: userPayload.role,
      },
      // Safely check if token expiry timestamp exists
      sessionExpiresAt: userPayload.exp ? new Date(userPayload.exp * 1000).toISOString() : null,
    };
  }
}