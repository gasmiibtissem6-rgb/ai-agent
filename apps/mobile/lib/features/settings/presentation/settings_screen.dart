import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../features/auth/domain/auth_provider.dart';
import '../../../shared/ideal_ui.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailUpdates = true;
  bool _twoFactor = true;
  bool _publicProfile = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = ref.watch(localeProvider).languageCode;

    return IdealAppScaffold(
      activeRoute: 'settings',
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.surface, AppColors.surfaceAlt],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            Text(
              l10n.tr('settings.title'),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.tr('settings.subtitle'),
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _SettingsCard(
              title: l10n.tr('settings.general'),
              icon: Icons.language,
              children: [
                _FieldLabel(l10n.tr('settings.language')),
                DropdownButtonFormField<String>(
                  initialValue: languageCode,
                  items: AppLocalizations.supportedLocales
                      .map(
                        (locale) => DropdownMenuItem<String>(
                          value: locale.languageCode,
                          child: Text(
                            AppLocalizations.languageLabels[locale
                                    .languageCode] ??
                                locale.languageCode,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(localeProvider.notifier).setLanguage(value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsCard(
              title: l10n.tr('settings.notifications'),
              icon: Icons.notifications,
              children: [
                _SwitchRow(
                  title: l10n.tr('settings.pushNotifications'),
                  subtitle: l10n.tr('settings.pushNotificationsSub'),
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                  },
                ),
                const Divider(),
                _SwitchRow(
                  title: l10n.tr('settings.emailUpdates'),
                  subtitle: l10n.tr('settings.emailUpdatesSub'),
                  value: _emailUpdates,
                  onChanged: (value) {
                    setState(() {
                      _emailUpdates = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsCard(
              title: l10n.tr('settings.security'),
              icon: Icons.lock,
              children: [
                _SwitchRow(
                  title: l10n.tr('settings.twoFactor'),
                  subtitle: l10n.tr('settings.twoFactorSub'),
                  value: _twoFactor,
                  onChanged: (value) {
                    setState(() {
                      _twoFactor = value;
                    });
                  },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.tr('settings.changePassword')),
                  subtitle: Text(l10n.tr('settings.changePasswordSub')),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _comingSoon(context);
                    },
                    child: Text(l10n.tr('common.change')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsCard(
              title: l10n.tr('settings.account'),
              icon: Icons.person_outline,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.tr('settings.editProfile')),
                  subtitle: Text(l10n.tr('settings.editProfileSub')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.go(AppRoutes.editProfile);
                  },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.tr('settings.activeSessions')),
                  subtitle: Text(l10n.tr('settings.activeSessionsSub')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _comingSoon(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsCard(
              title: l10n.tr('settings.privacy'),
              icon: Icons.security,
              children: [
                _SwitchRow(
                  title: l10n.tr('settings.publicProfile'),
                  subtitle: l10n.tr('settings.publicProfileSub'),
                  value: _publicProfile,
                  onChanged: (value) {
                    setState(() {
                      _publicProfile = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.error),
                      const SizedBox(width: 8),
                      Text(
                        l10n.tr('settings.dangerZone'),
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref.read(authProvider.notifier).signOut();
                      },
                      icon: const Icon(Icons.logout),
                      label: Text(l10n.tr('settings.logout')),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _comingSoon(context);
                      },
                      icon: const Icon(Icons.delete_forever),
                      label: Text(l10n.tr('settings.deleteAccount')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.tr('common.comingSoon'))),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
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
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
    );
  }
}
