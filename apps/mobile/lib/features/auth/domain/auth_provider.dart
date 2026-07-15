import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/token_storage.dart';
import '../../../services/auth_api.dart';
import '../../../services/auth_service.dart';
import 'auth_state.dart';

class AuthNotifier extends AsyncNotifier<AppAuthState> {
  StreamSubscription<AuthState>? _subscription;

  @override
  Future<AppAuthState> build() async {
    _subscription?.cancel();
    _subscription = AuthService.authStateChanges.listen((authState) {
      // Supabase is only the source of truth for the password-recovery
      // OTP event now; everything else is driven by NestJS via AuthApi.
      if (authState.event == AuthChangeEvent.passwordRecovery) {
        state = AsyncData(AppAuthState.passwordRecovery());
      }
    });

    ref.onDispose(() => _subscription?.cancel());

    // Restore the session from the stored token via NestJS GET /auth/me.
    final token = await TokenStorage.getAccessToken();
    if (token == null) {
      return AppAuthState.unauthenticated();
    }
    try {
      final profile = await AuthApi.me();
      return AppAuthState.authenticated(profile);
    } catch (_) {
      // Token invalid and unrecoverable (the interceptor already tried refresh).
      await TokenStorage.clearTokens();
      return AppAuthState.unauthenticated();
    }
  }

  /// Register via NestJS (email auto-confirmed, no OTP) and log straight in.
  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = AsyncData(AppAuthState.loading());
    try {
      final profile = await AuthApi.register(
        email: email,
        password: password,
        fullName: fullName ?? '',
      );
      state = AsyncData(AppAuthState.authenticated(profile));
      return true;
    } catch (e) {
      state = AsyncData(AppAuthState.error(_formatError(e)));
      return false;
    }
  }

  /// Sign in with email and password via NestJS.
  Future<void> signIn({required String email, required String password}) async {
    state = AsyncData(AppAuthState.loading());
    try {
      final profile = await AuthApi.login(email: email, password: password);
      state = AsyncData(AppAuthState.authenticated(profile));
    } catch (e) {
      state = AsyncData(AppAuthState.error(_formatError(e)));
    }
  }

  /// Sign in with Google — still on Supabase (to migrate later). The
  /// resulting Supabase JWT is stored and resolved to the canonical
  /// NestJS profile so the rest of the app stays profile-driven.
  Future<void> signInWithGoogle() async {
    state = AsyncData(AppAuthState.loading());
    try {
      await AuthService.signInWithGoogle();
      final session = AuthService.currentSession;
      if (session != null) {
        await TokenStorage.saveTokens(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
        );
        final profile = await AuthApi.me();
        state = AsyncData(AppAuthState.authenticated(profile));
      } else {
        state = AsyncData(AppAuthState.unauthenticated());
      }
    } catch (e) {
      state = AsyncData(AppAuthState.error(_formatError(e)));
    }
  }

  /// Verify the signup OTP code (Supabase-issued), then resolve the
  /// canonical NestJS profile so the app is authenticated afterward.
  Future<void> verifyOtp({required String email, required String token}) async {
    state = AsyncData(AppAuthState.loading());
    try {
      await AuthService.verifyOtp(email: email, token: token);
      final profile = await AuthApi.me();
      state = AsyncData(AppAuthState.authenticated(profile));
    } catch (e) {
      state = AsyncData(AppAuthState.error(_formatError(e)));
    }
  }

  /// Resend the signup verification code.
  Future<void> resendOtp({required String email}) async {
    try {
      await AuthService.resendOtp(email: email);
    } catch (e) {
      state = AsyncData(AppAuthState.error(_formatError(e)));
    }
  }

  /// Kick off password reset: logs the request with NestJS, and asks
  /// Supabase to email the 6-digit OTP code.
  Future<void> resetPassword(String email) async {
    state = AsyncData(AppAuthState.loading());
    try {
      await AuthApi.forgotPassword(email);
      await AuthService.resetPassword(email);
      state = AsyncData(AppAuthState.unauthenticated());
    } catch (e) {
      state = AsyncData(AppAuthState.error(_formatError(e)));
    }
  }

  /// Verify the reset-password OTP code.
  Future<bool> verifyResetOtp({
    required String email,
    required String token,
  }) async {
    state = AsyncData(AppAuthState.loading());
    try {
      await AuthService.verifyPasswordResetOtp(email: email, token: token);
      return true;
    } catch (e) {
      state = AsyncData(AppAuthState.error(_formatError(e)));
      return false;
    }
  }

  /// Set the new password after OTP verification, then force a fresh login.
  Future<bool> confirmNewPassword(String newPassword) async {
    state = AsyncData(AppAuthState.loading());
    try {
      await AuthService.confirmNewPassword(newPassword);
      await AuthApi.logout();
      await TokenStorage.clearTokens();
      state = AsyncData(AppAuthState.unauthenticated());
      return true;
    } catch (e) {
      state = AsyncData(AppAuthState.error(_formatError(e)));
      return false;
    }
  }

  /// Sign out: NestJS logout (best-effort) + clear tokens + clear any
  /// Supabase session left over from Google/recovery flows.
  Future<void> signOut() async {
    await AuthApi.logout();
    await TokenStorage.clearTokens();
    try {
      await AuthService.signOut();
    } catch (_) {}
    state = AsyncData(AppAuthState.unauthenticated());
  }

  /// Delete account — still on Supabase (out of scope this session).
  Future<void> deleteAccount() async {
    state = AsyncData(AppAuthState.loading());
    try {
      await AuthService.deleteAccount();
      await TokenStorage.clearTokens();
      state = AsyncData(AppAuthState.unauthenticated());
    } catch (e) {
      state = AsyncData(AppAuthState.error(_formatError(e)));
    }
  }

  String _formatError(Object e) {
    if (e is AppException) {
      // Surface the NestJS envelope's `message` verbatim.
      return e.message;
    }
    final message = e.toString();
    if (message.contains('Token has expired') || message.contains('expired')) {
      return 'This code has expired. Request a new one.';
    }
    if (message.contains('Invalid token') || message.contains('invalid')) {
      return 'Invalid code. Please check and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AppAuthState>(
  AuthNotifier.new,
);