import '../core/network/api_client.dart';
import '../core/network/token_storage.dart';
import '../features/auth/domain/auth_profile.dart';

class AuthApi {
  const AuthApi._();

  static final ApiClient _api = ApiClient.instance;

  /// POST /auth/register
  static Future<AuthProfile> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _api.post(
      'auth/register',
      data: {
        'email': email,
        'password': password,
        'fullName': fullName,
      },
    );

    final data = _data(response);
    await _saveTokens(data);

    return AuthProfile.fromRegisterUser(
      data['user'] as Map<String, dynamic>,
    );
  }

  /// POST /auth/login
  static Future<AuthProfile> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      'auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = _data(response);
    await _saveTokens(data);

    return AuthProfile.fromJson(
      data['profile'] as Map<String, dynamic>,
    );
  }

  /// GET /auth/me
  static Future<AuthProfile> me() async {
    final response = await _api.get('/auth/me');

    return AuthProfile.fromJson(
      _data(response),
    );
  }

  /// PATCH /profile
  static Future<AuthProfile> updateProfile({
    String? displayName,
    String? username,
    String? avatarUrl,
    bool? isPublic,
  }) async {
    final data = <String, dynamic>{};

    if (displayName != null) {
      data['displayName'] = displayName;
    }

    if (username != null) {
      data['username'] = username;
    }

    if (avatarUrl != null) {
      data['avatarUrl'] = avatarUrl;
    }

    if (isPublic != null) {
      data['isPublic'] = isPublic;
    }

    final response = await _api.patch(
      '/profile',
      data: data,
    );

    return AuthProfile.fromJson(
      _data(response),
    );
  }

  /// POST /auth/forgot-password
  static Future<void> forgotPassword(String email) async {
    await _api.post(
      '/auth/forgot-password',
      data: {'email': email},
    );
  }

  /// POST /auth/logout
  static Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {
      // Tokens are cleared locally even if backend logout fails.
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
