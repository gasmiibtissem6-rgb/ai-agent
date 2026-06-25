class Validators {
  const Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required.';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required.';
    if (value.trim().length < 2) return 'Enter your full name.';
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.trim().isEmpty) return 'Verification code is required.';
    if (value.trim().length != 6) return 'Enter the 6-digit code.';
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) return 'Code must be 6 digits.';
    return null;
  }

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    return null;
  }
}
