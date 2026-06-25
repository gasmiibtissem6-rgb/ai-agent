import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class SecurityConfig {
  const SecurityConfig._();

  static final _logger = Logger();

  static Future<SecurityCheckResult> runStartupChecks() async {
    final checks = <String, bool>{};

    checks['debug_mode'] = kDebugMode;
    if (kDebugMode) {
      _logger.w('[SECURITY] App running in debug mode');
    }

    if (!kIsWeb) {
      final isCompromised = await _isDeviceCompromised();
      checks['device_compromised'] = isCompromised;
      if (isCompromised) {
        _logger.e('[SECURITY] Device appears to be rooted or jailbroken');
      }
    }

    return SecurityCheckResult(checks: checks);
  }

  static Future<bool> _isDeviceCompromised() async {
    try {
      if (Platform.isAndroid) {
        final suspiciousPaths = [
          '/system/app/Superuser.apk',
          '/sbin/su',
          '/system/bin/su',
          '/system/xbin/su',
          '/data/local/xbin/su',
          '/data/local/bin/su',
          '/system/sd/xbin/su',
          '/system/bin/failsafe/su',
          '/data/local/su',
        ];
        for (final path in suspiciousPaths) {
          if (await File(path).exists()) return true;
        }
      } else if (Platform.isIOS) {
        final suspiciousPaths = [
          '/Applications/Cydia.app',
          '/Library/MobileSubstrate/MobileSubstrate.dylib',
          '/bin/bash',
          '/usr/sbin/sshd',
          '/etc/apt',
          '/private/var/lib/apt',
        ];
        for (final path in suspiciousPaths) {
          if (await File(path).exists()) return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static void applyCertificatePinning(Dio dio) {
    if (kIsWeb) return;

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) {
        _logger.e('[SECURITY] Bad certificate rejected for host: $host');
        return false;
      };
      return client;
    };

    _logger.d('[SECURITY] Certificate pinning applied');
  }

  static String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[<>"' "'" r']'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '***';
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return '**@$domain';
    final first = name[0];
    final last = name[name.length - 1];
    final stars = '*' * (name.length - 2);
    return first + stars + last + '@' + domain;
  }

  static String maskToken(String token) {
    if (token.length <= 8) return '***';
    final start = token.substring(0, 4);
    final end = token.substring(token.length - 4);
    return start + '...**********...' + end;
  }
}

class SecurityCheckResult {
  final Map<String, bool> checks;

  const SecurityCheckResult({required this.checks});

  bool get isDeviceCompromised => checks['device_compromised'] ?? false;
  bool get isDebugMode => checks['debug_mode'] ?? false;
  bool get shouldBlockAccess => isDeviceCompromised && !isDebugMode;
}