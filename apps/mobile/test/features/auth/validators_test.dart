import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ideal_app/core/utils/validators.dart';

/// Validators now take a [BuildContext] so their messages can be localized.
/// `context.l10n` falls back to English even without a Localizations ancestor,
/// so any pumped context works here; these tests still assert the validation
/// logic (null vs non-null), not the exact message text.
void main() {
  late BuildContext context;

  Future<void> pumpContext(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  group('Validators.email', () {
    testWidgets('returns error for empty email', (tester) async {
      await pumpContext(tester);
      expect(Validators.email(context, ''), isNotNull);
      expect(Validators.email(context, null), isNotNull);
    });

    testWidgets('returns error for invalid email format', (tester) async {
      await pumpContext(tester);
      expect(Validators.email(context, 'notanemail'), isNotNull);
      expect(Validators.email(context, 'missing@domain'), isNotNull);
      expect(Validators.email(context, '@nodomain.com'), isNotNull);
    });

    testWidgets('returns null for valid email', (tester) async {
      await pumpContext(tester);
      expect(Validators.email(context, 'user@example.com'), isNull);
      expect(Validators.email(context, 'user.name+tag@domain.co'), isNull);
    });
  });

  group('Validators.password', () {
    testWidgets('returns error for empty password', (tester) async {
      await pumpContext(tester);
      expect(Validators.password(context, ''), isNotNull);
      expect(Validators.password(context, null), isNotNull);
    });

    testWidgets('returns error for password shorter than 8 characters',
        (tester) async {
      await pumpContext(tester);
      expect(Validators.password(context, 'short'), isNotNull);
      expect(Validators.password(context, '1234567'), isNotNull);
    });

    testWidgets('returns null for valid password', (tester) async {
      await pumpContext(tester);
      expect(Validators.password(context, 'password123'), isNull);
      expect(Validators.password(context, '12345678'), isNull);
    });
  });

  group('Validators.fullName', () {
    testWidgets('returns error for empty name', (tester) async {
      await pumpContext(tester);
      expect(Validators.fullName(context, ''), isNotNull);
      expect(Validators.fullName(context, null), isNotNull);
    });

    testWidgets('returns error for single character', (tester) async {
      await pumpContext(tester);
      expect(Validators.fullName(context, 'A'), isNotNull);
    });

    testWidgets('returns null for valid full name', (tester) async {
      await pumpContext(tester);
      expect(Validators.fullName(context, 'John Doe'), isNull);
      expect(Validators.fullName(context, 'Ra'), isNull);
    });
  });

  group('Validators.otp', () {
    testWidgets('returns error for empty OTP', (tester) async {
      await pumpContext(tester);
      expect(Validators.otp(context, ''), isNotNull);
      expect(Validators.otp(context, null), isNotNull);
    });

    testWidgets('returns error for OTP not 6 digits', (tester) async {
      await pumpContext(tester);
      expect(Validators.otp(context, '12345'), isNotNull);
      expect(Validators.otp(context, '1234567'), isNotNull);
      expect(Validators.otp(context, 'abcdef'), isNotNull);
    });

    testWidgets('returns null for valid 6-digit OTP', (tester) async {
      await pumpContext(tester);
      expect(Validators.otp(context, '123456'), isNull);
      expect(Validators.otp(context, '000000'), isNull);
    });
  });
}
