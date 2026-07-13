import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/auth_session_events.dart';
import '../../../core/network/token_storage.dart';
import '../../../services/auth_api.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import 'auth_state.dart';

class AuthNotifier extends AsyncNotifier<AppAuthState> {
  StreamSubscription<AuthState>? _subscription;
  StreamSubscription<void>? _sessionSub;

  @override
  Future<AppAuthState> build() async {
    // Route back to login whenever the network layer reports a dead session
    // (refresh failed on a 401).
    _sessionSub?.cancel();
    _sessionSub = AuthSessionEvents.instance.onSignedOut.listen((_) async {
      await TokenStorage.clearTokens();
      state = AsyncData(AppAuthState.unauthenticated());
    });

    // Supabase auth events are still consumed for the flows kept on Supabase:
    //  - passwordRecovery: the reset-password deep link (to migrate later).
    //  - signedIn: Google OAuth, whose web redirect completes asynchronously
    //    and delivers the session via this event (not the signInWithGoogle call).
    _subscription?.cancel();
    _subscription = AuthService.authStateChanges.listen((authState) {
      switch (authState.event) {
        case AuthChangeEvent.passwordRecovery:
          state = AsyncData(AppAuthState.passwordRecovery());
          break;
        case AuthChangeEvent.signedIn:
          final session = authState.session;
          if (session != null) {
            _hydrateFromSupabaseSession(session);
          }
          break;
        default:
          break;
      }
    });

    ref.onDispose(() {
      _subscription?.cancel();
      _sessionSub?.cancel();
    });

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

  /// Sign in with Google — STILL ON SUPABASE (to migrate later). The resulting
  /// Supabase JWT is stored and validated by NestJS like any other token.
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

  /// Send a password-reset email via NestJS (generic success always).
  Future<void> resetPassword(String email) async {
    state = AsyncData(AppAuthState.loading());
    try {
      await AuthApi.forgotPassword(email);
      state = AsyncData(AppAuthState.unauthenticated());
    } catch (e) {
      state = AsyncData(AppAuthState.error(_formatError(e)));
    }
  }

  /// Update the password after a PASSWORD_RECOVERY deep link.
  /// STILL ON SUPABASE (to migrate later) — completion uses the recovery token.
  Future<bool> updatePassword(String newPassword) async {
    state = AsyncData(AppAuthState.loading());
    try {
      await AuthService.updatePassword(newPassword);
      // Sign out everywhere and force a fresh login for security.
      await AuthApi.logout();
      await TokenStorage.clearTokens();
      try {
        await AuthService.signOut();
      } catch (_) {}
      state = AsyncData(AppAuthState.unauthenticated());
      return true;
    } catch (e) {
      state = AsyncData(AppAuthState.error(_formatError(e)));
      return false;
    }
  }

  /// Updates the caller's own profile via NestJS and refreshes the auth state
  /// so every screen reading `profile` re-renders with the new values.
  ///
  /// Returns the backend's message on failure, or `null` on success. The state
  /// is never moved to `error` here: that would log the user out of the router's
  /// point of view for what is only a form failure.
  Future<String?> updateProfile({
    String? displayName,
    String? username,
    String? avatarUrl,
    bool? isPublic,
  }) async {
    final previous = state.whenOrNull(data: (s) => s);
    if (previous?.profile == null) return 'You are not signed in.';

    try {
      final profile = await ProfileService.updateProfile(
        displayName: displayName,
        username: username,
        avatarUrl: avatarUrl,
        isPublic: isPublic,
      );
      state = AsyncData(AppAuthState.authenticated(profile));
      return null;
    } catch (e) {
      return _formatError(e);
    }
  }

  /// Sign out: NestJS logout (best-effort) + clear tokens + clear any Supabase
  /// session left over from Google/recovery flows.
  Future<void> signOut() async {
    await AuthApi.logout();
    await TokenStorage.clearTokens();
    try {
      await AuthService.signOut();
    } catch (_) {}
    state = AsyncData(AppAuthState.unauthenticated());
  }

  /// Delete account — STILL ON SUPABASE (out of scope this session).
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

  // --- DEAD CODE (kept intentionally, no longer reachable) -------------------
  // The OTP email-verification flow is disabled now that registration
  // auto-confirms the email. These remain until explicitly removed.

  Future<void> verifyOtp({required String email, required String token}) async {
    state = AsyncData(AppAuthState.loading());
    try {
      await AuthService.verifyOtp(email: email, token: token);
    } catch (e) {
      state = AsyncData(AppAuthState.error(_formatError(e)));
    }
  }

  Future<void> resendOtp({required String email}) async {
    try {
      await AuthService.resendOtp(email: email);
    } catch (e) {
      state = AsyncData(AppAuthState.error(_formatError(e)));
    }
  }

  // ---------------------------------------------------------------------------

  /// Persists a Supabase-issued session (e.g. from Google OAuth) and resolves
  /// the canonical profile through NestJS so the rest of the app is token-driven.
  Future<void> _hydrateFromSupabaseSession(Session session) async {
    try {
      await TokenStorage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      final profile = await AuthApi.me();
      state = AsyncData(AppAuthState.authenticated(profile));
    } catch (_) {
      // Leave current state untouched if hydration fails.
    }
  }

  String _formatError(Object e) {
    if (e is AppException) {
      // Surface the NestJS envelope's `message` verbatim.
      return e.message;
    }
    return 'Something went wrong. Please try again.';
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AppAuthState>(
  AuthNotifier.new,
);
