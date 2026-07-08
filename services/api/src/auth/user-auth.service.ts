import {
  BadRequestException,
  ConflictException,
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import type { AuthError, Session } from '@supabase/supabase-js';
import { AuditActionType, KycStatus, Profile } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';

/** Request context captured on audit records (never contains secrets). */
export interface AuthRequestContext {
  ipAddress?: string;
  userAgent?: string;
}

/** Normalized session tokens returned to the client. */
export interface SessionTokens {
  access_token: string;
  refresh_token: string;
  expires_at: number | null;
}

/**
 * End-user authentication, delegated entirely to Supabase Auth (server-side).
 *
 * This service is ADDITIVE: it does not touch the existing admin login flow in
 * {@link AuthService} (POST /auth/login/admin), the unified {@link JwtAuthGuard},
 * or GET /auth/me. It owns register / login / refresh / logout / forgot-password.
 *
 * Two Supabase clients are used:
 *  - `anon`  (SUPABASE_ANON_KEY): password sign-in, refresh, password-reset email.
 *  - `admin` (SUPABASE_SERVICE_ROLE_KEY): privileged createUser + server-side signOut.
 *
 * Password verification and token issuance are NEVER done locally — Supabase owns them.
 */
@Injectable()
export class UserAuthService {
  private readonly anon: SupabaseClient | null;
  private readonly admin: SupabaseClient | null;

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
  ) {
    const url = this.config.get<string>('SUPABASE_URL');
    const anonKey = this.config.get<string>('SUPABASE_ANON_KEY');
    const serviceRoleKey = this.config.get<string>('SUPABASE_SERVICE_ROLE_KEY');

    const clientOptions = {
      auth: { autoRefreshToken: false, persistSession: false },
    } as const;

    this.anon =
      url && anonKey ? createClient(url, anonKey, clientOptions) : null;
    this.admin =
      url && serviceRoleKey
        ? createClient(url, serviceRoleKey, clientOptions)
        : null;
  }

  // ---------------------------------------------------------------------------
  // Public flows
  // ---------------------------------------------------------------------------

  /**
   * Creates a Supabase user (email pre-confirmed via the service-role client),
   * guarantees a Profile row exists, then signs in to return a live session.
   */
  async register(dto: RegisterDto, ctx: AuthRequestContext) {
    const email = this.normalizeEmail(dto.email);

    const { data, error } = await this.adminClient().auth.admin.createUser({
      email,
      password: dto.password,
      email_confirm: true,
      user_metadata: { full_name: dto.fullName },
    });

    if (error || !data.user) {
      this.throwFromSignUpError(error);
    }

    const authUserId = data.user.id;

    // Never depend on a DB trigger: upsert by authUserId (idempotent).
    const profile = await this.prisma.profile.upsert({
      where: { authUserId },
      update: {},
      create: {
        authUserId,
        email,
        displayName: dto.fullName,
        kycStatus: KycStatus.NOT_STARTED,
      },
    });

    const session = await this.signIn(email, dto.password);
    await this.writeAccountCreatedAudit(profile.id, ctx);

    return {
      message: 'Registration successful.',
      data: {
        user: {
          id: profile.id,
          email: profile.email,
          fullName: profile.displayName,
        },
        ...this.toTokens(session),
      },
    };
  }

  /**
   * Verifies credentials via Supabase and returns tokens plus the canonical
   * Profile (same row GET /auth/me resolves; self-heals if the row is missing).
   */
  async login(dto: LoginDto) {
    const email = this.normalizeEmail(dto.email);
    const session = await this.signIn(email, dto.password);
    const profile = await this.resolveProfile(session.user.id, email);

    return {
      message: 'Login successful.',
      data: {
        ...this.toTokens(session),
        profile,
      },
    };
  }

  /** Exchanges a refresh token for a new session via Supabase. */
  async refresh(dto: RefreshTokenDto) {
    const { data, error } = await this.anonClient().auth.refreshSession({
      refresh_token: dto.refresh_token,
    });

    if (error || !data.session) {
      throw new UnauthorizedException('Invalid or expired refresh token.');
    }

    return {
      message: 'Session refreshed.',
      data: this.toTokens(data.session),
    };
  }

  /**
   * Best-effort server-side sign-out of the presented access token. Never fails:
   * the token may already be invalid, and the client discards it regardless.
   */
  async logout(accessToken: string | undefined) {
    if (accessToken && this.admin) {
      try {
        await this.admin.auth.admin.signOut(accessToken);
      } catch {
        // Intentionally swallowed — logout is idempotent and must not error.
      }
    }

    return { message: 'Logged out.', data: { success: true } };
  }

  /**
   * Triggers a Supabase password-reset email. ALWAYS returns a generic success,
   * never revealing whether the email is registered (enumeration protection).
   */
  async forgotPassword(dto: ForgotPasswordDto) {
    const email = this.normalizeEmail(dto.email);

    if (this.anon) {
      try {
        const redirectTo = this.config.get<string>(
          'SUPABASE_PASSWORD_RESET_REDIRECT',
        );
        await this.anon.auth.resetPasswordForEmail(
          email,
          redirectTo ? { redirectTo } : undefined,
        );
      } catch {
        // Never surface provider errors — response must be indistinguishable.
      }
    }

    return {
      message:
        'If an account exists for this email, a password reset link has been sent.',
      data: { success: true },
    };
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  private normalizeEmail(email: string): string {
    return email.trim().toLowerCase();
  }

  private async signIn(email: string, password: string): Promise<Session> {
    const { data, error } = await this.anonClient().auth.signInWithPassword({
      email,
      password,
    });

    if (error || !data.session) {
      throw new UnauthorizedException('Invalid email or password.');
    }

    return data.session;
  }

  /** Returns the canonical Profile for a Supabase user, creating it if absent. */
  private async resolveProfile(
    authUserId: string,
    email: string,
  ): Promise<Profile> {
    return this.prisma.profile.upsert({
      where: { authUserId },
      update: {},
      create: {
        authUserId,
        email,
        kycStatus: KycStatus.NOT_STARTED,
      },
    });
  }

  private toTokens(session: Session): SessionTokens {
    return {
      access_token: session.access_token,
      refresh_token: session.refresh_token,
      expires_at: session.expires_at ?? null,
    };
  }

  private async writeAccountCreatedAudit(
    profileId: string,
    ctx: AuthRequestContext,
  ): Promise<void> {
    try {
      await this.prisma.auditLog.create({
        data: {
          actorProfileId: profileId,
          actionType: AuditActionType.ACCOUNT_CREATED,
          resourceType: 'Profile',
          resourceId: profileId,
          metadataJson: { method: 'email_password' },
          ipAddress: ctx.ipAddress ?? null,
          userAgent: ctx.userAgent ?? null,
        },
      });
    } catch {
      // Audit logging must never block the registration flow.
    }
  }

  private throwFromSignUpError(error: AuthError | null): never {
    const message = error?.message ?? 'Unable to complete registration.';
    const code = (error as { code?: string } | null)?.code;

    if (
      code === 'email_exists' ||
      /already.*(registered|exists)/i.test(message)
    ) {
      throw new ConflictException('An account with this email already exists.');
    }
    if (code === 'weak_password' || /password/i.test(message)) {
      throw new BadRequestException(message);
    }
    throw new BadRequestException(message);
  }

  private anonClient(): SupabaseClient {
    if (!this.anon) {
      throw new ServiceUnavailableException(
        'Authentication is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }
    return this.anon;
  }

  private adminClient(): SupabaseClient {
    if (!this.admin) {
      throw new ServiceUnavailableException(
        'Server-side authentication is not configured. Set SUPABASE_SERVICE_ROLE_KEY.',
      );
    }
    return this.admin;
  }
}
