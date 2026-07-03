import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'isPublic';

/**
 * Marks a route as public so `JwtAuthGuard` skips token validation.
 * Useful for webhooks and unauthenticated endpoints when the guard is applied
 * at controller (or global) scope.
 */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
