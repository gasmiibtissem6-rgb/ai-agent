import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/auth_provider.dart';
import '../domain/auth_state.dart';
import '../../../core/router/app_router.dart';
import '../../../core/constants/app_colors.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _codeFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _codeVerified = false;
  int _failedAttempts = 0;
  static const _maxAttempts = 5;

  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = 30);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  Future<void> _resendCode() async {
    if (_cooldownSeconds > 0) return;
    await ref.read(authProvider.notifier).resetPassword(widget.email);
    setState(() => _failedAttempts = 0);
    _startCooldown();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new code has been sent.')),
      );
    }
  }

  Future<void> _verifyCode() async {
    if (!_codeFormKey.currentState!.validate()) return;
    if (_failedAttempts >= _maxAttempts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Too many attempts. Please request a new code.'),
        ),
      );
      return;
    }

    final ok = await ref.read(authProvider.notifier).verifyResetOtp(
          email: widget.email,
          token: _codeController.text.trim(),
        );

    if (!mounted) return;

    if (ok) {
      setState(() => _codeVerified = true);
    } else {
      setState(() => _failedAttempts++);
    }
  }

  Future<void> _submitNewPassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    final ok = await ref
        .read(authProvider.notifier)
        .confirmNewPassword(_passwordController.text);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please sign in.')),
      );
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authProvider);
    final authState = authAsync.whenOrNull(data: (s) => s);
    final isLoading = authState?.status == AuthStatus.loading;
    final errorMessage =
        authState?.status == AuthStatus.error ? authState?.errorMessage : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _codeVerified ? _buildPasswordForm(isLoading, errorMessage)
                               : _buildCodeForm(isLoading, errorMessage),
        ),
      ),
    );
  }

  Widget _buildCodeForm(bool isLoading, String? errorMessage) {
    return Form(
      key: _codeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
  'Enter the code',
  style: TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  ),
),
          const SizedBox(height: 8),
          Text(
            'We sent a 6-digit code to ${widget.email}',
            style: TextStyle(
  fontSize: 15,
  color: AppColors.textSecondary,
  height: 1.4,
),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Verification code',
              prefixIcon: Icon(Icons.pin_outlined),
              counterText: '',
            ),
            validator: (v) {
              if (v == null || v.trim().length != 6) {
                return 'Enter the 6-digit code';
              }
              return null;
            },
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(errorMessage, style: const TextStyle(color: Colors.red)),
          ],
          if (_failedAttempts > 0 && _failedAttempts < _maxAttempts) ...[
            const SizedBox(height: 8),
            Text(
              '${_maxAttempts - _failedAttempts} attempt(s) remaining',
              style: const TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : _verifyCode,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Verify code'),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _cooldownSeconds > 0 ? null : _resendCode,
              child: Text(
                _cooldownSeconds > 0
                    ? 'Resend code in ${_cooldownSeconds}s'
                    : 'Resend code',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordForm(bool isLoading, String? errorMessage) {
    return Form(
      key: _passwordFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Set a new password',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (v) {
              if (v == null || v.length < 8) {
                return 'At least 8 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm new password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (v) {
              if (v != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(errorMessage, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : _submitNewPassword,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Update password'),
          ),
        ],
      ),
    );
  }
}