import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/auth_provider.dart';
import '../domain/auth_state.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/ideal_ui.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String _accountType = 'Individual';
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.tr('register.acceptTerms')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final email = _emailController.text.trim();
    // On success the provider emits `authenticated` and the ref.listen below
    // navigates straight to home — no OTP step. Errors surface via the listener.
    await ref
        .read(authProvider.notifier)
        .signUp(
          email: email,
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
        );
  }

  Future<void> _registerWithGoogle() async {
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
        return;
      }
      if (state?.status == AuthStatus.error && state?.errorMessage != null) {
        final message = state!.errorMessage!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
            action: message.contains('already exists')
                ? SnackBarAction(
                    label: context.l10n.tr('register.signInAction'),
                    textColor: Colors.white,
                    onPressed: () => context.go(AppRoutes.login),
                  )
                : null,
          ),
        );
      }
    });

    final l10n = context.l10n;
    return AuthShell(
      title: l10n.tr('register.title'),
      subtitle: l10n.tr('register.subtitle'),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _FieldLabel(l10n.tr('register.fullName')),
            TextFormField(
              controller: _nameController,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: l10n.tr('register.fullNameHint'),
                prefixIcon: const Icon(Icons.person_outlined),
              ),
              validator: (v) => Validators.fullName(context, v),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            _FieldLabel(l10n.tr('auth.password')),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: l10n.tr('register.passwordHint'),
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
            const SizedBox(height: 16),
            _FieldLabel(l10n.tr('register.confirmPassword')),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _register(),
              decoration: InputDecoration(
                hintText: l10n.tr('register.confirmHint'),
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (value) {
                final passwordError = Validators.password(context, value);
                if (passwordError != null) return passwordError;
                if (value != _passwordController.text) {
                  return l10n.tr('validation.passwordsNoMatch');
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _FieldLabel(l10n.tr('register.accountType')),
            DropdownButtonFormField<String>(
              initialValue: _accountType,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.business_center_outlined),
              ),
              items: [
                DropdownMenuItem(
                  value: 'Individual',
                  child: Text(l10n.tr('register.individual')),
                ),
                DropdownMenuItem(
                  value: 'Company',
                  child: Text(l10n.tr('register.company')),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _accountType = value);
              },
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _agreeToTerms,
                  onChanged: (value) =>
                      setState(() => _agreeToTerms = value ?? false),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      l10n.tr('register.agree'),
                      style: const TextStyle(fontSize: 12, height: 1.35),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _register,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.tr('register.create')),
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
                label: Text(l10n.tr('register.google')),
                onPressed: isLoading ? null : _registerWithGoogle,
              ),
            ),
            const SizedBox(height: 22),
            Center(
              child: TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: Text.rich(
                  TextSpan(
                    text: l10n.tr('register.haveAccount'),
                    style: TextStyle(color: AppColors.textSecondary),
                    children: [
                      TextSpan(
                        text: l10n.tr('register.signInLink'),
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
