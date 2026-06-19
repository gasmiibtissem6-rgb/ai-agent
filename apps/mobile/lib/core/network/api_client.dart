import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';

class ApiClient {
  const ApiClient({this.baseUrl = ApiConfig.baseUrl});

  final String baseUrl;

  Uri uri(String endpoint) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedEndpoint = endpoint.startsWith('/')
        ? endpoint
        : '/$endpoint';

    return Uri.parse('$normalizedBase$normalizedEndpoint');
  }

  Future<Map<String, dynamic>> getJson(String endpoint) async {
    final client = HttpClient();

    try {
      final request = await client.getUrl(uri(endpoint));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}: $body');
      }

      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {'response': decoded};
    } finally {
      client.close(force: true);
    }
  }
}
