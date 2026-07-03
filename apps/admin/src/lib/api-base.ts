const DEFAULT_API_BASE_URL = 'http://localhost:3001/api/v1';

function stripTrailingSlashes(value: string): string {
  return value.replace(/\/+$/, '');
}

export function getApiBaseUrl(rawValue?: string | null): string {
  const input = (rawValue ?? '').trim();
  const base = stripTrailingSlashes(input.length > 0 ? input : DEFAULT_API_BASE_URL);

  // Backward compatibility: if env still points to /api, upgrade it to /api/v1.
  if (base.endsWith('/api')) {
    return `${base}/v1`;
  }

  return base;
}
