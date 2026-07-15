import {
  Body,
  Controller,
  Headers,
  HttpCode,
  HttpStatus,
  Ip,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { Public } from './decorators/public.decorator';
import { UserAuthService } from './user-auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';

/**
 * End-user authentication surface (Supabase-backed), ADDED alongside the
 * existing admin flow. The admin route (POST /auth/login/admin), JwtAuthGuard,
 * RolesGuard and GET /auth/me live in {@link AuthController}/{@link AuthService}
 * and are intentionally left untouched.
 */
@ApiTags('auth')
@Controller('auth')
export class UserAuthController {
  constructor(private readonly userAuth: UserAuthService) {}

  @Post('register')
  @Public()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Register a new end-user via Supabase and return a live session.',
  })
  @ApiResponse({ status: 201, description: 'User created; tokens returned.' })
  @ApiResponse({ status: 409, description: 'Email already registered.' })
  @ApiResponse({
    status: 400,
    description: 'Validation or weak-password error.',
  })
  register(
    @Body() dto: RegisterDto,
    @Ip() ipAddress: string,
    @Headers('user-agent') userAgent: string,
  ) {
    return this.userAuth.register(dto, { ipAddress, userAgent });
  }

  @Post('login')
  @Public()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Authenticate an end-user; returns tokens and the canonical profile.',
  })
  @ApiResponse({ status: 200, description: 'Authenticated; tokens + profile.' })
  @ApiResponse({ status: 401, description: 'Invalid credentials.' })
  loginUser(@Body() dto: LoginDto) {
    return this.userAuth.login(dto);
  }

  @Post('refresh')
  @Public()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Exchange a refresh token for a new session.' })
  @ApiResponse({ status: 200, description: 'New tokens returned.' })
  @ApiResponse({
    status: 401,
    description: 'Invalid or expired refresh token.',
  })
  refresh(@Body() dto: RefreshTokenDto) {
    return this.userAuth.refresh(dto);
  }

  @Post('logout')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Sign the current user out server-side.' })
  @ApiResponse({ status: 200, description: 'Logged out.' })
  @ApiResponse({ status: 401, description: 'Missing or invalid token.' })
  logout(@Headers('authorization') authorization?: string) {
    const token = authorization?.startsWith('Bearer ')
      ? authorization.slice('Bearer '.length).trim()
      : undefined;
    return this.userAuth.logout(token);
  }

  @Post('forgot-password')
  @Public()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Trigger a password-reset email (always a generic response).',
  })
  @ApiResponse({
    status: 200,
    description: 'Generic success (account existence is never revealed).',
  })
  forgotPassword(@Body() dto: ForgotPasswordDto) {
    return this.userAuth.forgotPassword(dto);
  }
}
