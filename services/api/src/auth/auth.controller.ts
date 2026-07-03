import { Controller, Post, Get, Body, UseGuards } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { AdminLoginDto } from './dto/admin-login.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { CurrentUser } from './decorators/current-user.decorator';
import type { AuthenticatedUser } from './types/authenticated-user';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('login/admin')
  @ApiOperation({
    summary: 'Authenticate an administrator and return a token.',
  })
  @ApiOkResponse({ description: 'Returns a bearer token for the admin.' })
  @ApiUnauthorizedResponse({
    description: 'Invalid administrative credentials.',
  })
  async login(@Body() body: AdminLoginDto) {
    return this.authService.login(body.email, body.password);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Return the authenticated user profile.',
    description:
      'Works for both Supabase (mobile) and NestJS (admin) tokens — the guard ' +
      'validates either and resolves the Prisma profile.',
  })
  @ApiOkResponse({ description: 'The authenticated profile.' })
  @ApiUnauthorizedResponse({
    description: 'Missing, invalid or expired token.',
  })
  async getMe(@CurrentUser() user: AuthenticatedUser) {
    return this.authService.getMe(user);
  }

  @Get('profile')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary:
      'Return the authenticated user profile (legacy alias of /auth/me).',
    deprecated: true,
  })
  async getProfile(@CurrentUser() user: AuthenticatedUser) {
    return this.authService.getMe(user);
  }
}
