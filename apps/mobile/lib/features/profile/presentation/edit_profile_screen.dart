import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/ideal_ui.dart';
import '../../auth/domain/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _displayNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _avatarUrlController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref
        .read(authProvider)
        .whenOrNull(data: (s) => s.profile);
    _displayNameController = TextEditingController(
      text: profile?.displayName ?? '',
    );
    _usernameController = TextEditingController(text: profile?.username ?? '');
    _avatarUrlController = TextEditingController(text: profile?.avatarUrl ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final avatarUrl = _avatarUrlController.text.trim();
    final username = _usernameController.text.trim();
    final error = await ref
        .read(authProvider.notifier)
        .updateProfile(
          displayName: _displayNameController.text.trim(),
          username: username.isEmpty ? null : username,
          avatarUrl: avatarUrl.isEmpty ? null : avatarUrl,
        );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.tr('profile.updated')),
        backgroundColor: AppColors.success,
      ),
    );
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authProvider).whenOrNull(data: (s) => s.profile);

    return IdealAppScaffold(
      activeRoute: 'profile',
      showBack: true,
      body: IdealGradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: FadeSlideIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go(AppRoutes.home),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SectionTitle(
                            title: context.l10n.tr('profile.title'),
                            subtitle: context.l10n.tr('profile.subtitle'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    IdealCard(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: _AvatarPreview(
                                url: _avatarUrlController.text.trim(),
                                fallback:
                                    profile?.displayNameOrEmail ?? '?',
                              ),
                            ),
                            const SizedBox(height: 24),
                            FieldLabel(context.l10n.tr('profile.displayName')),
                            TextFormField(
                              controller: _displayNameController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText:
                                    context.l10n.tr('profile.displayNameHint'),
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              validator: (v) => Validators.fullName(context, v),
                            ),
                            const SizedBox(height: 18),
                            FieldLabel(context.l10n.tr('profile.username')),
                            TextFormField(
                              controller: _usernameController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: context.l10n.tr('profile.usernameHint'),
                                prefixIcon: const Icon(Icons.alternate_email),
                                helperText:
                                    context.l10n.tr('profile.usernameHelper'),
                              ),
                              validator: _validateUsername,
                            ),
                            const SizedBox(height: 18),
                            FieldLabel(context.l10n.tr('profile.avatarUrl')),
                            TextFormField(
                              controller: _avatarUrlController,
                              keyboardType: TextInputType.url,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: context.l10n.tr('profile.avatarHint'),
                                prefixIcon: const Icon(Icons.image_outlined),
                              ),
                              validator: _validateAvatarUrl,
                            ),
                            const SizedBox(height: 18),
                            FieldLabel(context.l10n.tr('profile.email')),
                            TextFormField(
                              initialValue: profile?.email ?? '',
                              readOnly: true,
                              enabled: false,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.alternate_email),
                                helperText:
                                    context.l10n.tr('profile.emailHelper'),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _ReadOnlyRow(
                              icon: Icons.verified_user_outlined,
                              label: context.l10n
                                  .tr('profile.identityVerification'),
                              value: _kycLabel(context, profile?.kycStatus),
                            ),
                            const SizedBox(height: 26),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isSaving
                                        ? null
                                        : () => context.go(AppRoutes.home),
                                    child: Text(context.l10n.tr('common.cancel')),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isSaving ? null : _save,
                                    child: _isSaving
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(context.l10n
                                            .tr('profile.saveChanges')),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Optional; must match the backend rule (3-30 letters/digits/underscore).
  String? _validateUsername(String? value) {
    final username = value?.trim() ?? '';
    if (username.isEmpty) return null;
    if (username.length < 3 || username.length > 30) {
      return context.l10n.tr('validation.usernameLength');
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return context.l10n.tr('validation.usernameChars');
    }
    return null;
  }

  /// Optional, but the backend rejects anything that is not an absolute URL.
  String? _validateAvatarUrl(String? value) {
    final url = value?.trim() ?? '';
    if (url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.isAbsolute) {
      return context.l10n.tr('validation.urlFull');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return context.l10n.tr('validation.urlScheme');
    }
    return null;
  }
}

String _kycLabel(BuildContext context, String? status) => switch (status) {
  'APPROVED' => context.l10n.tr('kycProfile.approved'),
  'SUBMITTED' => context.l10n.tr('kycProfile.submitted'),
  'UNDER_REVIEW' => context.l10n.tr('kycProfile.underReview'),
  'REJECTED' => context.l10n.tr('kycProfile.rejected'),
  'RESUBMISSION_REQUIRED' => context.l10n.tr('kycProfile.resubmission'),
  'REVOKED' => context.l10n.tr('kycProfile.revoked'),
  _ => context.l10n.tr('kycProfile.notStarted'),
};

class _AvatarPreview extends StatelessWidget {
  final String url;
  final String fallback;

  const _AvatarPreview({required this.url, required this.fallback});

  @override
  Widget build(BuildContext context) {
    final initial = fallback.isEmpty ? '?' : fallback[0].toUpperCase();
    final valid = Uri.tryParse(url)?.isAbsolute ?? false;

    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.12),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: valid
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _Initial(initial: initial),
            )
          : _Initial(initial: initial),
    );
  }
}

class _Initial extends StatelessWidget {
  final String initial;

  const _Initial({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReadOnlyRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
