import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/auth_provider.dart';
import '../domain/auth_state.dart';
import '../../../core/router/app_router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final success = await ref.read(authProvider.notifier).signUp(
          email: email,
          password: _passwordController.text.trim(),
          fullName: _nameController.text.trim(),
        );
    if (success && mounted) {
      context.go(AppRoutes.otp, extra: email);
    }
  }
  

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authProvider);
    final authState = authAsync.when(
      data: (data) => data,
      loading: () => null,
      error: (_, __) => null,
    );
    final status = authState?.status;

    ref.listen(authProvider, (_, next) {
      final state = next.when(
        data: (data) => data,
        loading: () => null,
        error: (_, __) => null,
      );
      if (state?.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state?.errorMessage ?? 'Signup failed')),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Create account',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: status == AuthStatus.loading ? null : _register,
                  child: status == AuthStatus.loading
                      ? const CircularProgressIndicator()
                      : const Text('Sign up'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Already have an account? Login'),
              ),
              const SizedBox(height: 12),
const Row(
  children: [
    Expanded(child: Divider()),
    Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Text('or', style: TextStyle(color: Colors.grey)),
    ),
    Expanded(child: Divider()),
  ],
),
const SizedBox(height: 12),
SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    icon: const Icon(Icons.g_mobiledata, size: 28),
    label: const Text('Sign up with Google'),
    onPressed: status == AuthStatus.loading
        ? null
        : () async {
            await ref.read(authProvider.notifier).signInWithGoogle();
          },
  ),
),
            ],
          ),
        ),
      ),
    );
  }
}