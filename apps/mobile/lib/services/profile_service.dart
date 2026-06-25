import '../core/network/api_client.dart';
import '../features/profile/domain/profile_model.dart';

/// Profile service communicates with the NestJS backend API.
/// It never calls Supabase directly.
class ProfileService {
  const ProfileService._();

  static final _api = ApiClient.instance;

  static Future<ProfileModel> getMyProfile() async {
    return await _api.get<ProfileModel>(
      '/profile/me',
      fromJson: (data) => ProfileModel.fromJson(data as Map<String, dynamic>),
    );
  }

  static Future<ProfileModel> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{};

    if (fullName != null) data['full_name'] = fullName;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;

    return await _api.patch<ProfileModel>(
      '/profile/me',
      data: data,
      fromJson: (data) => ProfileModel.fromJson(data as Map<String, dynamic>),
    );
  }
}
