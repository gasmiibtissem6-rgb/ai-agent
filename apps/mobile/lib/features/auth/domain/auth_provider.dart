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
    await _subscription?.cancel();

    _subscription = AuthService.authStateChanges.listen((authState) {
      if (authState.event == AuthChangeEvent.passwordRecovery) {
        state = AsyncData(
          AppAuthState.passwordRecovery(),
        );
      }
    });

    ref.onDispose(() {
      _subscription?.cancel();
    });

    final token = await TokenStorage.getAccessToken();

    if (token == null) {
      return AppAuthState.unauthenticated();
    }

    try {
      final profile = await AuthApi.me();

      return AppAuthState.authenticated(profile);
    } catch (_) {
      await TokenStorage.clearTokens();

      return AppAuthState.unauthenticated();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = AsyncData(
      AppAuthState.loading(),
    );

    try {
      final profile = await AuthApi.register(
        email: email,
        password: password,
        fullName: fullName ?? '',
      );

      state = AsyncData(
        AppAuthState.authenticated(profile),
      );

      return true;
    } catch (e) {
      state = AsyncData(
        AppAuthState.error(_formatError(e)),
      );

      return false;
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = AsyncData(
      AppAuthState.loading(),
    );

    try {
      final profile = await AuthApi.login(
        email: email,
        password: password,
      );

      state = AsyncData(
        AppAuthState.authenticated(profile),
      );
    } catch (e) {
      state = AsyncData(
        AppAuthState.error(_formatError(e)),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = AsyncData(
      AppAuthState.loading(),
    );

    try {
      await AuthService.signInWithGoogle();

      final session = AuthService.currentSession;

      if (session == null) {
        state = AsyncData(
          AppAuthState.unauthenticated(),
        );
        return;
      }

      await TokenStorage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );

      final profile = await AuthApi.me();

      state = AsyncData(
        AppAuthState.authenticated(profile),
      );
    } catch (e) {
      state = AsyncData(
        AppAuthState.error(_formatError(e)),
      );
    }
  }

  Future<void> verifyOtp({
    required String email,
    required String token,
  }) async {
    state = AsyncData(
      AppAuthState.loading(),
    );

    try {
      await AuthService.verifyOtp(
        email: email,
        token: token,
      );

      final profile = await AuthApi.me();

      state = AsyncData(
        AppAuthState.authenticated(profile),
      );
    } catch (e) {
      state = AsyncData(
        AppAuthState.error(_formatError(e)),
      );
    }
  }

  Future<void> resendOtp({
    required String email,
  }) async {
    try {
      await AuthService.resendOtp(email: email);
    } catch (e) {
      state = AsyncData(
        AppAuthState.error(_formatError(e)),
      );
    }
  }

  Future<void> resetPassword(String email) async {
    state = AsyncData(
      AppAuthState.loading(),
    );

    try {
      await AuthApi.forgotPassword(email);
      await AuthService.resetPassword(email);

      state = AsyncData(
        AppAuthState.unauthenticated(),
      );
    } catch (e) {
      state = AsyncData(
        AppAuthState.error(_formatError(e)),
      );
    }
  }

  Future<bool> verifyResetOtp({
    required String email,
    required String token,
  }) async {
    state = AsyncData(
      AppAuthState.loading(),
    );

    try {
      await AuthService.verifyPasswordResetOtp(
        email: email,
        token: token,
      );

      return true;
    } catch (e) {
      state = AsyncData(
        AppAuthState.error(_formatError(e)),
      );

      return false;
    }
  }

  Future<bool> confirmNewPassword(String newPassword) async {
    state = AsyncData(
      AppAuthState.loading(),
    );

    try {
      await AuthService.confirmNewPassword(newPassword);
      await AuthApi.logout();
      await TokenStorage.clearTokens();

      state = AsyncData(
        AppAuthState.unauthenticated(),
      );

      return true;
    } catch (e) {
      state = AsyncData(
        AppAuthState.error(_formatError(e)),
      );

      return false;
    }
  }

  Future<void> signOut() async {
    await AuthApi.logout();
    await TokenStorage.clearTokens();

    try {
      await AuthService.signOut();
    } catch (_) {
      // Ignore Supabase logout errors.
    }

    state = AsyncData(
      AppAuthState.unauthenticated(),
    );
  }

  Future<void> deleteAccount() async {
    state = AsyncData(
      AppAuthState.loading(),
    );

    try {
      await AuthService.deleteAccount();
      await TokenStorage.clearTokens();

      state = AsyncData(
        AppAuthState.unauthenticated(),
      );
    } catch (e) {
      state = AsyncData(
        AppAuthState.error(_formatError(e)),
      );
    }
  }

  Future<bool> updateProfile({
    String? displayName,
    String? username,
    String? avatarUrl,
    bool? isPublic,
  }) async {
    try {
      final updatedProfile = await AuthApi.updateProfile(
        displayName: displayName,
        username: username,
        avatarUrl: avatarUrl,
        isPublic: isPublic,
      );

      state = AsyncData(
        AppAuthState.authenticated(updatedProfile),
      );

      return true;
    } catch (e) {
      state = AsyncData(
        AppAuthState.error(_formatError(e)),
      );

      return false;
    }
  }

  String _formatError(Object error) {
    if (error is AppException) {
      return error.message;
    }

    final message = error.toString();

    if (message.contains('Token has expired') ||
        message.contains('expired')) {
      return 'This code has expired. Request a new one.';
    }

    if (message.contains('Invalid token') ||
        message.contains('invalid')) {
      return 'Invalid code. Please check and try again.';
    }

    return 'Something went wrong. Please try again.';
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AppAuthState>(
  AuthNotifier.new,
);
