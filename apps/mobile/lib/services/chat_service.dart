import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

class ChatService {
  const ChatService();

  RealtimeChannel? messagesChannel(String dealId) {
    final client = SupabaseService.client;
    if (client == null) {
      return null;
    }

    return client.channel('deal:$dealId:messages');
  }
}
