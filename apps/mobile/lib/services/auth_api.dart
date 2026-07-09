import '../core/network/api_client.dart';
import '../core/network/token_storage.dart';
import '../features/auth/domain/auth_profile.dart';

/// Talks to the NestJS user-auth endpoints (all under the single `/api/v1`
/// base URL configured on [ApiClient]). Every response uses the backend
/// envelope `{ success, message, data, requestId }`; this reads `data`.
///
/// Tokens returned by register/login are persisted to [TokenStorage]; the
/// `ApiClient` interceptor then attaches them to every subsequent request.
class AuthApi {
  const AuthApi._();

  static final ApiClient _api = ApiClient.instance;

  /// POST /auth/register → creates the account and returns a live session.
  static Future<AuthProfile> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _api.post(
      '/auth/register',
      data: {'email': email, 'password': password, 'fullName': fullName},
    );
    final data = _data(response);
    await _saveTokens(data);
    return AuthProfile.fromRegisterUser(data['user'] as Map<String, dynamic>);
  }

  /// POST /auth/login → returns session tokens + the canonical profile.
  static Future<AuthProfile> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = _data(response);
    await _saveTokens(data);
    return AuthProfile.fromJson(data['profile'] as Map<String, dynamic>);
  }

  /// GET /auth/me → resolves the current profile from the stored token.
  /// Used to restore the session on cold start.
  static Future<AuthProfile> me() async {
    final response = await _api.get('/auth/me');
    return AuthProfile.fromJson(_data(response));
  }

  /// POST /auth/forgot-password → always a generic success server-side.
  static Future<void> forgotPassword(String email) async {
    await _api.post('/auth/forgot-password', data: {'email': email});
  }

  /// POST /auth/logout → best-effort server-side sign-out. Never throws.
  static Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {
      // Logout is idempotent; the client clears its tokens regardless.
    }
  }

  static Map<String, dynamic> _data(dynamic envelope) {
    final map = envelope as Map<String, dynamic>;
    return map['data'] as Map<String, dynamic>;
  }

  static Future<void> _saveTokens(Map<String, dynamic> data) async {
    final accessToken = data['access_token'] as String?;
    final refreshToken = data['refresh_token'] as String?;
    if (accessToken != null) {
      await TokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }
  }
}
