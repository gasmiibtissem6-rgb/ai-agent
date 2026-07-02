import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AdminRole } from '@prisma/client';
import { RolesGuard } from '../auth/guards/roles.guard';
import { AuthenticatedUser } from '../auth/types/authenticated-user';
import { AdminKycController } from './admin-kyc.controller';

/**
 * Verifies the @Roles() protection declared on every AdminKycController route by running
 * the real RolesGuard against the controller's actual method metadata.
 */
describe('AdminKycController role protection', () => {
  const guard = new RolesGuard(new Reflector());

  const buildUser = (overrides: Partial<AuthenticatedUser> = {}): AuthenticatedUser => ({
    sub: 'auth-1',
    profileId: 'profile-1',
    email: 'u@example.com',
    isAdmin: false,
    adminRole: null,
    kycStatus: 'APPROVED',
    tokenType: 'supabase',
    ...overrides,
  });

  // eslint-disable-next-line @typescript-eslint/no-unsafe-function-type
  const contextFor = (user: AuthenticatedUser, handler: Function): ExecutionContext =>
    ({
      switchToHttp: () => ({ getRequest: () => ({ user }) }),
      getHandler: () => handler,
      getClass: () => AdminKycController,
    }) as unknown as ExecutionContext;

  const proto = AdminKycController.prototype;
  const reviewHandlers = [
    proto.getQueue,
    proto.getById,
    proto.approve,
    proto.reject,
    proto.requestResubmission,
    proto.revoke,
  ];
  const allHandlers = [...reviewHandlers, proto.recheck];

  it('blocks a normal (non-admin) user on every /admin/kyc/* route', () => {
    const user = buildUser({ isAdmin: false });
    for (const handler of allHandlers) {
      expect(() => guard.canActivate(contextFor(user, handler))).toThrow(
        ForbiddenException,
      );
    }
  });

  it('blocks FINANCE_REVIEWER on every /admin/kyc/* route', () => {
    const user = buildUser({ isAdmin: true, adminRole: AdminRole.FINANCE_REVIEWER });
    for (const handler of allHandlers) {
      expect(() => guard.canActivate(contextFor(user, handler))).toThrow(
        ForbiddenException,
      );
    }
  });

  it('allows SUPPORT_REVIEWER on review routes but blocks recheck', () => {
    const user = buildUser({ isAdmin: true, adminRole: AdminRole.SUPPORT_REVIEWER });
    for (const handler of reviewHandlers) {
      expect(guard.canActivate(contextFor(user, handler))).toBe(true);
    }
    expect(() => guard.canActivate(contextFor(user, proto.recheck))).toThrow(
      ForbiddenException,
    );
  });

  it('allows SUPER_ADMIN on every route including recheck', () => {
    const user = buildUser({ isAdmin: true, adminRole: AdminRole.SUPER_ADMIN });
    for (const handler of allHandlers) {
      expect(guard.canActivate(contextFor(user, handler))).toBe(true);
    }
  });
});
