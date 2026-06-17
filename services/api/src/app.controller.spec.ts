import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller';
import { AppService } from './app.service';

describe('AppController', () => {
  let appController: AppController;

  beforeEach(async () => {
    const app: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [AppService],
    }).compile();

    appController = app.get<AppController>(AppController);
  });

  describe('root', () => {
    it('returns app information', () => {
      expect(appController.getAppInfo()).toEqual({
        projectName: 'IDEAL',
        status: 'ready',
        serviceName: 'api',
      });
    });
  });

  describe('health', () => {
    it('returns health status', () => {
      expect(appController.getHealth()).toEqual({ status: 'ok' });
    });
  });
});
