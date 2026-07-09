import 'dart:async';

/// Lightweight event bus that lets the network layer signal the auth layer
/// without a direct dependency on Riverpod/router.
///
/// The 401-refresh interceptor emits [notifySignedOut] when a token refresh
/// fails (session truly expired). The auth provider listens and flips the app
/// to the unauthenticated state, which the router turns into a redirect to
/// the login screen.
class AuthSessionEvents {
  AuthSessionEvents._();

  static final AuthSessionEvents instance = AuthSessionEvents._();

  final StreamController<void> _controller = StreamController<void>.broadcast();

  /// Emits whenever the session can no longer be recovered.
  Stream<void> get onSignedOut => _controller.stream;

  void notifySignedOut() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}
