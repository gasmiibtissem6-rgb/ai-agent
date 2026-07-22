import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/api_config.dart';

class ChatMessage {
  final String role;
  final String content;

  const ChatMessage({
    required this.role,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final String sessionId;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    required this.sessionId,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    String? sessionId,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  static const Uuid _uuid = Uuid();

  late final Dio _dio;

  @override
  ChatState build() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 3),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    return ChatState(
      sessionId: _uuid.v4(),
    );
  }

  Future<void> sendMessage(
    String message, {
    String? image,
  }) async {
    final text = message.trim();

    if (text.isEmpty || state.isLoading) {
      return;
    }

    final userMessage = ChatMessage(
      role: 'user',
      content: text,
    );

    final currentMessages = [
      ...state.messages,
      userMessage,
    ];

    state = state.copyWith(
      messages: currentMessages,
      isLoading: true,
      clearError: true,
    );

    try {
      final token =
          Supabase.instance.client.auth.currentSession?.accessToken;

      final response = await _dio.post(
        '/chat/message',
        data: {
          'message': text,
          'sessionId': state.sessionId,
          'history': currentMessages
              .map((chatMessage) => chatMessage.toJson())
              .toList(),
          if (image != null && image.isNotEmpty)
            'image': image,
        },
        options: Options(
          headers: {
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        ),
      );

      final responseBody = response.data;

      if (responseBody is! Map<String, dynamic>) {
        throw const FormatException(
          'Format de réponse invalide.',
        );
      }

      final responseData = responseBody['data'];

      if (responseData is! Map<String, dynamic>) {
        throw const FormatException(
          'Les données retournées sont invalides.',
        );
      }

      final answer =
          responseData['answer']?.toString().trim();

      if (answer == null || answer.isEmpty) {
        throw const FormatException(
          'Aucune réponse reçue de l’agent IA.',
        );
      }

      state = state.copyWith(
        messages: [
          ...currentMessages,
          ChatMessage(
            role: 'assistant',
            content: answer,
          ),
        ],
        isLoading: false,
        clearError: true,
      );
    } on DioException catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: _extractServerError(error),
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  String _extractServerError(DioException error) {
    final data = error.response?.data;

    if (data is Map<String, dynamic>) {
      final message = data['message'];

      if (message is String && message.isNotEmpty) {
        return message;
      }

      final nestedError = data['error'];

      if (nestedError is Map<String, dynamic>) {
        final nestedMessage = nestedError['message'];

        if (nestedMessage is String) {
          return nestedMessage;
        }

        if (nestedMessage is List) {
          return nestedMessage.join('\n');
        }
      }
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Impossible de contacter le backend NestJS.';
    }

    if (error.type == DioExceptionType.receiveTimeout) {
      return 'L’agent IA met trop de temps à répondre.';
    }

    return 'Erreur de communication avec le serveur.';
  }

  void clearChat() {
    state = ChatState(
      sessionId: _uuid.v4(),
    );
  }
}

final chatProvider =
    NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
