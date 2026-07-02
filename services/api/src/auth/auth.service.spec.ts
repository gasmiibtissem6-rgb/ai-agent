import {
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { AdminRole, KycStatus, Profile } from '@prisma/client';
import { AuthService } from './auth.service';
import { PrismaService } from '../prisma/prisma.service';

const buildProfile = (overrides: Partial<Profile> = {}): Profile =>
  ({
    id: 'profile-1',
    authUserId: 'auth-user-1',
    email: 'user@example.com',
    displayName: 'User',
    avatarUrl: null,
    kycStatus: KycStatus.APPROVED,
    isAdmin: false,
    adminRole: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    archivedAt: null,
    ...overrides,
  }) as Profile;

describe('AuthService.verifyToken', () => {
  let service: AuthService;
  let prisma: {
    profile: {
      findUnique: jest.Mock;
      update: jest.Mock;
      create: jest.Mock;
    };
  };
  let jwtService: { verifyAsync: jest.Mock; signAsync: jest.Mock };
  let config: Record<string, string | undefined>;

  const configService = {
    get: (key: string) => config[key],
  } as unknown as ConfigService;

  beforeEach(() => {
    // Keep supabase client null by leaving SUPABASE_URL/ANON unset by default.
    config = { JWT_SECRET: 'nest-secret' };
    prisma = {
      profile: {
        findUnique: jest.fn(),
        update: jest.fn(),
        create: jest.fn(),
      },
    };
    jwtService = { verifyAsync: jest.fn(), signAsync: jest.fn() };
    service = new AuthService(
      prisma as unknown as PrismaService,
      configService,
      jwtService as unknown as JwtService,
    );
  });

  it('accepts a valid NestJS-signed token and returns a normalized admin user', async () => {
    jwtService.verifyAsync.mockResolvedValue({
      sub: 'auth-user-1',
      exp: 1893456000,
    });
    prisma.profile.findUnique.mockResolvedValue(
      buildProfile({ isAdmin: true, adminRole: AdminRole.SUPER_ADMIN }),
    );

    const user = await service.verifyToken('valid.nest.token');

    expect(user).toMatchObject({
      sub: 'auth-user-1',
      profileId: 'profile-1',
      isAdmin: true,
      adminRole: AdminRole.SUPER_ADMIN,
      tokenType: 'nestjs',
      exp: 1893456000,
    });
  });

  it('rejects an invalid / expired token when no Supabase fallback exists', async () => {
    jwtService.verifyAsync.mockRejectedValue(new Error('jwt expired'));

    await expect(service.verifyToken('expired.token')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('rejects when token is empty', async () => {
    await expect(service.verifyToken('')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('falls back to Supabase getUser and returns a supabase-typed user', async () => {
    // NestJS verification fails so the Supabase branch runs.
    jwtService.verifyAsync.mockRejectedValue(new Error('bad signature'));
    // Inject a stub Supabase client (no SUPABASE_JWT_SECRET → network path).
    (service as unknown as {
      supabase: { auth: { getUser: jest.Mock } };
    }).supabase = {
      auth: {
        getUser: jest.fn().mockResolvedValue({
          data: { user: { id: 'auth-user-1' } },
          error: null,
        }),
      },
    };
    prisma.profile.findUnique.mockResolvedValue(buildProfile());

    const user = await service.verifyToken('supabase.token');

    expect(user).toMatchObject({
      sub: 'auth-user-1',
      tokenType: 'supabase',
      isAdmin: false,
    });
  });

  it('rejects a token belonging to an archived (deactivated) profile', async () => {
    jwtService.verifyAsync.mockResolvedValue({ sub: 'auth-user-1' });
    prisma.profile.findUnique.mockResolvedValue(
      buildProfile({ archivedAt: new Date() }),
    );

    await expect(service.verifyToken('valid.nest.token')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  describe('getMe', () => {
    it('returns the profile for an authenticated user', async () => {
      const profile = buildProfile();
      prisma.profile.findUnique.mockResolvedValue(profile);

      const result = await service.getMe({
        sub: 'auth-user-1',
        profileId: 'profile-1',
        email: 'user@example.com',
        isAdmin: false,
        adminRole: null,
        kycStatus: KycStatus.APPROVED,
        tokenType: 'supabase',
      });

      expect(prisma.profile.findUnique).toHaveBeenCalledWith({
        where: { id: 'profile-1' },
      });
      expect(result).toBe(profile);
    });
  });

  describe('login', () => {
    it('uses documented default local admin credentials in development', async () => {
      config = { JWT_SECRET: 'nest-secret', NODE_ENV: 'development' };
      service = new AuthService(
        prisma as unknown as PrismaService,
        configService,
        jwtService as unknown as JwtService,
      );

      const adminProfile = buildProfile({
        email: 'admin@ideal.local',
        isAdmin: true,
        adminRole: AdminRole.SUPER_ADMIN,
      });
      prisma.profile.findUnique.mockResolvedValue(null);
      prisma.profile.create.mockResolvedValue(adminProfile);
      jwtService.signAsync.mockResolvedValue('signed.local.admin.jwt');

      const result = await service.login('admin@ideal.local', 'ChangeMe123!');

      expect(prisma.profile.create).toHaveBeenCalled();
      expect(result).toEqual({ token: 'signed.local.admin.jwt' });
    });

    it('requires explicit local admin credentials outside local development', async () => {
      config = { JWT_SECRET: 'nest-secret', NODE_ENV: 'test' };
      service = new AuthService(
        prisma as unknown as PrismaService,
        configService,
        jwtService as unknown as JwtService,
      );

      await expect(
        service.login('admin@ideal.local', 'ChangeMe123!'),
      ).rejects.toBeInstanceOf(ServiceUnavailableException);
    });
  });
});
