import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/auth_service.dart';
import 'auth_state.dart';

class AuthNotifier extends AsyncNotifier<AppAuthState> {
  StreamSubscription<AuthState>? _subscription;

  @override
  Future<AppAuthState> build() async {
    final user = AuthService.currentUser;

    _subscription?.cancel();
    _subscription = AuthService.authStateChanges.listen((authState) {
      final u = authState.session?.user;
      if (u != null) {
        state = AsyncData(AppAuthState.authenticated(u));
      } else {
        state = AsyncData(AppAuthState.unauthenticated());
      }
    });

    ref.onDispose(() => _subscription?.cancel());

    if (user != null) return AppAuthState.authenticated(user);
    return AppAuthState.unauthenticated();
  }

  /// Sign up — returns true if successful (navigate to OTP screen)
  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = AsyncData(AppAuthState.loading());
    try {
      await AuthService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = AsyncData(AppAuthState.unauthenticated());
      return true;
    } catch (e) {
      final message = e.toString();
      if (message.contains('User already registered') ||
          message.contains('already been registered') ||
          message.contains('email address is already')) {
        state = AsyncData(
          AppAuthState.error(
            'An account with this email already exists. Please sign in instead.',
          ),
        );
      } else {
        state = AsyncData(AppAuthState.error(_formatError(e)));
      }
      return false;
    }
  }

  /// Verify OTP after signup
  Future<void> verifyOtp({required String email, required String token}) async {
    state = AsyncData(AppAuthState.loading());
    try {
      await AuthService.verifyOtp(email: email, token: token);
    } catch (e) {
      state = AsyncData(AppAuthState.error(_formatError(e)));
    }
  }

  /// Sign in with email and password
  Future<void> signIn({required String email, required String password}) async {
    state = AsyncData(AppAuthState.loading());
    try {
      await AuthService.signIn(email: email, password: password);
    } catch (e) {
      state = AsyncData(AppAuthState.error(_formatError(e)));
    }
  }

  /// Sign in with Google OAuth
  Future<void> signInWithGoogle() async {
    state = AsyncData(AppAuthState.loading());
    try {
      await AuthService.signInWithGoogle();
      final user = AuthService.currentUser;
      if (user != null) {
        state = AsyncData(AppAuthState.authenticated(user));
      } else {
        state = AsyncData(AppAuthState.unauthenticated());
      }
    } catch (e) {
      state = AsyncData(AppAuthState.error(_formatError(e)));
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    state = AsyncData(AppAuthState.loading());
    try {
      await AuthService.resetPassword(email);
      state = AsyncData(AppAuthState.unauthenticated());
    } catch (e) {
      state = AsyncData(AppAuthState.error(_formatError(e)));
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await AuthService.signOut();
  }

  /// Delete account permanently
  Future<void> deleteAccount() async {
    state = AsyncData(AppAuthState.loading());
    try {
      await AuthService.deleteAccount();
    } catch (e) {
      state = AsyncData(AppAuthState.error(_formatError(e)));
    }
  }

  String _formatError(Object e) {
    final message = e.toString();
    if (message.contains('Invalid login credentials')) {
      return 'Invalid email or password.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Please verify your email first.';
    }
    if (message.contains('User already registered')) {
      return 'An account with this email already exists.';
    }
    if (message.contains('Token has expired')) {
      return 'Verification code expired. Please sign up again.';
    }
    if (message.contains('Invalid OTP')) {
      return 'Invalid verification code. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AppAuthState>(
  AuthNotifier.new,
);
