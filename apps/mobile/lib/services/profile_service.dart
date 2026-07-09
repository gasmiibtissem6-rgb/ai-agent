import '../core/network/api_client.dart';
import '../features/auth/domain/auth_profile.dart';

/// Profile service — talks to the NestJS `/profile` endpoints, never Supabase.
///
/// Responses use the backend envelope `{ success, message, data, requestId }`
/// and carry the Prisma `Profile` shape (camelCase), the same one [AuthProfile]
/// already parses for `GET /auth/me`.
class ProfileService {
  const ProfileService._();

  static final ApiClient _api = ApiClient.instance;

  /// GET /profile → the caller's profile.
  static Future<AuthProfile> getMyProfile() async {
    final response = await _api.get('/profile');
    return AuthProfile.fromJson(_data(response));
  }

  /// PATCH /profile → updates the caller's own presentation fields.
  ///
  /// `kycStatus`, `isAdmin` and `adminRole` are privilege-bearing and are
  /// rejected by the backend DTO, so they are not exposed here.
  static Future<AuthProfile> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    final response = await _api.patch(
      '/profile',
      data: {'displayName': ?displayName, 'avatarUrl': ?avatarUrl},
    );
    return AuthProfile.fromJson(_data(response));
  }

  static Map<String, dynamic> _data(dynamic response) {
    final body = response as Map;
    return Map<String, dynamic>.from(body['data'] as Map);
  }
}
