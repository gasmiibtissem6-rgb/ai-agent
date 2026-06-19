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
        productSubtitle: 'Trusted Digital Deals and Contracts',
        status: 'ready',
        serviceName: 'api',
        apiVersion: 'v1',
      });
    });
  });
});
