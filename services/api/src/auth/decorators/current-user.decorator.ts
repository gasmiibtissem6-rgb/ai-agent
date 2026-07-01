import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { AuthenticatedUser } from '../types/authenticated-user';

/**
 * Injects the normalized `AuthenticatedUser` (set by JwtAuthGuard) into a
 * handler parameter, optionally selecting a single property.
 *
 * @example
 *   getMe(@CurrentUser() user: AuthenticatedUser) { ... }
 *   getMe(@CurrentUser('profileId') profileId: string) { ... }
 */
export const CurrentUser = createParamDecorator(
  (
    data: keyof AuthenticatedUser | undefined,
    ctx: ExecutionContext,
  ): AuthenticatedUser | AuthenticatedUser[keyof AuthenticatedUser] => {
    const request = ctx
      .switchToHttp()
      .getRequest<{ user: AuthenticatedUser }>();
    const user = request.user;
    return data ? user?.[data] : user;
  },
);
