class RateLimiter {
  RateLimiter({
    required this.maxAttempts,
    required this.windowDuration,
    required this.lockoutDuration,
  });

  final int maxAttempts;
  final Duration windowDuration;
  final Duration lockoutDuration;

  final List<DateTime> _attempts = [];
  DateTime? _lockedUntil;

  bool get isAllowed {
    _cleanup();
    if (_lockedUntil != null && DateTime.now().isBefore(_lockedUntil!)) {
      return false;
    }
    if (_lockedUntil != null && DateTime.now().isAfter(_lockedUntil!)) {
      _lockedUntil = null;
      _attempts.clear();
    }
    return _attempts.length < maxAttempts;
  }

  void recordFailure() {
    _cleanup();
    _attempts.add(DateTime.now());
    if (_attempts.length >= maxAttempts) {
      _lockedUntil = DateTime.now().add(lockoutDuration);
    }
  }

  void recordSuccess() {
    _attempts.clear();
    _lockedUntil = null;
  }

  Duration? get remainingLockout {
    if (_lockedUntil == null) return null;
    final remaining = _lockedUntil!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  String? get lockoutMessage {
    final remaining = remainingLockout;
    if (remaining == null) return null;
    final seconds = remaining.inSeconds;
    if (seconds < 60) return 'Try again in $seconds seconds';
    return 'Try again in ${remaining.inMinutes} minutes';
  }

  void _cleanup() {
    final cutoff = DateTime.now().subtract(windowDuration);
    _attempts.removeWhere((t) => t.isBefore(cutoff));
  }

  void reset() {
    _attempts.clear();
    _lockedUntil = null;
  }
}

class AuthRateLimiters {
  AuthRateLimiters._();

  static final login = RateLimiter(
    maxAttempts: 5,
    windowDuration: const Duration(minutes: 15),
    lockoutDuration: const Duration(minutes: 30),
  );

  static final signup = RateLimiter(
    maxAttempts: 3,
    windowDuration: const Duration(minutes: 10),
    lockoutDuration: const Duration(minutes: 15),
  );

  static final passwordReset = RateLimiter(
    maxAttempts: 3,
    windowDuration: const Duration(hours: 1),
    lockoutDuration: const Duration(hours: 1),
  );

  static final otpVerify = RateLimiter(
    maxAttempts: 5,
    windowDuration: const Duration(minutes: 10),
    lockoutDuration: const Duration(minutes: 15),
  );
}