import { Test, TestingModule } from '@nestjs/testing';
import { UserAuthController } from './user-auth.controller';
import { UserAuthService } from './user-auth.service';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

describe('UserAuthController', () => {
  let controller: UserAuthController;
  let userAuth: {
    register: jest.Mock;
    login: jest.Mock;
    refresh: jest.Mock;
    logout: jest.Mock;
    forgotPassword: jest.Mock;
  };

  beforeEach(async () => {
    userAuth = {
      register: jest.fn(),
      login: jest.fn(),
      refresh: jest.fn(),
      logout: jest.fn(),
      forgotPassword: jest.fn(),
    };

    const moduleRef: TestingModule = await Test.createTestingModule({
      controllers: [UserAuthController],
      providers: [{ provide: UserAuthService, useValue: userAuth }],
    })
      // Logout is guarded; the guard has its own spec, so bypass it here.
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .compile();

    controller = moduleRef.get(UserAuthController);
  });

  it('register: forwards the DTO + request context', async () => {
    userAuth.register.mockResolvedValue({ message: 'ok', data: {} });

    await controller.register(
      { email: 'user@example.com', password: 'S3curePass', fullName: 'Jane' },
      '10.0.0.1',
      'jest-agent',
    );

    expect(userAuth.register).toHaveBeenCalledWith(
      { email: 'user@example.com', password: 'S3curePass', fullName: 'Jane' },
      { ipAddress: '10.0.0.1', userAgent: 'jest-agent' },
    );
  });

  it('login: delegates to the service', async () => {
    userAuth.login.mockResolvedValue({ message: 'ok', data: {} });

    await controller.loginUser({ email: 'user@example.com', password: 'x' });

    expect(userAuth.login).toHaveBeenCalledWith({
      email: 'user@example.com',
      password: 'x',
    });
  });

  it('refresh: delegates to the service', async () => {
    userAuth.refresh.mockResolvedValue({ message: 'ok', data: {} });

    await controller.refresh({ refresh_token: 'r' });

    expect(userAuth.refresh).toHaveBeenCalledWith({ refresh_token: 'r' });
  });

  it('logout: extracts the bearer token from the Authorization header', async () => {
    userAuth.logout.mockResolvedValue({
      message: 'ok',
      data: { success: true },
    });

    await controller.logout('Bearer the-access-token');

    expect(userAuth.logout).toHaveBeenCalledWith('the-access-token');
  });

  it('logout: passes undefined when no bearer token is present', async () => {
    userAuth.logout.mockResolvedValue({
      message: 'ok',
      data: { success: true },
    });

    await controller.logout(undefined);

    expect(userAuth.logout).toHaveBeenCalledWith(undefined);
  });

  it('forgot-password: delegates to the service', async () => {
    userAuth.forgotPassword.mockResolvedValue({
      message: 'ok',
      data: { success: true },
    });

    await controller.forgotPassword({ email: 'user@example.com' });

    expect(userAuth.forgotPassword).toHaveBeenCalledWith({
      email: 'user@example.com',
    });
  });
});
