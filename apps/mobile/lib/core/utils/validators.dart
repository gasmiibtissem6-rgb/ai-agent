import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

/// Form field validators. Each takes the current [BuildContext] so the returned
/// message is localized in the active language.
class Validators {
  const Validators._();

  static String? email(BuildContext context, String? value) {
    final l10n = context.l10n;
    if (value == null || value.trim().isEmpty) {
      return l10n.tr('validation.emailRequired');
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return l10n.tr('validation.emailInvalid');
    }
    return null;
  }

  static String? password(BuildContext context, String? value) {
    final l10n = context.l10n;
    if (value == null || value.isEmpty) {
      return l10n.tr('validation.passwordRequired');
    }
    if (value.length < 8) return l10n.tr('validation.passwordShort');
    return null;
  }

  static String? fullName(BuildContext context, String? value) {
    final l10n = context.l10n;
    if (value == null || value.trim().isEmpty) {
      return l10n.tr('validation.fullNameRequired');
    }
    if (value.trim().length < 2) return l10n.tr('validation.fullNameShort');
    return null;
  }

  static String? otp(BuildContext context, String? value) {
    final l10n = context.l10n;
    if (value == null || value.trim().isEmpty) {
      return l10n.tr('validation.otpRequired');
    }
    if (value.trim().length != 6) return l10n.tr('validation.otpLength');
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return l10n.tr('validation.otpDigits');
    }
    return null;
  }

  static String? required(
    BuildContext context,
    String? value, {
    String field = 'This field',
  }) {
    if (value == null || value.trim().isEmpty) {
      return context.l10n.trp('validation.fieldRequired', {'field': field});
    }
    return null;
  }
}
