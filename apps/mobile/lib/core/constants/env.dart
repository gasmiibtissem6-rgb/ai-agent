import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  const Env._();

  static Future<void> load() async {
    for (final fileName in const ['.env', '.env.example']) {
      try {
        await dotenv.load(fileName: fileName);
        break;
      } catch (_) {
        // Local env files are intentionally untracked; fall back to the safe template.
      }
    }
  }

  static String get googleClientId => dotenv.maybeGet('GOOGLE_CLIENT_ID') ?? '';

  static String get supabaseUrl => dotenv.maybeGet('SUPABASE_URL') ?? '';

  static String get supabaseAnonKey =>
      dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
