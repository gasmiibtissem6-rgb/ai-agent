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

  /// PATCH /deals/:id/status → creator-only transition to Approved,
  /// Bridged (NEGOTIATION on the wire) or Cancelled.
  static Future<Deal> updateStatus({
    required String dealId,
    required DealStatus status,
    String? reason,
  }) async {
    final response = await _api.patch(
      '/deals/$dealId/status',
      data: {
        'status': status.wireValue,
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

  static Map<String, dynamic> _data(dynamic response) {
    final body = response as Map;
    return Map<String, dynamic>.from(body['data'] as Map);
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
