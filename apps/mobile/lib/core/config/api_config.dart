import '../constants/env.dart';

/// Single source of truth for the NestJS API base URL.
///
/// Delegates to [Env.apiBaseUrl] (loaded from `.env` / `.env.example`, which
/// must already include the `/api/v1` prefix) so the whole app — the
/// interceptor-equipped [ApiClient] and the legacy chat/documents callers —
/// resolves the same backend origin.
class ApiConfig {
  const ApiConfig._();

  static String get baseUrl => Env.apiBaseUrl;
}
