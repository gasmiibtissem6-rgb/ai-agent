// services/api/src/profiles/profiles.service.ts
import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
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

    try {
      return await this.prisma.profile.update({
        where: { authUserId: userId },
        data: {
          displayName: dto.displayName ?? undefined,
          username: dto.username?.toLowerCase() ?? undefined,
          avatarUrl: dto.avatarUrl ?? undefined,
          isPublic: dto.isPublic ?? undefined,
        },
      });
    } catch (error) {
      // Unique-constraint violation on username.
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException('That username is already taken.');
      }
      throw error;
    }
  }

  /**
   * Resolves a *public* profile by username or id, for QR-scan discovery and
   * attaching a counterparty to a deal. Private profiles are never returned.
   */
  async lookupPublicProfile(query: string) {
    const value = query.trim().toLowerCase();
    if (!value) {
      throw new NotFoundException('No profile matches that code.');
    }

    const isUuid =
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(
        value,
      );

    const profile = await this.prisma.profile.findFirst({
      where: {
        isPublic: true,
        ...(isUuid ? { id: value } : { username: value }),
      },
      select: {
        id: true,
        email: true,
        displayName: true,
        username: true,
        avatarUrl: true,
        kycStatus: true,
        isPublic: true,
      },
    });

    if (!profile) {
      throw new NotFoundException(
        'No public profile matches that code (it may be private).',
      );
    }
    return profile;
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
