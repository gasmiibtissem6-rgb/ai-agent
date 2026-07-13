import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/errors/app_exception.dart';
import '../core/network/api_client.dart';

/// An image embedded in a generated PDF. The backend strips the
/// `data:image/...;base64,` prefix itself, so a data URL is accepted as-is.
class DocumentMedia {
  final String dataUrl;
  final String? caption;

  const DocumentMedia({required this.dataUrl, this.caption});

  Map<String, dynamic> toJson() => {
    'type': 'image',
    'data': dataUrl,
    if (caption != null) 'caption': caption,
  };
}

/// Generates deal/template documents and runs OCR, via the NestJS chat module.
///
/// Reuses [ApiClient]'s Dio so the bearer token, logging and certificate
/// pinning all apply — unlike the raw `Dio()` the chat and documents screens
/// still construct by hand.
class DocumentService {
  const DocumentService._();

  static Dio get _dio => ApiClient.instance.dio;

  /// POST /chat/generate-pdf → the rendered PDF bytes.
  static Future<Uint8List> generatePdf({
    required String title,
    required String content,
    List<DocumentMedia> media = const [],
  }) async {
    try {
      final response = await _dio.post(
        '/chat/generate-pdf',
        data: {
          'title': title,
          'content': content,
          if (media.isNotEmpty)
            'mediaItems': media.map((m) => m.toJson()).toList(),
        },
        options: Options(responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data is Uint8List) return data;
      return Uint8List.fromList(List<int>.from(data as List));
    } on DioException catch (e) {
      throw ServerException('Could not generate the document: ${e.message}');
    }
  }

  /// POST /chat/scan-contract → text extracted from an image by OCR.
  ///
  /// Returns an empty string when the backend finds no text.
  static Future<String> scanDocument({
    required String imageDataUrl,
    String lang = 'fra+eng',
  }) async {
    try {
      final response = await _dio.post(
        '/chat/scan-contract',
        data: {'image': imageDataUrl, 'lang': lang},
      );
      final body = response.data as Map;
      if (body['success'] != true) return '';
      return body['text'] as String? ?? '';
    } on DioException catch (e) {
      throw ServerException('Could not scan the document: ${e.message}');
    }
  }
}
