/**
 * Configurable deal-quota settings.
 *
 * The free-plan deal limit is NEVER hardcoded in business logic. It is resolved (in order):
 *   1. From the `Plan` row with code `free` (`monthlyDealLimit`) — admin-configurable at runtime.
 *   2. From the `FREE_PLAN_DEAL_LIMIT` env var — configurable per environment.
 *   3. From `DEFAULT_FREE_PLAN_DEAL_LIMIT` below — last-resort default.
 *
 * A resolved limit of `null` means unlimited.
 */

/** Reserved Plan.code identifying the built-in free tier. */
export const FREE_PLAN_CODE = 'free';

/** Last-resort default when neither a Plan row nor the env var is present. */
const DEFAULT_FREE_PLAN_DEAL_LIMIT = 5;

/** Resolves the free-plan deal limit from the environment, falling back to the default. */
export function getFreePlanDealLimit(): number {
  const raw = process.env.FREE_PLAN_DEAL_LIMIT;
  const parsed = raw ? Number.parseInt(raw, 10) : Number.NaN;
  return Number.isInteger(parsed) && parsed >= 0
    ? parsed
    : DEFAULT_FREE_PLAN_DEAL_LIMIT;
}

/** Public base URL invitation links are built from (Flutter/Next.js render the QR from it). */
export function getInviteBaseUrl(): string {
  const configured = process.env.DEAL_INVITE_BASE_URL?.replace(/\/+$/, '');
  return configured && configured.length > 0
    ? configured
    : 'https://app.ideal.local/deals/invite';
}

/** Permissions an invitation link may grant. Stored on the link and echoed to invitees. */
export const DEAL_INVITE_PERMISSIONS = ['VIEW', 'COMMENT', 'SIGN'] as const;
export type DealInvitePermission = (typeof DEAL_INVITE_PERMISSIONS)[number];
