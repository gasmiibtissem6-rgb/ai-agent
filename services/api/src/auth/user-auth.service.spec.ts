import {
  BadRequestException,
  ConflictException,
  UnauthorizedException,
} from '@nestjs/common';
import { KycStatus, Profile } from '@prisma/client';
import { UserAuthService } from './user-auth.service';

/**
 * The two Supabase clients are built in the constructor from ConfigService.
 * By making ConfigService.get return undefined, the constructor leaves both
 * clients null; each test then injects lightweight fakes on the private fields.
 * This keeps the suite fully offline (no real Supabase, no network).
 */
describe('UserAuthService', () => {
  let service: UserAuthService;
  let prisma: {
    profile: { upsert: jest.Mock };
    auditLog: { create: jest.Mock };
  };
  let anonAuth: {
    signInWithPassword: jest.Mock;
    refreshSession: jest.Mock;
    resetPasswordForEmail: jest.Mock;
  };
  let adminAuth: { createUser: jest.Mock; signOut: jest.Mock };

  const buildProfile = (overrides: Partial<Profile> = {}): Profile => ({
    id: 'profile-1',
    authUserId: 'auth-user-1',
    email: 'user@example.com',
    displayName: 'Jane Doe',
    avatarUrl: null,
    kycStatus: KycStatus.NOT_STARTED,
    isAdmin: false,
    adminRole: null,
    createdAt: new Date('2026-01-01T00:00:00Z'),
    updatedAt: new Date('2026-01-01T00:00:00Z'),
    archivedAt: null,
    ...overrides,
  });

  const buildSession = (over: Record<string, unknown> = {}) => ({
    access_token: 'access-token',
    refresh_token: 'refresh-token',
    expires_at: 1_800_000_000,
    user: { id: 'auth-user-1' },
    ...over,
  });

  beforeEach(() => {
    prisma = {
      profile: { upsert: jest.fn() },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    const config = { get: jest.fn().mockReturnValue(undefined) };

    service = new UserAuthService(prisma as never, config as never);

    anonAuth = {
      signInWithPassword: jest.fn(),
      refreshSession: jest.fn(),
      resetPasswordForEmail: jest.fn(),
    };
    adminAuth = { createUser: jest.fn(), signOut: jest.fn() };

    // Inject fake Supabase clients over the (null) private fields.
    (service as unknown as { anon: unknown }).anon = { auth: anonAuth };
    (service as unknown as { admin: unknown }).admin = {
      auth: { admin: adminAuth },
    };
  });

  describe('register', () => {
    it('creates the user, ensures a Profile row, returns tokens + audits', async () => {
      adminAuth.createUser.mockResolvedValue({
        data: { user: { id: 'auth-user-1' } },
        error: null,
      });
      prisma.profile.upsert.mockResolvedValue(buildProfile());
      anonAuth.signInWithPassword.mockResolvedValue({
        data: { session: buildSession() },
        error: null,
      });

      const result = await service.register(
        {
          email: 'User@Example.com',
          password: 'S3curePass',
          fullName: 'Jane Doe',
        },
        { ipAddress: '127.0.0.1', userAgent: 'jest' },
      );

      // Email normalized to lowercase before hitting Supabase + Prisma.
      expect(adminAuth.createUser).toHaveBeenCalledWith(
        expect.objectContaining({
          email: 'user@example.com',
          email_confirm: true,
        }),
      );
      expect(prisma.profile.upsert).toHaveBeenCalledWith(
        expect.objectContaining({ where: { authUserId: 'auth-user-1' } }),
      );
      expect(prisma.auditLog.create).toHaveBeenCalledTimes(1);
      expect(result.data.access_token).toBe('access-token');
      expect(result.data.refresh_token).toBe('refresh-token');
      expect(result.data.expires_at).toBe(1_800_000_000);
      expect(result.data.user).toEqual({
        id: 'profile-1',
        email: 'user@example.com',
        fullName: 'Jane Doe',
      });
    });

    it('maps a duplicate email to a 409 ConflictException', async () => {
      adminAuth.createUser.mockResolvedValue({
        data: { user: null },
        error: {
          message: 'A user with this email address has already been registered',
          code: 'email_exists',
        },
      });

      await expect(
        service.register(
          {
            email: 'dupe@example.com',
            password: 'S3curePass',
            fullName: 'Dupe',
          },
          {},
        ),
      ).rejects.toBeInstanceOf(ConflictException);
      expect(prisma.profile.upsert).not.toHaveBeenCalled();
    });

    it('maps a weak password to a 400 BadRequestException', async () => {
      adminAuth.createUser.mockResolvedValue({
        data: { user: null },
        error: {
          message: 'Password should be at least 6 characters',
          code: 'weak_password',
        },
      });

      await expect(
        service.register(
          {
            email: 'weak@example.com',
            password: 'S3curePass',
            fullName: 'Weak',
          },
          {},
        ),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('login', () => {
    it('returns tokens plus the canonical profile on valid credentials', async () => {
      anonAuth.signInWithPassword.mockResolvedValue({
        data: { session: buildSession() },
        error: null,
      });
      prisma.profile.upsert.mockResolvedValue(buildProfile());

      const result = await service.login({
        email: 'user@example.com',
        password: 'S3curePass',
      });

      expect(result.data.access_token).toBe('access-token');
      expect(result.data.profile.id).toBe('profile-1');
      expect(result.data.profile.email).toBe('user@example.com');
    });

    it('rejects invalid credentials with 401', async () => {
      anonAuth.signInWithPassword.mockResolvedValue({
        data: { session: null },
        error: { message: 'Invalid login credentials' },
      });

      await expect(
        service.login({ email: 'user@example.com', password: 'wrong' }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });
  });

  describe('refresh', () => {
    it('returns fresh tokens for a valid refresh token', async () => {
      anonAuth.refreshSession.mockResolvedValue({
        data: {
          session: buildSession({
            access_token: 'new-access',
            refresh_token: 'new-refresh',
            expires_at: 1_900_000_000,
          }),
        },
        error: null,
      });

      const result = await service.refresh({ refresh_token: 'old-refresh' });

      expect(anonAuth.refreshSession).toHaveBeenCalledWith({
        refresh_token: 'old-refresh',
      });
      expect(result.data.access_token).toBe('new-access');
      expect(result.data.refresh_token).toBe('new-refresh');
      expect(result.data.expires_at).toBe(1_900_000_000);
    });

    it('rejects an invalid/expired refresh token with 401', async () => {
      anonAuth.refreshSession.mockResolvedValue({
        data: { session: null },
        error: { message: 'Invalid Refresh Token' },
      });

      await expect(
        service.refresh({ refresh_token: 'bad' }),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });
  });

  describe('logout', () => {
    it('signs the token out server-side and confirms success', async () => {
      adminAuth.signOut.mockResolvedValue({ data: null, error: null });

      const result = await service.logout('access-token');

      expect(adminAuth.signOut).toHaveBeenCalledWith('access-token');
      expect(result.data.success).toBe(true);
    });

    it('never fails even if Supabase signOut throws', async () => {
      adminAuth.signOut.mockRejectedValue(new Error('network down'));

      await expect(service.logout('access-token')).resolves.toMatchObject({
        data: { success: true },
      });
    });
  });

  describe('forgotPassword', () => {
    it('returns a generic success when the email exists', async () => {
      anonAuth.resetPasswordForEmail.mockResolvedValue({
        data: {},
        error: null,
      });

      const result = await service.forgotPassword({
        email: 'user@example.com',
      });

      expect(anonAuth.resetPasswordForEmail).toHaveBeenCalled();
      expect(result.data.success).toBe(true);
    });

    it('returns the SAME generic success even when the provider errors', async () => {
      anonAuth.resetPasswordForEmail.mockRejectedValue(
        new Error('unknown email'),
      );

      const result = await service.forgotPassword({
        email: 'ghost@example.com',
      });

      expect(result.data.success).toBe(true);
      expect(result.message).toContain('If an account exists');
    });
  });
});
