import 'package:dio/dio.dart';

class AiAgentService {
  AiAgentService({
    String baseUrl = 'http://localhost:3001',
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(minutes: 2),
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        );

  final Dio _dio;

  Future<String> sendMessage(String message) async {
    try {
      final response = await _dio.post(
        '/api/v1/chat/message',
        data: {
          'message': message,
        },
      );

      final responseData = response.data;

      final answer =
          responseData['data']?['answer']?.toString();

      if (answer == null || answer.isEmpty) {
        throw Exception(
          'Aucune réponse reçue de l’agent IA.',
        );
      }

      return answer;
    } on DioException catch (error) {
      final serverMessage =
          error.response?.data?['message']?.toString();

      throw Exception(
        serverMessage ??
            'Impossible de contacter le backend NestJS.',
      );
    }
  }
}