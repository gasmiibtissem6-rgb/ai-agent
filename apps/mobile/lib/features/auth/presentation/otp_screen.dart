import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/auth_provider.dart';
import '../domain/auth_state.dart';
import '../../../core/router/app_router.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    await ref.read(authProvider.notifier).verifyOtp(
          email: widget.email,
          token: _otpController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authProvider);
    final authState = authAsync.when(
      data: (data) => data,
      loading: () => null,
      error: (_, _) => null,
    );
    final status = authState?.status;

    ref.listen(authProvider, (_, next) {
      final state = next.when(
        data: (data) => data,
        loading: () => null,
        error: (_, _) => null,
      );
      if (state?.status == AuthStatus.authenticated) {
        context.go(AppRoutes.home);
      }
      if (state?.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state?.errorMessage ?? 'Invalid code')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_unread_outlined, size: 72, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Check your email',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'We sent a 6-digit verification code to\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 8),
                decoration: const InputDecoration(
                  labelText: 'Enter 6-digit code',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: status == AuthStatus.loading ? null : _verify,
                  child: status == AuthStatus.loading
                      ? const CircularProgressIndicator()
                      : const Text('Verify'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Back to sign up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}