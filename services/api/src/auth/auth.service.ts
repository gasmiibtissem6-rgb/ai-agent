import {
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { AdminRole, KycStatus, Profile } from '@prisma/client';
import { randomUUID } from 'crypto';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import {
  AuthenticatedUser,
  TokenType,
} from './types/authenticated-user';

const defaultLocalAdminEmail = 'admin@ideal.local';
const defaultLocalAdminPassword = 'ChangeMe123!';

@Injectable()
export class AuthService {
  private supabase: SupabaseClient | null = null;

  constructor(
    private prisma: PrismaService,
    private configService: ConfigService,
    private jwtService: JwtService,
  ) {
    const supabaseUrl = this.configService.get<string>('SUPABASE_URL');
    const supabaseKey = this.configService.get<string>('SUPABASE_ANON_KEY');

    if (supabaseUrl && supabaseKey) {
      this.supabase = createClient(supabaseUrl, supabaseKey);
    }
  }

  private getSupabaseClient(): SupabaseClient {
    if (!this.supabase) {
      throw new ServiceUnavailableException(
        'Supabase authentication is not configured yet. Add SUPABASE_URL and SUPABASE_ANON_KEY to enable auth endpoints.',
      );
    }

    return this.supabase;
  }

  async login(email: string, pass: string) {
    if (!this.supabase) {
      return this.loginLocalAdmin(email, pass);
    }

    const supabase = this.getSupabaseClient();
    const { data: authData, error } = await supabase.auth.signInWithPassword({
      email,
      password: pass,
    });

    if (error || !authData.user) {
      throw new UnauthorizedException('Invalid administrative credentials.');
    }

    // FIX: Using this.prisma.profile instead of this.prisma.user!
    const profile = await this.prisma.profile.findUnique({
      where: { authUserId: authData.user.id },
    });

    if (!profile || !profile.isAdmin) {
      throw new UnauthorizedException(
        'Access denied. Admin privileges required.',
      );
    }

    return {
      token: authData.session.access_token,
    };
  }

  async getProfile(authHeader: string) {
    if (!authHeader) {
      throw new UnauthorizedException('Missing authorization header');
    }

    const token = authHeader.replace('Bearer ', '').trim();

    if (!this.supabase) {
      return this.getLocalProfile(token);
    }

    const supabase = this.getSupabaseClient();
    const { data: authData, error } = await supabase.auth.getUser(token);

    if (error || !authData.user) {
      throw new UnauthorizedException('Invalid or expired token.');
    }

    // Fetch the actual user details from Prisma using the verified ID
    const profile = await this.prisma.profile.findUnique({
      where: { authUserId: authData.user.id },
    });

    if (!profile) {
      throw new UnauthorizedException('Profile not found.');
    }

    return profile;
  }

  /**
   * Unified token verification used by {@link JwtAuthGuard}. Accepts BOTH:
   *  - NestJS-signed JWTs (local admin dev fallback, signed with JWT_SECRET), and
   *  - Supabase JWTs (Flutter mobile users and admins authenticated via Supabase).
   *
   * Returns a normalized {@link AuthenticatedUser} backed by the Prisma Profile,
   * so every downstream guard/controller reads identity the same way regardless
   * of token origin.
   */
  async verifyToken(token: string): Promise<AuthenticatedUser> {
    if (!token) {
      throw new UnauthorizedException('Authentication token is missing.');
    }

    // 1. NestJS-signed JWT (offline, no network).
    const nestUser = await this.tryVerifyNestJwt(token);
    if (nestUser) {
      return nestUser;
    }

    // 2. Supabase JWT (offline if SUPABASE_JWT_SECRET is set, else network).
    const supabaseUser = await this.tryVerifySupabaseToken(token);
    if (supabaseUser) {
      return supabaseUser;
    }

    throw new UnauthorizedException(
      'Invalid or expired authentication token.',
    );
  }

  /**
   * Resolves the full Profile for an already-authenticated user (GET /auth/me).
   */
  async getMe(user: AuthenticatedUser): Promise<Profile> {
    const profile = await this.prisma.profile.findUnique({
      where: { id: user.profileId },
    });

    if (!profile) {
      throw new UnauthorizedException('Profile not found.');
    }

    return profile;
  }

  private async tryVerifyNestJwt(
    token: string,
  ): Promise<AuthenticatedUser | null> {
    const jwtSecret = this.configService.get<string>('JWT_SECRET');
    if (!jwtSecret) {
      return null;
    }

    try {
      const payload = await this.jwtService.verifyAsync<{
        sub: string;
        exp?: number;
      }>(token, { secret: jwtSecret });

      const profile = await this.prisma.profile.findUnique({
        where: { authUserId: payload.sub },
      });

      if (!profile) {
        return null;
      }

      return this.toAuthenticatedUser(profile, 'nestjs', payload.exp);
    } catch {
      return null;
    }
  }

  private async tryVerifySupabaseToken(
    token: string,
  ): Promise<AuthenticatedUser | null> {
    let authUserId: string | undefined;
    let exp: number | undefined;

    const supabaseJwtSecret =
      this.configService.get<string>('SUPABASE_JWT_SECRET');

    if (supabaseJwtSecret) {
      // Offline HS256 verification — no network round-trip per request.
      try {
        const payload = await this.jwtService.verifyAsync<{
          sub: string;
          exp?: number;
        }>(token, { secret: supabaseJwtSecret });
        authUserId = payload.sub;
        exp = payload.exp;
      } catch {
        return null;
      }
    } else if (this.supabase) {
      // Network verification via Supabase Auth (default).
      const { data, error } = await this.supabase.auth.getUser(token);
      if (error || !data.user) {
        return null;
      }
      authUserId = data.user.id;
    } else {
      return null;
    }

    const profile = await this.prisma.profile.findUnique({
      where: { authUserId },
    });

    if (!profile) {
      return null;
    }

    return this.toAuthenticatedUser(profile, 'supabase', exp);
  }

  private toAuthenticatedUser(
    profile: Profile,
    tokenType: TokenType,
    exp?: number,
  ): AuthenticatedUser {
    if (profile.archivedAt) {
      throw new UnauthorizedException('This account has been deactivated.');
    }

    return {
      sub: profile.authUserId,
      profileId: profile.id,
      email: profile.email,
      isAdmin: profile.isAdmin,
      adminRole: profile.adminRole,
      kycStatus: profile.kycStatus,
      tokenType,
      exp,
    };
  }

  private async loginLocalAdmin(email: string, pass: string) {
    const nodeEnv = this.configService.get<string>('NODE_ENV');

    if (nodeEnv === 'production') {
      throw new ServiceUnavailableException(
        'Supabase authentication must be configured in production.',
      );
    }

    const configuredLocalAdminEmail =
      this.configService.get<string>('LOCAL_ADMIN_EMAIL');
    const configuredLocalAdminPassword =
      this.configService.get<string>('LOCAL_ADMIN_PASSWORD');
    const useDefaultLocalAdmin =
      !configuredLocalAdminEmail &&
      !configuredLocalAdminPassword &&
      (!nodeEnv || nodeEnv === 'development');
    const localAdminEmail = useDefaultLocalAdmin
      ? defaultLocalAdminEmail
      : configuredLocalAdminEmail;
    const localAdminPassword = useDefaultLocalAdmin
      ? defaultLocalAdminPassword
      : configuredLocalAdminPassword;

    if (!localAdminEmail || !localAdminPassword) {
      throw new ServiceUnavailableException(
        'Local admin login is not configured. Set LOCAL_ADMIN_EMAIL and LOCAL_ADMIN_PASSWORD.',
      );
    }

    if (email !== localAdminEmail || pass !== localAdminPassword) {
      throw new UnauthorizedException('Invalid administrative credentials.');
    }

    const profile = await this.ensureLocalAdminProfile(localAdminEmail);
    const token = await this.signLocalAdminToken(profile);

    return { token };
  }

  private async ensureLocalAdminProfile(email: string): Promise<Profile> {
    const existingProfile = await this.prisma.profile.findUnique({
      where: { email },
    });

    if (existingProfile) {
      return this.prisma.profile.update({
        where: { id: existingProfile.id },
        data: {
          displayName: existingProfile.displayName ?? 'IDEAL Local Admin',
          isAdmin: true,
          adminRole: AdminRole.SUPER_ADMIN,
          kycStatus: KycStatus.APPROVED,
          archivedAt: null,
        },
      });
    }

    return this.prisma.profile.create({
      data: {
        authUserId: randomUUID(),
        email,
        displayName: 'IDEAL Local Admin',
        isAdmin: true,
        adminRole: AdminRole.SUPER_ADMIN,
        kycStatus: KycStatus.APPROVED,
      },
    });
  }

  private async signLocalAdminToken(profile: Profile): Promise<string> {
    const jwtSecret = this.configService.get<string>('JWT_SECRET');

    if (!jwtSecret) {
      throw new ServiceUnavailableException(
        'JWT_SECRET is required for local admin login.',
      );
    }

    return this.jwtService.signAsync(
      {
        sub: profile.authUserId,
        email: profile.email,
        role: 'admin',
        adminRole: profile.adminRole,
      },
      {
        secret: jwtSecret,
        expiresIn: '1d',
      },
    );
  }

  private async getLocalProfile(token: string): Promise<Profile> {
    const jwtSecret = this.configService.get<string>('JWT_SECRET');

    if (!jwtSecret) {
      throw new ServiceUnavailableException(
        'JWT_SECRET is required for local admin login.',
      );
    }

    try {
      const payload = await this.jwtService.verifyAsync<{ sub: string }>(
        token,
        {
          secret: jwtSecret,
        },
      );

      const profile = await this.prisma.profile.findUnique({
        where: { authUserId: payload.sub },
      });

      if (!profile || !profile.isAdmin) {
        throw new UnauthorizedException(
          'Access denied. Admin privileges required.',
        );
      }

      return profile;
    } catch (error) {
      if (error instanceof UnauthorizedException) {
        throw error;
      }

      throw new UnauthorizedException('Invalid or expired token.');
    }
  }
}
