import { Controller, Post, Get, Body, UseGuards, Request } from '@nestjs/common';
import { AuthService } from './auth.service';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('login/admin')
  async login(@Body() body: any) {
    return this.authService.login(body.email, body.password);
  }

  @Get('profile')
  async getProfile(@Request() req: any) {
    // You will add an AuthGuard here later to protect this route
    return this.authService.getProfile(req.headers.authorization);
  }
}