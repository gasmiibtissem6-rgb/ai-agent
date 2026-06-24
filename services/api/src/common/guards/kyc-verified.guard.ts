// services/api/src/common/guards/kyc-verified.guard.ts
import { Injectable, CanActivate, ExecutionContext, ForbiddenException, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service'; // Adjust path to your PrismaService
import { KycStatus } from '@prisma/client';

@Injectable()
export class KycVerifiedGuard implements CanActivate {
  // Inject Prisma to look up the DB state dynamically
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user; // Appended previously by your AuthGuard

    if (!user || !user.sub) {
      throw new UnauthorizedException('Authentication context missing. Ensure AuthGuard is applied first.');
    }

    // Query the structural database state using the Supabase authUserId mapping index
    const profile = await this.prisma.profile.findUnique({
      where: { authUserId: user.sub },
      select: { kycStatus: true, isAdmin: true },
    });

    if (!profile) {
      throw new ForbiddenException('User profile record could not be found.');
    }

    // Business Rule Gatekeep: Allow access only if status is fully APPROVED
    if (profile.kycStatus !== KycStatus.APPROVED) {
      throw new ForbiddenException(
        `Access Denied: Verification status is current ${profile.kycStatus}. Full KYC Approval required.`
      );
    }

    // Optional optimization: Attach full database structural roles to request object if needed later
    request.user.kycStatus = profile.kycStatus;
    request.user.isAdmin = profile.isAdmin;

    return true;
  }
}