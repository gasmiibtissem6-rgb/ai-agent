import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Request } from 'express';
import { AuthService } from '../auth.service';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';
import { AuthenticatedUser } from '../types/authenticated-user';

/**
 * Unified authentication guard. Validates an incoming token that may reside
 * in an HttpOnly cookie (admin dashboard) OR a traditional Bearer token header
 * (Flutter mobile), delegating to {@link AuthService.verifyToken}. On success it
 * attaches a normalized {@link AuthenticatedUser} to `request.user`.
 *
 * Routes annotated with `@Public()` bypass validation.
 */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly authService: AuthService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) {
      return true;
    }

    const request = context
      .switchToHttp()
      .getRequest<
        Request & { user?: AuthenticatedUser; cookies?: Record<string, string> }
      >();

    // Extract token checking both Cookie vectors and Header fallbacks
    const token = this.extractToken(request);

    if (!token) {
      throw new UnauthorizedException('Authentication token is missing.');
    }

    request.user = await this.authService.verifyToken(token);
    return true;
  }

  private extractToken(request: any): string | undefined {
    // 1. Check if the token exists inside the secure HttpOnly cookie wrapper first (Admin dashboard client)
    if (request.cookies && request.cookies['admin_token']) {
      return request.cookies['admin_token'];
    }

    // 2. Fallback: Parse the authorization header (Flutter mobile app client)
    const [type, token] = request.headers.authorization?.split(' ') ?? [];
    return type === 'Bearer' ? token : undefined;
  }
}
