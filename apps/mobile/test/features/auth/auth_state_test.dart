import 'package:flutter_test/flutter_test.dart';
import 'package:ideal_app/features/auth/domain/auth_state.dart';

void main() {
  group('AppAuthState', () {
    test('creates unauthenticated state', () {
      final state = AppAuthState.unauthenticated();

      expect(state.status, AuthStatus.unauthenticated);
      expect(state.isAuthenticated, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.hasError, isFalse);
    });

    test('creates loading and error states', () {
      expect(AppAuthState.loading().isLoading, isTrue);

      final error = AppAuthState.error('Nope');
      expect(error.hasError, isTrue);
      expect(error.errorMessage, 'Nope');
    });
  });
}
