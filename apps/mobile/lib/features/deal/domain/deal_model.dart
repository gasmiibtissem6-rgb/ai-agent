enum DealStatus { draft, sent, negotiating, approved, rejected, finalized }

class Deal {
  final String id;
  final String title;
  final String? description;
  final String createdBy;
  final DealStatus status;
  final DateTime createdAt;
  final DateTime? finalizedAt;
  final List<DealVersion> versions;

  const Deal({
    required this.id,
    required this.title,
    this.description,
    required this.createdBy,
    required this.status,
    required this.createdAt,
    this.finalizedAt,
    this.versions = const [],
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdBy: json['created_by'] as String,
      status: _parseStatus(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      finalizedAt: json['finalized_at'] != null
          ? DateTime.parse(json['finalized_at'] as String)
          : null,
      versions: [],
    );
  }

  static DealStatus _parseStatus(String? status) {
    switch (status) {
      case 'sent':
        return DealStatus.sent;
      case 'negotiating':
        return DealStatus.negotiating;
      case 'approved':
        return DealStatus.approved;
      case 'rejected':
        return DealStatus.rejected;
      case 'finalized':
        return DealStatus.finalized;
      default:
        return DealStatus.draft;
    }
  }

  String get statusLabel {
    switch (status) {
      case DealStatus.draft:
        return 'Draft';
      case DealStatus.sent:
        return 'Sent';
      case DealStatus.negotiating:
        return 'Negotiating';
      case DealStatus.approved:
        return 'Approved';
      case DealStatus.rejected:
        return 'Rejected';
      case DealStatus.finalized:
        return 'Finalized';
    }
  }

  bool get isEditable =>
      status == DealStatus.draft || status == DealStatus.negotiating;

  bool get isFinalized => status == DealStatus.finalized;
}

class DealVersion {
  final String id;
  final String dealId;
  final int versionNumber;
  final String content;
  final String createdBy;
  final bool isFinal;
  final DateTime createdAt;
  final List<String> approvedBy;
  final List<String> rejectedBy;

  const DealVersion({
    required this.id,
    required this.dealId,
    required this.versionNumber,
    required this.content,
    required this.createdBy,
    required this.isFinal,
    required this.createdAt,
    this.approvedBy = const [],
    this.rejectedBy = const [],
  });

  factory DealVersion.fromJson(Map<String, dynamic> json) {
    return DealVersion(
      id: json['id'] as String,
      dealId: json['deal_id'] as String,
      versionNumber: json['version_number'] as int,
      content: json['content'] as String,
      createdBy: json['created_by'] as String,
      isFinal: json['is_final'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      approvedBy: List<String>.from(json['approved_by'] ?? []),
      rejectedBy: List<String>.from(json['rejected_by'] ?? []),
    );
  }
}

class DealApproval {
  final String id;
  final String dealId;
  final String versionId;
  final String userId;
  final String action;
  final String? comment;
  final DateTime createdAt;

  const DealApproval({
    required this.id,
    required this.dealId,
    required this.versionId,
    required this.userId,
    required this.action,
    this.comment,
    required this.createdAt,
  });

  factory DealApproval.fromJson(Map<String, dynamic> json) {
    return DealApproval(
      id: json['id'] as String,
      dealId: json['deal_id'] as String,
      versionId: json['version_id'] as String,
      userId: json['user_id'] as String,
      action: json['action'] as String,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
