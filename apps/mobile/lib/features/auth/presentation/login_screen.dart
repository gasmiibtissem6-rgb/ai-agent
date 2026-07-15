import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/auth_provider.dart';
import '../domain/auth_state.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/security/rate_limiter.dart';
import '../../../shared/ideal_ui.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

final _rateLimiter = AuthRateLimiters.login;

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_rateLimiter.isAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _rateLimiter.lockoutMessage ??
                context.l10n.tr('auth.tooManyAttempts'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final email = _emailController.text.trim();
    await ref
        .read(authProvider.notifier)
        .signIn(
          email: email,
          password: _passwordController.text,
        );
    final state = ref.read(authProvider).whenOrNull(data: (s) => s);
    if (state?.status == AuthStatus.error) {
      _rateLimiter.recordFailure();
    } else {
      _rateLimiter.recordSuccess();
    }
  }

  Future<void> _loginWithGoogle() async {
    // Navigation is handled by the ref.listen below once authenticated.
    await ref.read(authProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authProvider);
    final status = authAsync.whenOrNull(data: (s) => s.status);
    final isLoading = status == AuthStatus.loading;

    ref.listen(authProvider, (_, next) {
      final state = next.whenOrNull(data: (s) => s);
      if (state?.status == AuthStatus.authenticated) {
        context.go(AppRoutes.home);
      }
      if (state?.status == AuthStatus.error && state?.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state!.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    final l10n = context.l10n;
    return AuthShell(
      title: l10n.tr('login.title'),
      subtitle: l10n.tr('login.subtitle'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _FieldLabel(l10n.tr('auth.email')),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: l10n.tr('auth.emailHint'),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (v) => Validators.email(context, v),
            ),
            const SizedBox(height: 18),
            _FieldLabel(l10n.tr('auth.password')),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _login(),
              decoration: InputDecoration(
                hintText: l10n.tr('login.passwordHint'),
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => Validators.password(context, v),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) =>
                      setState(() => _rememberMe = value ?? false),
                ),
                Expanded(
                  child: Text(
                    l10n.tr('login.rememberMe'),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.forgotPassword),
                  child: Text(l10n.tr('login.forgot')),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _login,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.tr('login.signIn')),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    l10n.tr('common.or'),
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.g_mobiledata, size: 26),
                label: Text(l10n.tr('login.google')),
                onPressed: isLoading ? null : _loginWithGoogle,
              ),
            ),
            const SizedBox(height: 22),
            Center(
              child: TextButton(
                onPressed: () => context.go(AppRoutes.register),
                child: Text.rich(
                  TextSpan(
                    text: l10n.tr('login.noAccount'),
                    style: TextStyle(color: AppColors.textSecondary),
                    children: [
                      TextSpan(
                        text: l10n.tr('login.signUpLink'),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
