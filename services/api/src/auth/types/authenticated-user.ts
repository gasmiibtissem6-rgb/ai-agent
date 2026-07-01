import { AdminRole, KycStatus } from '@prisma/client';

/**
 * Origin of the bearer token that authenticated the request.
 * - `supabase`: JWT issued by Supabase Auth (Flutter mobile users, and admins in prod).
 * - `nestjs`: JWT signed by this API with JWT_SECRET (local admin dev fallback).
 */
export type TokenType = 'supabase' | 'nestjs';

/**
 * Normalized authentication context attached to `request.user` by JwtAuthGuard.
 * This is the single source of truth consumed by controllers and downstream
 * guards (RolesGuard, KycVerifiedGuard) regardless of where the token came from.
 */
export interface AuthenticatedUser {
  /** Supabase auth user id (Profile.authUserId). Stable across token types. */
  sub: string;
  /** Prisma Profile.id (internal primary key). */
  profileId: string;
  email: string;
  isAdmin: boolean;
  adminRole: AdminRole | null;
  kycStatus: KycStatus;
  tokenType: TokenType;
  /** Token expiry (epoch seconds) when available on the source JWT. */
  exp?: number;
}

/** Express request augmented with the authenticated user. */
export interface RequestWithUser {
  user: AuthenticatedUser;
  headers: Record<string, string | string[] | undefined>;
}
