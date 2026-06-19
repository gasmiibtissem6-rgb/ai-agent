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
      return true;
    } catch (e) {
      state = AsyncData(AppAuthState.error(e.toString()));
      return false;
    }
  }

  Future<void> verifyOtp({
    required String email,
    required String token,
  }) async {
    state = AsyncData(AppAuthState.loading());
    try {
      await AuthService.verifyOtp(email: email, token: token);
    } catch (e) {
      state = AsyncData(AppAuthState.error(e.toString()));
    }
  }

  Future<void> signInWithGoogle() async {
    state = AsyncData(AppAuthState.loading());
    try {
      await AuthService.signInWithGoogle();
    } catch (e) {
      state = AsyncData(AppAuthState.error(e.toString()));
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = AsyncData(AppAuthState.loading());
    try {
      await AuthService.signIn(email: email, password: password);
    } catch (e) {
      state = AsyncData(AppAuthState.error(e.toString()));
    }
  }

  Future<void> resetPassword(String email) async {
    state = AsyncData(AppAuthState.loading());
    try {
      await AuthService.resetPassword(email);
      state = AsyncData(AppAuthState.unauthenticated());
    } catch (e) {
      state = AsyncData(AppAuthState.error(e.toString()));
    }
  }

  Future<void> signOut() async {
    await AuthService.signOut();
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AppAuthState>(
  AuthNotifier.new,
);