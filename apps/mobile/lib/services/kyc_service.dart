import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/network/api_client.dart';
import '../features/kyc/domain/kyc_model.dart';

/// KYC Service — now goes through the NestJS API (Front → NestJS → Supabase),
/// the same architecture as auth. The client no longer talks to Supabase
/// directly:
///  1. POST /kyc/storage/authorize → a signed upload URL + pre-authorized path.
///  2. PUT the bytes straight to the signed Storage URL (NestJS never sees them).
///  3. POST /kyc/submit → creates the submission from the authorized paths.
class KycService {
  const KycService._();

  static final ApiClient _api = ApiClient.instance;

  /// GET /kyc/me/status → the caller's current verification status.
  static Future<KycSubmission?> getMyKyc() async {
    final response = await _api.get('/kyc/me/status');
    final data = _data(response);
    final status = (data['status'] as String?) ?? 'NOT_STARTED';
    if (status == 'NOT_STARTED') return null;
    return KycSubmission.fromStatus(data);
  }

  /// Authorizes and uploads a single document, returning the pre-authorized
  /// storage path to reference on submit.
  static Future<String> uploadDocument({
    required Uint8List fileBytes,
    required String fileName,
    required String documentSide, // 'front' | 'back' | 'selfie'
  }) async {
    final mimeType = _mimeFromName(fileName);
    final authorized = await _api.post(
      '/kyc/storage/authorize',
      data: {
        'fileName': fileName,
        'mimeType': mimeType,
        'sizeBytes': fileBytes.length,
        'documentSide': documentSide,
      },
    );
    final data = _data(authorized);
    final uploadUrl = data['uploadUrl'] as String;
    final storagePath = data['storagePath'] as String;

    await _putBytes(uploadUrl, fileBytes, mimeType);
    return storagePath;
  }

  /// POST /kyc/submit → create the submission from pre-authorized paths.
  static Future<KycSubmission> submitKyc({
    required String documentType,
    required String storagePathFront,
    String? storagePathBack,
    required String storagePathSelfie,
    Map<String, dynamic>? personalInfo,
  }) async {
    final response = await _api.post(
      '/kyc/submit',
      data: {
        'documentType': documentType,
        'storagePathFront': storagePathFront,
        'storagePathBack': ?storagePathBack,
        'storagePathSelfie': storagePathSelfie,
        if (personalInfo != null && personalInfo.isNotEmpty)
          'personalInfo': personalInfo,
      },
    );
    return KycSubmission.fromSubmitResponse(_data(response));
  }

  /// PUTs the raw bytes to the signed Storage URL. Uses a bare Dio because the
  /// URL is an absolute Supabase Storage URL, not our API base, and must not
  /// carry our Authorization header or interceptors.
  static Future<void> _putBytes(
    String uploadUrl,
    Uint8List bytes,
    String mimeType,
  ) async {
    final dio = Dio();
    await dio.put(
      uploadUrl,
      data: Stream<List<int>>.fromIterable([bytes]),
      options: Options(
        headers: {
          'Content-Type': mimeType,
          Headers.contentLengthHeader: bytes.length,
          'x-upsert': 'true',
        },
      ),
    );
  }

  static String _mimeFromName(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'image/jpeg';
    }
  }

  static Map<String, dynamic> _data(dynamic response) {
    final body = response as Map;
    return Map<String, dynamic>.from(body['data'] as Map);
  }
}
