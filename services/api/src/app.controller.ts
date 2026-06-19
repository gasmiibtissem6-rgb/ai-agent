import { Controller, Get } from '@nestjs/common';
import type { AppInfo } from './app.service';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getAppInfo(): AppInfo {
    return this.appService.getAppInfo();
  }
}
