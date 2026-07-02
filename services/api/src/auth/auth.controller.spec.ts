import { Test, TestingModule } from '@nestjs/testing';
import { KycStatus, Profile } from '@prisma/client';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { AuthenticatedUser } from './types/authenticated-user';

describe('AuthController', () => {
  let controller: AuthController;
  let authService: { getMe: jest.Mock; login: jest.Mock };

  const currentUser: AuthenticatedUser = {
    sub: 'auth-user-1',
    profileId: 'profile-1',
    email: 'user@example.com',
    isAdmin: false,
    adminRole: null,
    kycStatus: KycStatus.APPROVED,
    tokenType: 'supabase',
  };

  beforeEach(async () => {
    authService = { getMe: jest.fn(), login: jest.fn() };

    const moduleRef: TestingModule = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [{ provide: AuthService, useValue: authService }],
    })
      // The guard's behavior is covered by its own spec; bypass it here.
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .compile();

    controller = moduleRef.get(AuthController);
  });

  describe('GET /auth/me', () => {
    it('returns the profile resolved from the authenticated user', async () => {
      const profile = { id: 'profile-1', email: 'user@example.com' } as Profile;
      authService.getMe.mockResolvedValue(profile);

      const result = await controller.getMe(currentUser);

      expect(authService.getMe).toHaveBeenCalledWith(currentUser);
      expect(result).toBe(profile);
    });
  });

  describe('POST /auth/login/admin', () => {
    it('delegates credentials to AuthService.login', async () => {
      authService.login.mockResolvedValue({ token: 'jwt' });

      const result = await controller.login({
        email: 'admin@ideal.local',
        password: 'ChangeMe123!',
      });

      expect(authService.login).toHaveBeenCalledWith(
        'admin@ideal.local',
        'ChangeMe123!',
      );
      expect(result).toEqual({ token: 'jwt' });
    });
  });
});
