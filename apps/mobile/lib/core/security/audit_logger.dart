import 'package:logger/logger.dart';

enum AuditEventType {
  loginSuccess,
  loginFailure,
  loginBlocked,
  signupSuccess,
  signupFailure,
  otpVerified,
  otpFailed,
  otpBlocked,
  passwordResetRequested,
  googleLoginSuccess,
  googleLoginFailure,
  sessionExpired,
  sessionRestored,
  accountDeleted,
  accountSignedOut,
  suspiciousDeviceDetected,
  certificateError,
  apiError,
  kycSubmitted,
  dealCreated,
  dealSent,
  dealApproved,
  dealRejected,
  dealFinalized,
}

class AuditEvent {
  final AuditEventType type;
  final DateTime timestamp;
  final String? maskedEmail;
  final String? details;
  final bool isSecurityAlert;

  const AuditEvent({
    required this.type,
    required this.timestamp,
    this.maskedEmail,
    this.details,
    this.isSecurityAlert = false,
  });

  @override
  String toString() {
    return '[AUDIT] ${type.name} | ${timestamp.toIso8601String()}'
        '${maskedEmail != null ? ' | user: $maskedEmail' : ''}'
        '${details != null ? ' | $details' : ''}';
  }
}

class AuditLogger {
  AuditLogger._();

  static final _logger = Logger();
  static final List<AuditEvent> _events = [];

  static void log(
    AuditEventType type, {
    String? maskedEmail,
    String? details,
    bool isSecurityAlert = false,
  }) {
    final event = AuditEvent(
      type: type,
      timestamp: DateTime.now(),
      maskedEmail: maskedEmail,
      details: details,
      isSecurityAlert: isSecurityAlert,
    );

    _events.add(event);

    if (isSecurityAlert) {
      _logger.e(event.toString());
    } else {
      _logger.i(event.toString());
    }
  }

  static List<AuditEvent> get recentEvents => List.unmodifiable(_events);
  static List<AuditEvent> get securityAlerts =>
      _events.where((e) => e.isSecurityAlert).toList();
  static void clear() => _events.clear();
}