import { Controller, Get, Req, UseGuards } from '@nestjs/common';
import type { Request } from 'express';
import type { AppInfo } from './app.service';
import { AppService } from './app.service';
import { AuthGuard } from './common/guards/auth.guard';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getAppInfo(): AppInfo {
    return this.appService.getAppInfo();
  }

  @Get('secure')
  @UseGuards(AuthGuard)
  getSecureData(@Req() req: any) {
    return {
      message: 'If you see this, your AuthGuard successfully verified the token!',
      userPayload: (req as Request & { user?: unknown }).user,
    };
  }
}
