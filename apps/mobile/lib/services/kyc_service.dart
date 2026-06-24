import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../features/kyc/domain/kyc_model.dart';
import 'supabase_service.dart';

/// KYC Service — handles document upload and verification status
/// File uploads go directly to Supabase Storage (private bucket)
/// KYC business logic and admin review goes through NestJS API
class KycService {
  const KycService._();

  static SupabaseClient get _client => SupabaseService.client!;
  static const _uuid = Uuid();

  /// Get current user's KYC submission
  static Future<KycSubmission?> getMyKyc() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('kyc_submissions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return KycSubmission.fromJson(response);
  }

  /// Upload a KYC document to private storage bucket
  /// Returns the file path in storage
  static Future<String> uploadDocument({
    required String userId,
    required Uint8List fileBytes,
    required String fileName,
    required String fileType,
    void Function(double)? onProgress,
  }) async {
    final fileId = _uuid.v4();
    final extension = fileName.split('.').last;
    final storagePath = '$userId/$fileType/$fileId.$extension';

    await _client.storage.from('kyc-documents').uploadBinary(
      storagePath,
      fileBytes,
      fileOptions: const FileOptions(
        cacheControl: '3600',
        upsert: false,
      ),
    );

    return storagePath;
  }

  /// Get a signed URL for temporary access to a private file
  static Future<String> getSignedUrl(String storagePath) async {
    final response = await _client.storage
        .from('kyc-documents')
        .createSignedUrl(storagePath, 3600); // 1 hour expiry
    return response;
  }

  /// Submit KYC after uploading documents
  static Future<KycSubmission> submitKyc({
    required String documentType,
    required String frontPath,
    String? backPath,
    String? selfiePath,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _client
        .from('kyc_submissions')
        .insert({
          'user_id': userId,
          'document_type': documentType,
          'document_url': frontPath,
          'front_url': frontPath,
          'back_url': backPath,
          'selfie_url': selfiePath,
          'status': 'pending',
        })
        .select()
        .single();

    // Log audit event
    await _logAuditEvent(
      userId: userId,
      eventType: 'kyc_submitted',
      resourceType: 'kyc_submission',
      metadata: {'document_type': documentType},
    );

    return KycSubmission.fromJson(response);
  }

  /// Log audit event to audit_logs table
  static Future<void> _logAuditEvent({
    required String userId,
    required String eventType,
    String? resourceType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _client.from('audit_logs').insert({
        'user_id': userId,
        'event_type': eventType,
        'resource_type': resourceType,
        'metadata': metadata ?? {},
      });
    } catch (_) {
      // Audit logging should never break the main flow
    }
  }
}