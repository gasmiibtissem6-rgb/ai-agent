import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { JwtAuthGuard } from './auth/guards/jwt-auth.guard';

describe('AppController', () => {
  let appController: AppController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [AppService],
    })
      // AppController references JwtAuthGuard; stub it so DI doesn't pull AuthService.
      .overrideGuard(JwtAuthGuard)
      .useValue({ canActivate: () => true })
      .compile();

    appController = app.get<AppController>(AppController);
  });

  describe('root', () => {
    it('returns app information', () => {
      expect(appController.getAppInfo()).toEqual({
        projectName: 'IDEAL',
        productSubtitle: 'Trusted Digital Deals and Contracts',
        status: 'ready',
        serviceName: 'api',
        apiVersion: 'v1',
      });
    });
  });
});
