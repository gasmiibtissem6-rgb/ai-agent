import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AdminRole } from '@prisma/client';
import { ROLES_KEY } from '../decorators/roles.decorator';
import { AuthenticatedUser } from '../types/authenticated-user';

/**
 * Authorization guard for the `@Roles()` decorator. Must run AFTER
 * {@link JwtAuthGuard} (which populates `request.user`).
 *
 * Semantics:
 *  - No `@Roles()` on the route        → no role requirement (auth only).
 *  - `@Roles()` with no arguments      → any admin (isAdmin === true).
 *  - `@Roles(AdminRole.ADMIN, ...)`    → admin whose adminRole is in the list.
 *
 * A normal (non-admin) user is always rejected when `@Roles()` is present,
 * which is what keeps KYC review and other admin routes off-limits to users.
 */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<
      AdminRole[] | undefined
    >(ROLES_KEY, [context.getHandler(), context.getClass()]);

    // No @Roles() decorator → this guard imposes no restriction.
    if (requiredRoles === undefined) {
      return true;
    }

    const request = context
      .switchToHttp()
      .getRequest<{ user?: AuthenticatedUser }>();
    const user = request.user;

    if (!user) {
      throw new UnauthorizedException(
        'Authentication context missing. Ensure JwtAuthGuard runs first.',
      );
    }

    if (!user.isAdmin) {
      throw new ForbiddenException(
        'Access denied. Administrator privileges required.',
      );
    }

    // @Roles() with no specific role → any admin is allowed.
    if (requiredRoles.length === 0) {
      return true;
    }

    if (!user.adminRole || !requiredRoles.includes(user.adminRole)) {
      throw new ForbiddenException(
        'Access denied. Insufficient administrator role.',
      );
    }

    return true;
  }
}
