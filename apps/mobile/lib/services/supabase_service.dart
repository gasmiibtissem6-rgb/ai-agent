import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/env.dart';

class SupabaseService {
  const SupabaseService._();

  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static SupabaseClient? get client {
    if (!_isInitialized) {
      return null;
    }

    return Supabase.instance.client;
  }

  static Future<void> initialize() async {
    if (!Env.hasSupabaseConfig || _isInitialized) {
      return;
    }

    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );

    _isInitialized = true;
  }
}
