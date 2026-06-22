import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading, error }

class AppAuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AppAuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AppAuthState.initial() =>
      const AppAuthState(status: AuthStatus.initial);

  factory AppAuthState.loading() =>
      const AppAuthState(status: AuthStatus.loading);

  factory AppAuthState.unauthenticated() =>
      const AppAuthState(status: AuthStatus.unauthenticated);

  factory AppAuthState.authenticated(User user) =>
      AppAuthState(status: AuthStatus.authenticated, user: user);

  factory AppAuthState.error(String message) =>
      AppAuthState(status: AuthStatus.error, errorMessage: message);

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;
}
