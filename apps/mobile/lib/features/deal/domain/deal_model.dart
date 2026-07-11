/// Mirrors the Postgres `deal_status` enum exactly (Prisma `DealStatus`).
///
/// `negotiation` is the wire value; the product surfaces it as **Bridged**.
/// Keeping the wire value canonical means the admin dashboard, the audit trail
/// and this app all agree on what is stored.
enum DealStatus {
  draft,
  negotiation,
  pendingApproval,
  approved,
  locked,
  changesRequested,
  rejected,
  cancelled,
  archived,
}

/// The kind of content a deal carries. Persisted in `deals.deal_type` (TEXT).
enum DealContentType { document, video, scanned }

extension DealContentTypeX on DealContentType {
  String get wireValue => switch (this) {
    DealContentType.document => 'document',
    DealContentType.video => 'video',
    DealContentType.scanned => 'scanned',
  };

  String get label => switch (this) {
    DealContentType.document => 'Document',
    DealContentType.video => 'Video',
    DealContentType.scanned => 'Scanned document',
  };

  String get description => switch (this) {
    DealContentType.document => 'A written agreement drafted in the app.',
    DealContentType.video => 'A recorded video agreement or walkthrough.',
    DealContentType.scanned => 'A photo or scan, read with OCR.',
  };

  static DealContentType? fromWire(String? value) => switch (value) {
    'document' => DealContentType.document,
    'video' => DealContentType.video,
    'scanned' => DealContentType.scanned,
    _ => null,
  };
}

extension DealStatusX on DealStatus {
  String get wireValue => switch (this) {
    DealStatus.draft => 'DRAFT',
    DealStatus.negotiation => 'NEGOTIATION',
    DealStatus.pendingApproval => 'PENDING_APPROVAL',
    DealStatus.approved => 'APPROVED',
    DealStatus.locked => 'LOCKED',
    DealStatus.changesRequested => 'CHANGES_REQUESTED',
    DealStatus.rejected => 'REJECTED',
    DealStatus.cancelled => 'CANCELLED',
    DealStatus.archived => 'ARCHIVED',
  };

  /// User-facing label. NEGOTIATION reads as "Bridged" throughout the app.
  String get label => switch (this) {
    DealStatus.draft => 'Draft',
    DealStatus.negotiation => 'Bridged',
    DealStatus.pendingApproval => 'Pending approval',
    DealStatus.approved => 'Approved',
    DealStatus.locked => 'Locked',
    DealStatus.changesRequested => 'Changes requested',
    DealStatus.rejected => 'Rejected',
    DealStatus.cancelled => 'Cancelled',
    DealStatus.archived => 'Archived',
  };

  static DealStatus fromWire(String? value) => switch (value) {
    'NEGOTIATION' => DealStatus.negotiation,
    'PENDING_APPROVAL' => DealStatus.pendingApproval,
    'APPROVED' => DealStatus.approved,
    'LOCKED' => DealStatus.locked,
    'CHANGES_REQUESTED' => DealStatus.changesRequested,
    'REJECTED' => DealStatus.rejected,
    'CANCELLED' => DealStatus.cancelled,
    'ARCHIVED' => DealStatus.archived,
    _ => DealStatus.draft,
  };
}

/// The statuses a deal creator may set on their own deal.
/// Mirrors `CREATOR_SETTABLE_STATUSES` in the NestJS `UpdateDealStatusDto`.
const kCreatorSettableStatuses = <DealStatus>[
  DealStatus.approved,
  DealStatus.negotiation,
  DealStatus.cancelled,
];

/// Categories shared by the deal form and the template form.
const kDealCategories = <String>[
  'Partnership',
  'Investment',
  'Service',
  'Supply',
  'License',
];

/// Participant roles shared by the deal form and the template form.
const kDealRoles = <String>[
  'Owner',
  'Partner',
  'Investor',
  'Supplier',
  'Client',
];

class Deal {
  final String id;
  final String creatorProfileId;
  final String title;
  final String? description;
  final DealContentType? contentType;
  final DealStatus status;
  final String? currentVersionId;
  final String? lockedVersionId;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final DateTime? archivedAt;
  final List<DealVersion> versions;
  final List<DealPartyInfo> parties;

  const Deal({
    required this.id,
    required this.creatorProfileId,
    required this.title,
    this.description,
    this.contentType,
    required this.status,
    this.currentVersionId,
    this.lockedVersionId,
    required this.createdAt,
    this.cancelledAt,
    this.archivedAt,
    this.versions = const [],
    this.parties = const [],
  });

