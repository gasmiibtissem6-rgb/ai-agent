import { Controller, Get, UseGuards } from '@nestjs/common';
import type { AppInfo } from './app.service';
import { AppService } from './app.service';
import { JwtAuthGuard } from './auth/guards/jwt-auth.guard';
import { CurrentUser } from './auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from './auth/types/authenticated-user';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getAppInfo(): AppInfo {
    return this.appService.getAppInfo();
  }

  @Get('secure')
  @UseGuards(JwtAuthGuard)
  getSecureData(@CurrentUser() user: AuthenticatedUser) {
    return {
      message: 'If you see this, your JwtAuthGuard successfully verified the token!',
      userPayload: user,
    };
  }
}
