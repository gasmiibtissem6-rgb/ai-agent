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

  private async loginLocalAdmin(email: string, pass: string) {
    if (this.configService.get<string>('NODE_ENV') === 'production') {
      throw new ServiceUnavailableException(
        'Supabase authentication must be configured in production.',
      );
    }

    const localAdminEmail =
      this.configService.get<string>('LOCAL_ADMIN_EMAIL') ??
      'admin@ideal.local';
    const localAdminPassword =
      this.configService.get<string>('LOCAL_ADMIN_PASSWORD') ?? 'ChangeMe123!';

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