  /// Parses the NestJS/Prisma shape (camelCase, uppercase status enum).
  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      id: json['id'] as String,
      creatorProfileId: json['creatorProfileId'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String?,
      contentType: DealContentTypeX.fromWire(json['dealType'] as String?),
      status: DealStatusX.fromWire(json['status'] as String?),
      currentVersionId: json['currentVersionId'] as String?,
      lockedVersionId: json['lockedVersionId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      cancelledAt: _parseDate(json['cancelledAt']),
      archivedAt: _parseDate(json['archivedAt']),
      versions: (json['versions'] as List? ?? const [])
          .map((e) => DealVersion.fromJson(e as Map<String, dynamic>))
          .toList(),
      parties: (json['parties'] as List? ?? const [])
          .map((e) => DealPartyInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static DateTime? _parseDate(dynamic value) =>
      value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;

  String get statusLabel => status.label;

  /// Human-friendly auto-generated reference derived from the deal id, e.g.
  /// `DEAL-1A2B3C4D`. Stable for the life of the deal.
  String get reference =>
      'DEAL-${id.replaceAll('-', '').substring(0, 8).toUpperCase()}';

  /// Only a DRAFT deal can have its fields edited (matches DealsService).
  bool get isEditable => status == DealStatus.draft;

  /// LOCKED and ARCHIVED deals can never transition again.
  bool get isTerminal =>
      status == DealStatus.locked || status == DealStatus.archived;

  bool get isLocked => status == DealStatus.locked;

  /// Whether [profileId] owns this deal and may therefore change its status.
  bool isCreatedBy(String? profileId) =>
      profileId != null && profileId == creatorProfileId;

  /// The party row belonging to [profileId], if the caller is a participant.
  DealPartyInfo? partyFor(String? profileId) {
    if (profileId == null) return null;
    for (final party in parties) {
      if (party.profileId == profileId) return party;
    }
    return null;
  }

  /// True once at least one invited party has accepted (chat can open).
  bool get hasAcceptedParty =>
      parties.any((p) => p.partyStatus == 'ACCEPTED');
}

/// A participant on a deal, as returned by the backend (`DealParty`).
class DealPartyInfo {
  final String id;
  final String? profileId;
  final String email;
  final String role;

  /// Wire value of the Postgres `party_status` enum: INVITED, ACCEPTED,
  /// DECLINED, REMOVED, EXPIRED, REVOKED.
  final String partyStatus;
  final bool requiredApproval;

  const DealPartyInfo({
    required this.id,
    this.profileId,
    required this.email,
    required this.role,
    required this.partyStatus,
    required this.requiredApproval,
  });

  factory DealPartyInfo.fromJson(Map<String, dynamic> json) {
    return DealPartyInfo(
      id: json['id'] as String,
      profileId: json['profileId'] as String?,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'PARTICIPANT',
      partyStatus: json['partyStatus'] as String? ?? 'INVITED',
      requiredApproval: json['requiredApproval'] as bool? ?? true,
    );
  }

  bool get isAccepted => partyStatus == 'ACCEPTED';
  bool get isInvited => partyStatus == 'INVITED';
  bool get isDeclined => partyStatus == 'DECLINED';
}

class DealVersion {
  final String id;
  final String dealId;
  final int versionNumber;
  final DealStatus status;
  final String title;
  final Map<String, dynamic> terms;
  final String? summary;
  final DateTime? lockedAt;
  final String createdByProfileId;
  final DateTime createdAt;

  const DealVersion({
    required this.id,
    required this.dealId,
    required this.versionNumber,
    required this.status,
    required this.title,
    required this.terms,
    this.summary,
    this.lockedAt,
    required this.createdByProfileId,
    required this.createdAt,
  });

  factory DealVersion.fromJson(Map<String, dynamic> json) {
    return DealVersion(
      id: json['id'] as String,
      dealId: json['dealId'] as String,
      versionNumber: json['versionNumber'] as int,
      status: DealStatusX.fromWire(json['status'] as String?),
      title: json['title'] as String? ?? '',
      terms: Map<String, dynamic>.from(
        json['termsJson'] as Map? ?? const <String, dynamic>{},
      ),
      summary: json['summary'] as String?,
      lockedAt: Deal._parseDate(json['lockedAt']),
      createdByProfileId: json['createdByProfileId'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  bool get isFinal => lockedAt != null;

  /// The rendered document body stored alongside the structured terms.
  String get document => terms['document'] as String? ?? '';
}
