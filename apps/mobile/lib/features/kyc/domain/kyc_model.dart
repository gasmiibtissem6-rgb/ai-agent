enum KycStatus { notSubmitted, pending, approved, rejected }

enum KycDocumentType { nationalId, passport, driverLicense }

class KycSubmission {
  final String? id;
  final String userId;
  final KycDocumentType documentType;
  final KycStatus status;
  final String? frontUrl;
  final String? backUrl;
  final String? selfieUrl;
  final String? rejectionReason;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  const KycSubmission({
    this.id,
    required this.userId,
    required this.documentType,
    required this.status,
    this.frontUrl,
    this.backUrl,
    this.selfieUrl,
    this.rejectionReason,
    this.createdAt,
    this.reviewedAt,
  });

  /// Parses GET /kyc/me/status (`{ status, submittedAt, reviewedAt,
  /// rejectionReason }`). The status endpoint does not echo document paths.
  factory KycSubmission.fromStatus(Map<String, dynamic> json) {
    return KycSubmission(
      userId: '',
      documentType: KycDocumentType.nationalId,
      status: statusFromWire(json['status'] as String?),
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: _parseDate(json['submittedAt']),
      reviewedAt: _parseDate(json['reviewedAt']),
    );
  }

  /// Parses the KycSubmission row returned by POST /kyc/submit.
  factory KycSubmission.fromSubmitResponse(Map<String, dynamic> json) {
    return KycSubmission(
      id: json['id'] as String?,
      userId: json['profileId'] as String? ?? '',
      documentType: _parseDocumentType(json['documentType'] as String?),
      status: statusFromWire(json['status'] as String?),
      rejectionReason: json['rejectionReason'] as String?,
      createdAt: _parseDate(json['submittedAt'] ?? json['createdAt']),
      reviewedAt: _parseDate(json['reviewedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) =>
      value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;

  /// Maps the backend `KycStatus` enum onto the app's coarse status.
  static KycStatus statusFromWire(String? status) {
    switch (status) {
      case 'SUBMITTED':
      case 'UNDER_REVIEW':
        return KycStatus.pending;
      case 'APPROVED':
        return KycStatus.approved;
      case 'REJECTED':
      case 'RESUBMISSION_REQUIRED':
        return KycStatus.rejected;
      default:
        return KycStatus.notSubmitted;
    }
  }

  static KycDocumentType _parseDocumentType(String? type) {
    switch (type) {
      case 'passport':
        return KycDocumentType.passport;
      case 'driver_license':
        return KycDocumentType.driverLicense;
      default:
        return KycDocumentType.nationalId;
    }
  }

  String get statusLabel {
    switch (status) {
      case KycStatus.notSubmitted:
        return 'Not submitted';
      case KycStatus.pending:
        return 'Under review';
      case KycStatus.approved:
        return 'Verified';
      case KycStatus.rejected:
        return 'Rejected';
    }
  }

  String get documentTypeLabel {
    switch (documentType) {
      case KycDocumentType.nationalId:
        return 'National ID';
      case KycDocumentType.passport:
        return 'Passport';
      case KycDocumentType.driverLicense:
        return 'Driver License';
    }
  }
}
