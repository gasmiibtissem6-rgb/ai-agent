import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtAuthGuard } from './jwt-auth.guard';
import { AuthService } from '../auth.service';
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

const buildContext = (
  authorization?: string,
): { ctx: ExecutionContext; request: { headers: Record<string, string>; user?: AuthenticatedUser } } => {
  const request: { headers: Record<string, string>; user?: AuthenticatedUser } =
    { headers: authorization ? { authorization } : {} };
  const ctx = {
    switchToHttp: () => ({ getRequest: () => request }),
    // Real Reflector reads metadata off these targets, so they must be objects.
    getHandler: () => function handler() {},
    getClass: () => class Ctrl {},
  } as unknown as ExecutionContext;
  return { ctx, request };
};

describe('JwtAuthGuard', () => {
  let guard: JwtAuthGuard;
  let authService: { verifyToken: jest.Mock };
  let reflector: Reflector;

  beforeEach(() => {
    authService = { verifyToken: jest.fn() };
    reflector = new Reflector();
    guard = new JwtAuthGuard(
      authService as unknown as AuthService,
      reflector,
    );
  });

  it('allows a request with a valid token and attaches the user', async () => {
    const user = buildUser();
    authService.verifyToken.mockResolvedValue(user);
    const { ctx, request } = buildContext('Bearer valid.token');

    await expect(guard.canActivate(ctx)).resolves.toBe(true);
    expect(authService.verifyToken).toHaveBeenCalledWith('valid.token');
    expect(request.user).toEqual(user);
  });

  it('rejects when the Authorization header is missing', async () => {
    const { ctx } = buildContext();

    await expect(guard.canActivate(ctx)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
    expect(authService.verifyToken).not.toHaveBeenCalled();
  });

  it('rejects a non-Bearer scheme', async () => {
    const { ctx } = buildContext('Basic abc123');

    await expect(guard.canActivate(ctx)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
    expect(authService.verifyToken).not.toHaveBeenCalled();
  });

  it('propagates rejection for an invalid / expired token', async () => {
    authService.verifyToken.mockRejectedValue(
      new UnauthorizedException('Invalid or expired authentication token.'),
    );
    const { ctx } = buildContext('Bearer expired.token');

    await expect(guard.canActivate(ctx)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('bypasses validation for @Public() routes', async () => {
    jest.spyOn(reflector, 'getAllAndOverride').mockReturnValue(true);
    const { ctx } = buildContext();

    await expect(guard.canActivate(ctx)).resolves.toBe(true);
    expect(authService.verifyToken).not.toHaveBeenCalled();
  });
});
