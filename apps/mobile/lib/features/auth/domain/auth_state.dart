import 'auth_profile.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
  passwordRecovery,
}

class AppAuthState {
  final AuthStatus status;
  final AuthProfile? profile;
  final String? errorMessage;

  const AppAuthState({
    required this.status,
    this.profile,
    this.errorMessage,
  });

  factory AppAuthState.initial() =>
      const AppAuthState(status: AuthStatus.initial);

  factory AppAuthState.loading() =>
      const AppAuthState(status: AuthStatus.loading);

  factory AppAuthState.unauthenticated() =>
      const AppAuthState(status: AuthStatus.unauthenticated);

  factory AppAuthState.authenticated(AuthProfile profile) =>
      AppAuthState(status: AuthStatus.authenticated, profile: profile);

  /// No payload needed: the email for the reset screen already travels
  /// via the route's `extra`, and there's no NestJS profile yet at this point.
  factory AppAuthState.passwordRecovery() =>
      const AppAuthState(status: AuthStatus.passwordRecovery);

  factory AppAuthState.error(String message) =>
      AppAuthState(status: AuthStatus.error, errorMessage: message);

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;
}