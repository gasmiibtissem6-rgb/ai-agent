/// Canonical user profile returned by the NestJS backend.
///
/// Shape mirrors the Prisma `Profile` serialized by NestJS (camelCase),
/// as returned by POST /auth/login (`data.profile`) and GET /auth/me.
/// This replaces the previous Supabase `User` object in the auth state.
class AuthProfile {
  final String id;
  final String email;
  final String? displayName;
  final String? username;
  final String? avatarUrl;
  final String kycStatus;
  final bool isPublic;
  final bool isAdmin;
  final String? adminRole;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AuthProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.username,
    this.avatarUrl,
    this.kycStatus = 'NOT_STARTED',
    this.isPublic = false,
    this.isAdmin = false,
    this.adminRole,
    this.createdAt,
    this.updatedAt,
  });

  /// Parses the full profile (login `data.profile` / GET /auth/me `data`).
  factory AuthProfile.fromJson(Map<String, dynamic> json) {
    return AuthProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      kycStatus: json['kycStatus'] as String? ?? 'NOT_STARTED',
      isPublic: json['isPublic'] as bool? ?? false,
      isAdmin: json['isAdmin'] as bool? ?? false,
      adminRole: json['adminRole'] as String?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  /// Builds a profile from register's lighter `data.user` block
  /// (`{ id, email, fullName }`).
  factory AuthProfile.fromRegisterUser(Map<String, dynamic> user) {
    return AuthProfile(
      id: user['id'] as String,
      email: user['email'] as String,
      displayName: user['fullName'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// Best display label: name if present, else the email's local part.
  String get displayNameOrEmail {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return email.split('@').first;
  }

  /// An account is "verified" once its KYC has been approved.
  bool get isKycVerified => kycStatus.toUpperCase() == 'APPROVED';

  /// Emoji surfaced next to the name to signal verification at a glance.
  String get verifiedEmoji => isKycVerified ? '✅' : '⚠️';

  /// The scannable payload encoded in this profile's QR code. Uses the
  /// `ideal://profile/...` scheme so a scan can resolve it to a profile.
  String get qrPayload {
    final handle = username?.trim();
    if (handle != null && handle.isNotEmpty) {
      return 'ideal://profile/$handle';
    }
    return 'ideal://profile/id/$id';
  }

  /// "@username" when set, otherwise the display name / email fallback.
  String get handleOrName {
    final handle = username?.trim();
    if (handle != null && handle.isNotEmpty) return '@$handle';
    return displayNameOrEmail;
  }
}
