import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/api_config.dart';

class ChatMessage {
  final String role;
  final String content;
  const ChatMessage({required this.role, required this.content});
  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });
  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();

  Future<void> sendMessage(String message, {String? image}) async {
    final newMessages = [
      ...state.messages,
      ChatMessage(role: 'user', content: message),
    ];
    state = state.copyWith(messages: newMessages, isLoading: true);
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      final dio = Dio();
      final response = await dio.post(
        '${ApiConfig.baseUrl}/chat/message',
        data: {
          'message': message,
          'history': newMessages.map((m) => m.toJson()).toList(),
          'image': ?image,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      final reply = response.data['data']['reply'] as String;
      final updated = [
        ...newMessages,
        ChatMessage(role: 'assistant', content: reply),
      ];
      state = state.copyWith(messages: updated, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Connection error.');
    }
  }

  void clearChat() => state = const ChatState();
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
