// services/api/src/profiles/profiles.controller.ts
import { Controller, Get, UseGuards, Req } from '@nestjs/common';
import { AuthGuard } from '../common/guards/auth.guard';
import { ProfilesService } from './profiles.service';

@Controller()
@UseGuards(AuthGuard)
export class ProfilesController {
  constructor(private readonly profilesService: ProfilesService) {}

  @Get('auth/session')
  async getSession(@Req() req: any) {
    return this.profilesService.getSessionMetadata(req.user);
  }

  @Get('profile')
  async getProfile(@Req() req: any) {
    return this.profilesService.getProfileByUserId(req.user.sub);
  }
}