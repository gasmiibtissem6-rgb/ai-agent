// services/api/src/common/cors.ts

/**
 * Development only: `NODE_ENV` must say so explicitly. An unset NODE_ENV is
 * NOT treated as development here — a deploy that forgets the variable must
 * fall back to the strict allowlist, never to a loosened CORS policy.
 */
export const isExplicitDevelopment = (): boolean =>
  process.env.NODE_ENV === 'development';

const LOOPBACK_HOSTNAMES = new Set(['localhost', '127.0.0.1', '::1']);

/**
 * True for `http://localhost:<port>` and its loopback equivalents.
 *
 * Parsed with the URL API rather than matched with a regex, so lookalikes such
 * as `http://localhost.attacker.com` or `http://127.0.0.1.attacker.com` do not
 * pass: only the exact hostname counts. HTTPS is excluded because a loopback
 * dev server is plain HTTP; a real origin belongs in ALLOWED_ORIGINS.
 */
export function isLoopbackOrigin(origin: string): boolean {
  try {
    const url = new URL(origin);
    if (url.protocol !== 'http:') return false;
    // The URL parser keeps IPv6 hosts bracketed (`[::1]`); strip the brackets.
    const hostname = url.hostname.replace(/^\[|\]$/g, '');
    return LOOPBACK_HOSTNAMES.has(hostname);
  } catch {
    return false;
  }
}

/**
 * Decides whether a browser origin may call the API.
 *
 * `allowAnyLoopback` is passed in rather than read from the environment so the
 * caller resolves the mode once at bootstrap, and so this stays a pure function.
 */
export function isOriginAllowed(
  origin: string,
  allowedOrigins: readonly string[],
  allowAnyLoopback: boolean,
): boolean {
  if (allowedOrigins.includes(origin)) return true;
  return allowAnyLoopback && isLoopbackOrigin(origin);
}
