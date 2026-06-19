import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../core/constants/env.dart';


class AuthService {
  const AuthService._();

  static SupabaseClient get _client => SupabaseService.client!;

  static User? get currentUser => _client.auth.currentUser;
  static Session? get currentSession => _client.auth.currentSession;
  static bool get isLoggedIn => currentUser != null;
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Signup — sends OTP verification code to email
  static Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
      emailRedirectTo: null,
    );
  }

  // Verify OTP code after signup
  static Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    return await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );
  }

  // Login
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

 // Google Sign In
static Future<void> signInWithGoogle() async {
  await _client.auth.signInWithOAuth(
    OAuthProvider.google,
    redirectTo: 'http://localhost:8080',
  );
}
static Future<void> deleteAccount() async {
  final user = currentUser;
  if (user == null) return;
  await _client.rpc('delete_user');
  await signOut();
}
  // Password reset
  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // Logout
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}