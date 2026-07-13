import {
  Controller,
  Post,
  Body,
  Get,
  UseGuards,
  Res,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import {
  ApiOperation,
  ApiOkResponse,
  ApiUnauthorizedResponse,
  ApiBearerAuth,
} from '@nestjs/swagger';
// 1. FIXED: Type-only import to satisfy your strict 'isolatedModules' compiler configuration
import type { Response } from 'express';
import { AuthService } from './auth.service';
import { AdminLoginDto } from './dto/admin-login.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

// 2. FIXED: Put back whatever your original imports were for these two lines:
import { CurrentUser } from './decorators/current-user.decorator';
import type { AuthenticatedUser } from './types/authenticated-user'; // Replace with your original working path if different

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login/admin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Authenticate an administrator and set a secure HttpOnly session cookie.',
  })
  @ApiOkResponse({
    description:
      'Successfully authenticated. Cookie "admin_token" has been set.',
  })
  @ApiUnauthorizedResponse({
    description: 'Invalid administrative credentials.',
  })
  async login(
    @Body() body: AdminLoginDto,
    @Res({ passthrough: true }) response: any,
  ) {
    const result = await this.authService.login(body.email, body.password);

    // 1. Sets the secure cookie automatically for the browser
    response.cookie('admin_token', result.token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      maxAge: 1 * 24 * 60 * 60 * 1000,
      path: '/',
    });

    // 2. 🚀 FIXED: Return the token in the body as well to satisfy the frontend state checks
    return {
      success: true,
      token: result.token,
    };
  }

  @Post('logout/admin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Invalidate the administrator session by clearing the HttpOnly cookie.',
  })
  @ApiOkResponse({ description: 'Session successfully invalidated.' })
  async logout(@Res({ passthrough: true }) response: any) {
    response.clearCookie('admin_token', {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      path: '/',
    });

    return { success: true };
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
