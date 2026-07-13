import '../core/network/api_client.dart';
import '../features/deal/domain/deal_model.dart';

/// Deal Service — talks to the NestJS `/deals` endpoints.
///
/// Deals are never written through Supabase directly: RLS deliberately grants
/// the client SELECT only, and NestJS owns authorization, status transitions
/// and the audit trail. Every response uses the backend envelope
/// `{ success, message, data, requestId }`; this reads `data`.
class DealService {
  const DealService._();

  static final ApiClient _api = ApiClient.instance;

  /// GET /deals → deals where the caller is creator or participant.
  static Future<List<Deal>> getMyDeals({int limit = 100}) async {
    final response = await _api.get('/deals', queryParams: {'limit': limit});
    final items = _data(response)['items'] as List? ?? const [];
    return items
        .map((json) => Deal.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// GET /deals/:id → full detail, including versions and parties.
  static Future<Deal> getDeal(String dealId) async {
    final response = await _api.get('/deals/$dealId');
    return Deal.fromJson(_data(response));
  }

  /// POST /deals → creates the deal and its initial draft version.
  ///
  /// Requires an approved KYC (`KycVerifiedGuard` on the endpoint).
  static Future<Deal> createDeal({
    required String title,
    required String description,
    required Map<String, dynamic> terms,
    DealContentType? contentType,
    List<DealPartyInput> parties = const [],
  }) async {
    final response = await _api.post(
      '/deals',
      data: {
        'title': title,
        if (description.isNotEmpty) 'description': description,
        if (contentType != null) 'dealType': contentType.wireValue,
        'terms': terms,
        if (parties.isNotEmpty)
          'parties': parties.map((p) => p.toJson()).toList(),
      },
    );
    return Deal.fromJson(_data(response));
  }

  /// POST /deals/:id/share → generates an invitation link + QR payload.
  /// Grants VIEW + SIGN so whoever accepts becomes a required approver.
  static Future<DealShareLink> shareDeal(String dealId) async {
    final response = await _api.post(
      '/deals/$dealId/share',
      data: {
        'permissions': ['VIEW', 'SIGN'],
        'expiresInHours': 168,
      },
    );
    return DealShareLink.fromJson(_data(response));
  }

  /// POST /deals/:id/parties → attach a counterparty by username or email.
  static Future<Deal> addParty({
    required String dealId,
    required String identifier,
    String? role,
  }) async {
    final response = await _api.post(
      '/deals/$dealId/parties',
      data: {'identifier': identifier, 'role': ?role},
    );
    return Deal.fromJson(_data(response));
  }

  /// POST /deals/:id/respond → invited party accepts or refuses the deal.
  static Future<Deal> respondToDeal({
    required String dealId,
    required bool accept,
  }) async {
    final response = await _api.post(
      '/deals/$dealId/respond',
      data: {'accept': accept},
    );
    return Deal.fromJson(_data(response));
  }

  /// POST /deals/:id/versions/:versionId/submit → creator submits a version
  /// for the accepted parties to approve.
  static Future<Deal> submitVersion({
    required String dealId,
    required String versionId,
  }) async {
    final response = await _api.post(
      '/deals/$dealId/versions/$versionId/submit',
    );
    return Deal.fromJson(_data(response));
  }

  /// POST /deals/:id/versions/:versionId/decide → a required party approves or
  /// rejects. When both parties approve, the version locks and the deal is
  /// approved.
  static Future<Deal> decideVersion({
    required String dealId,
    required String versionId,
    required bool approve,
    String? reason,
  }) async {
    final response = await _api.post(
      '/deals/$dealId/versions/$versionId/decide',
      data: {
        'approve': approve,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return Deal.fromJson(_data(response));
  }

  /// POST /deals/:id/versions → new version (creator only, not approved/locked).
  static Future<DealVersion> createVersion({
    required String dealId,
    required Map<String, dynamic> terms,
    String? title,
    String? summary,
  }) async {
    final response = await _api.post(
      '/deals/$dealId/versions',
      data: {'terms': terms, 'title': ?title, 'summary': ?summary},
    );
    return DealVersion.fromJson(_data(response));
  }

  /// Versions come embedded in GET /deals/:id — there is no standalone
  /// versions endpoint (the deal-versions module is still a stub).
  static Future<List<DealVersion>> getDealVersions(String dealId) async {
    final deal = await getDeal(dealId);
    return deal.versions.reversed.toList();
  }

  /// DELETE /deals/:id → only a DRAFT deal with no confirmed parties.
  static Future<void> deleteDeal(String dealId) async {
    await _api.delete('/deals/$dealId');
  }

  /// GET /deals/:id/messages → the deal's party discussion (participants only).
  static Future<List<DealMessage>> getMessages(String dealId) async {
    final response = await _api.get('/deals/$dealId/messages');
    final items = (response as Map)['data'] as List? ?? const [];
    return items
        .map((e) => DealMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /deals/:id/messages → post a discussion message.
  static Future<DealMessage> sendMessage(String dealId, String body) async {
    final response = await _api.post(
      '/deals/$dealId/messages',
      data: {'body': body},
    );
    return DealMessage.fromJson(_data(response));
  }

  static Map<String, dynamic> _data(dynamic response) {
    final body = response as Map;
    return Map<String, dynamic>.from(body['data'] as Map);
  }
}

/// A deal discussion message (party chat, not the AI assistant).
class DealMessage {
  final String id;
  final String senderProfileId;
  final String body;
  final DateTime createdAt;
  final String? senderName;

  const DealMessage({
    required this.id,
    required this.senderProfileId,
    required this.body,
    required this.createdAt,
    this.senderName,
  });

  factory DealMessage.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    return DealMessage(
      id: json['id'] as String,
      senderProfileId: json['senderProfileId'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      senderName:
          sender?['displayName'] as String? ?? sender?['email'] as String?,
    );
  }
}

/// Invitation link + QR payload returned by POST /deals/:id/share.
class DealShareLink {
  final String inviteUrl;
  final String qrCodeData;
  final String? token;

  const DealShareLink({
    required this.inviteUrl,
    required this.qrCodeData,
    this.token,
  });

  factory DealShareLink.fromJson(Map<String, dynamic> json) {
    return DealShareLink(
      inviteUrl: json['inviteUrl'] as String? ?? '',
      qrCodeData:
          json['qrCodeData'] as String? ?? json['inviteUrl'] as String? ?? '',
      token: json['token'] as String?,
    );
  }
}

/// A participant supplied when creating a deal (mirrors `DealPartyInputDto`).
class DealPartyInput {
  final String email;
  final String role;
  final bool requiredApproval;

  const DealPartyInput({
    required this.email,
    required this.role,
    this.requiredApproval = true,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'role': role,
    'requiredApproval': requiredApproval,
  };
}
