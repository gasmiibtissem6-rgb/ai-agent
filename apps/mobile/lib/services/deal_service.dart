import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/deal/domain/deal_model.dart';
import 'supabase_service.dart';

/// Deal Service — handles deal CRUD via Supabase directly for now
/// When NestJS backend is ready, this will go through ApiClient
class DealService {
  const DealService._();

  static SupabaseClient get _client => SupabaseService.client!;

  static String get _userId => _client.auth.currentUser?.id ?? '';

  /// Get all deals for current user
  static Future<List<Deal>> getMyDeals() async {
    final response = await _client
        .from('deals')
        .select()
        .eq('created_by', _userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Deal.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a single deal by ID
  static Future<Deal> getDeal(String dealId) async {
    final response = await _client
        .from('deals')
        .select()
        .eq('id', dealId)
        .single();

    return Deal.fromJson(response);
  }

  /// Create a new deal with first version
  static Future<Deal> createDeal({
    required String title,
    required String description,
    required String content,
  }) async {
    // Create deal
    final dealResponse = await _client
        .from('deals')
        .insert({
          'title': title,
          'description': description,
          'status': 'draft',
          'created_by': _userId,
        })
        .select()
        .single();

    final deal = Deal.fromJson(dealResponse);

    // Create first version
    await _client.from('deal_versions').insert({
      'deal_id': deal.id,
      'version_number': 1,
      'content': content,
      'created_by': _userId,
      'is_final': false,
    });

    // Log audit
    await _logAudit('deal_created', dealId: deal.id);

    return deal;
  }

  /// Send deal to other party
  static Future<Deal> sendDeal(String dealId) async {
    final response = await _client
        .from('deals')
        .update({'status': 'sent'})
        .eq('id', dealId)
        .eq('created_by', _userId)
        .select()
        .single();

    await _logAudit('deal_sent', dealId: dealId);
    return Deal.fromJson(response);
  }

  /// Get all versions of a deal
  static Future<List<DealVersion>> getDealVersions(String dealId) async {
    final response = await _client
        .from('deal_versions')
        .select()
        .eq('deal_id', dealId)
        .order('version_number', ascending: false);

    return (response as List)
        .map((json) => DealVersion.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new version of a deal (for modifications)
  static Future<DealVersion> createNewVersion({
    required String dealId,
    required String content,
    required int previousVersionNumber,
  }) async {
    final response = await _client
        .from('deal_versions')
        .insert({
          'deal_id': dealId,
          'version_number': previousVersionNumber + 1,
          'content': content,
          'created_by': _userId,
          'is_final': false,
        })
        .select()
        .single();

    // Update deal status to negotiating
    await _client
        .from('deals')
        .update({'status': 'negotiating'})
        .eq('id', dealId);

    await _logAudit('deal_version_created', dealId: dealId);
    return DealVersion.fromJson(response);
  }

  /// Approve a deal version
  static Future<void> approveDeal({
    required String dealId,
    required String versionId,
    String? comment,
  }) async {
    await _client.from('approvals').insert({
      'deal_id': dealId,
      'version_id': versionId,
      'user_id': _userId,
      'action': 'approved',
      'comment': comment,
    });

    await _client
        .from('deals')
        .update({'status': 'approved'})
        .eq('id', dealId);

    await _logAudit('deal_approved', dealId: dealId);
  }

  /// Reject a deal version
  static Future<void> rejectDeal({
    required String dealId,
    required String versionId,
    String? comment,
  }) async {
    await _client.from('approvals').insert({
      'deal_id': dealId,
      'version_id': versionId,
      'user_id': _userId,
      'action': 'rejected',
      'comment': comment,
    });

    await _client
        .from('deals')
        .update({'status': 'rejected'})
        .eq('id', dealId);

    await _logAudit('deal_rejected', dealId: dealId);
  }

  /// Request modification on a deal version
  static Future<void> requestModification({
    required String dealId,
    required String versionId,
    required String comment,
  }) async {
    await _client.from('approvals').insert({
      'deal_id': dealId,
      'version_id': versionId,
      'user_id': _userId,
      'action': 'modify_requested',
      'comment': comment,
    });

    await _client
        .from('deals')
        .update({'status': 'negotiating'})
        .eq('id', dealId);

    await _logAudit('deal_modification_requested', dealId: dealId);
  }

  /// Finalize a deal — locks it permanently
  static Future<Deal> finalizeDeal({
    required String dealId,
    required String versionId,
  }) async {
    // Lock the version
    await _client
        .from('deal_versions')
        .update({'is_final': true})
        .eq('id', versionId);

    // Finalize the deal
    final response = await _client
        .from('deals')
        .update({
          'status': 'finalized',
          'finalized_at': DateTime.now().toIso8601String(),
          'finalized_version_id': versionId,
        })
        .eq('id', dealId)
        .select()
        .single();

    await _logAudit('deal_finalized', dealId: dealId);
    return Deal.fromJson(response);
  }

  static Future<void> _logAudit(String eventType, {String? dealId}) async {
    try {
      await _client.from('audit_logs').insert({
        'user_id': _userId,
        'event_type': eventType,
        'resource_type': 'deal',
        'metadata': {'deal_id': dealId},
      });
    } catch (_) {}
  }
}