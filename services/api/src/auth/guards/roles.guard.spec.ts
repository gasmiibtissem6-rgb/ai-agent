import {
  ExecutionContext,
  ForbiddenException,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AdminRole } from '@prisma/client';
import { RolesGuard } from './roles.guard';
import { AuthenticatedUser } from '../types/authenticated-user';

const buildUser = (
  overrides: Partial<AuthenticatedUser> = {},
): AuthenticatedUser => ({
  sub: 'auth-user-1',
  profileId: 'profile-1',
  email: 'user@example.com',
  isAdmin: false,
  adminRole: null,
  kycStatus: 'APPROVED',
  tokenType: 'supabase',
  ...overrides,
});

const buildContext = (user?: AuthenticatedUser): ExecutionContext =>
  ({
    switchToHttp: () => ({ getRequest: () => ({ user }) }),
    getHandler: () => function handler() {},
    getClass: () => class Ctrl {},
  }) as unknown as ExecutionContext;

describe('RolesGuard', () => {
  let guard: RolesGuard;
  let reflector: Reflector;

  beforeEach(() => {
    reflector = new Reflector();
    guard = new RolesGuard(reflector);
  });

  const mockRequired = (value: AdminRole[] | undefined) =>
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(value);

  it('allows any route with no @Roles() metadata', () => {
    mockRequired(undefined);
    expect(guard.canActivate(buildContext(buildUser()))).toBe(true);
  });

  it('denies a normal user on an admin route (@Roles() any-admin)', () => {
    mockRequired([]); // @Roles() with no args → any admin
    expect(() => guard.canActivate(buildContext(buildUser()))).toThrow(
      ForbiddenException,
    );
  });

  it('allows any admin for @Roles() with no specific role', () => {
    mockRequired([]);
    const admin = buildUser({ isAdmin: true, adminRole: AdminRole.SUPPORT_REVIEWER });
    expect(guard.canActivate(buildContext(admin))).toBe(true);
  });

  it('denies an admin whose role is not in the required list', () => {
    mockRequired([AdminRole.SUPER_ADMIN, AdminRole.ADMIN]);
    const reviewer = buildUser({
      isAdmin: true,
      adminRole: AdminRole.FINANCE_REVIEWER,
    });
    expect(() => guard.canActivate(buildContext(reviewer))).toThrow(
      ForbiddenException,
    );
  });

  it('allows an admin whose role is in the required list', () => {
    mockRequired([
      AdminRole.SUPER_ADMIN,
      AdminRole.ADMIN,
      AdminRole.SUPPORT_REVIEWER,
    ]);
    const reviewer = buildUser({
      isAdmin: true,
      adminRole: AdminRole.SUPPORT_REVIEWER,
    });
    expect(guard.canActivate(buildContext(reviewer))).toBe(true);
  });

  it('rejects when no authenticated user is present', () => {
    mockRequired([]);
    expect(() => guard.canActivate(buildContext(undefined))).toThrow(
      UnauthorizedException,
    );
  });
});
