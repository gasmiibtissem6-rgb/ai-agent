// services/api/src/profiles/profiles.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class ProfilesService {
  constructor(private prisma: PrismaService) {}

  async getProfileByUserId(userId: string) {
    // 💡 We use 'this.prisma.profile' and look up by 'authUserId'
    const profile = await this.prisma.profile.findUnique({
      where: { authUserId: userId },
    });

    if (!profile) {
      throw new NotFoundException(
        'Profile configuration not found for this account.',
      );
    }
    return profile;
  }

  /** Updates the caller's own presentation fields. Privilege fields are untouchable. */
  async updateProfileByUserId(userId: string, dto: UpdateProfileDto) {
    // Ensures the row exists and belongs to the caller before writing.
    await this.getProfileByUserId(userId);

    return this.prisma.profile.update({
      where: { authUserId: userId },
      data: {
        displayName: dto.displayName ?? undefined,
        avatarUrl: dto.avatarUrl ?? undefined,
      },
    });
  }

  async getSessionMetadata(user: AuthenticatedUser) {
    return {
      authenticated: true,
      user: {
        id: user.sub,
        profileId: user.profileId,
        email: user.email,
        isAdmin: user.isAdmin,
        adminRole: user.adminRole,
        kycStatus: user.kycStatus,
      },
      // Safely check if token expiry timestamp exists
      sessionExpiresAt: user.exp
        ? new Date(user.exp * 1000).toISOString()
        : null,
    };
  }
}
