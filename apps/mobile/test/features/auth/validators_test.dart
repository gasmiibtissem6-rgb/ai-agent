import 'package:flutter_test/flutter_test.dart';
import 'package:ideal_app/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('returns error for empty email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
    });

    test('returns error for invalid email format', () {
      expect(Validators.email('notanemail'), isNotNull);
      expect(Validators.email('missing@domain'), isNotNull);
      expect(Validators.email('@nodomain.com'), isNotNull);
    });

    test('returns null for valid email', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('user.name+tag@domain.co'), isNull);
    });
  });

  group('Validators.password', () {
    test('returns error for empty password', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password(null), isNotNull);
    });

    test('returns error for password shorter than 8 characters', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('1234567'), isNotNull);
    });

    test('returns null for valid password', () {
      expect(Validators.password('password123'), isNull);
      expect(Validators.password('12345678'), isNull);
    });
  });

  group('Validators.fullName', () {
    test('returns error for empty name', () {
      expect(Validators.fullName(''), isNotNull);
      expect(Validators.fullName(null), isNotNull);
    });

    test('returns error for single character', () {
      expect(Validators.fullName('A'), isNotNull);
    });

    test('returns null for valid full name', () {
      expect(Validators.fullName('John Doe'), isNull);
      expect(Validators.fullName('Ra'), isNull);
    });
  });

  group('Validators.otp', () {
    test('returns error for empty OTP', () {
      expect(Validators.otp(''), isNotNull);
      expect(Validators.otp(null), isNotNull);
    });

    test('returns error for OTP not 6 digits', () {
      expect(Validators.otp('12345'), isNotNull);
      expect(Validators.otp('1234567'), isNotNull);
      expect(Validators.otp('abcdef'), isNotNull);
    });

    test('returns null for valid 6-digit OTP', () {
      expect(Validators.otp('123456'), isNull);
      expect(Validators.otp('000000'), isNull);
    });
  });
}
