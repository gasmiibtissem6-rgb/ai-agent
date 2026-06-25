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

  factory KycSubmission.fromJson(Map<String, dynamic> json) {
    return KycSubmission(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      documentType: _parseDocumentType(json['document_type'] as String?),
      status: _parseStatus(json['status'] as String?),
      frontUrl: json['front_url'] as String?,
      backUrl: json['back_url'] as String?,
      selfieUrl: json['selfie_url'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
    );
  }

  static KycStatus _parseStatus(String? status) {
    switch (status) {
      case 'pending':
        return KycStatus.pending;
      case 'approved':
        return KycStatus.approved;
      case 'rejected':
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
