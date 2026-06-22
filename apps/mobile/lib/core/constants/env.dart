import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  const Env._();

  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Local env files are intentionally untracked; the app can boot without one.
    }
  }

  static String get supabaseUrl => dotenv.maybeGet('SUPABASE_URL') ?? '';

  static String get supabaseAnonKey =>
      dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';

  static String get apiBaseUrl => dotenv.maybeGet('API_BASE_URL') ?? '';

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
