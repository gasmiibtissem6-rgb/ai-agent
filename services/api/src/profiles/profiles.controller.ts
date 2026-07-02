// services/api/src/profiles/profiles.controller.ts
import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../auth/types/authenticated-user';
import { ProfilesService } from './profiles.service';

@ApiTags('profiles')
@ApiBearerAuth()
@Controller() // Keeping this empty allows the routes below to mount cleanly from root or /api global prefix
@UseGuards(JwtAuthGuard)
export class ProfilesController {
  constructor(private readonly profilesService: ProfilesService) {}

  @Get('auth/session')
  async getSession(@CurrentUser() user: AuthenticatedUser) {
    return this.profilesService.getSessionMetadata(user);
  }

  @Get('profile')
  async getProfile(@CurrentUser('sub') sub: string) {
    return this.profilesService.getProfileByUserId(sub);
  }
}
