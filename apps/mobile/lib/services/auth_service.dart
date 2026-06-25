import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/network/token_storage.dart';
import 'supabase_service.dart';

class AuthService {
  const AuthService._();

  static SupabaseClient get _client => SupabaseService.client!;

  static User? get currentUser => _client.auth.currentUser;
  static Session? get currentSession => _client.auth.currentSession;
  static bool get isLoggedIn => currentUser != null;
  static Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  /// Sign up — sends OTP verification code to email
  static Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
  }

  /// Verify OTP code sent to email after signup
  static Future<void> verifyOtp({
    required String email,
    required String token,
  }) async {
    final response = await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );

    // Save token to secure storage for NestJS API bearer auth
    final accessToken = response.session?.accessToken;
    final refreshToken = response.session?.refreshToken;
    if (accessToken != null) {
      await TokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }
  }

  /// Resend OTP code to email after signup
  static Future<void> resendOtp({required String email}) async {
    await _client.auth.resend(type: OtpType.signup, email: email);
  }

  /// Login with email and password
  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Save token for NestJS API bearer auth
    final accessToken = response.session?.accessToken;
    final refreshToken = response.session?.refreshToken;
    if (accessToken != null) {
      await TokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }
  }

  /// Sign in with Google OAuth
  static Future<void> signInWithGoogle() async {
    final redirectTo = kIsWeb ? Uri.base.toString() : null;
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
    );

    final session = currentSession;
    if (session != null) {
      await TokenStorage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
    }
  }

  /// Send password reset email
  static Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.idealapp://reset-password',
    );
  }

  /// Update the authenticated user's password (called after PASSWORD_RECOVERY)
  static Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  /// Sign out and clear stored tokens
  static Future<void> signOut() async {
    await _client.auth.signOut();
    await TokenStorage.clearTokens();
  }

  /// Delete account via Supabase RPC then sign out
  static Future<void> deleteAccount() async {
    await _client.rpc('delete_user');
    await signOut();
  }
}
