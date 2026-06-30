import { SetMetadata } from '@nestjs/common';
import { AdminRole } from '@prisma/client';

export const ROLES_KEY = 'roles';

/**
 * Restrict a route to administrators. Must be combined with `RolesGuard`
 * (and `JwtAuthGuard` to populate the user).
 *
 * - `@Roles()`            → any authenticated admin (Profile.isAdmin === true).
 * - `@Roles(AdminRole.SUPER_ADMIN, AdminRole.ADMIN)` → admin whose adminRole is
 *   one of the listed values.
 *
 * Routes WITHOUT this decorator impose no role requirement (authentication only).
 */
export const Roles = (...roles: AdminRole[]) => SetMetadata(ROLES_KEY, roles);
