import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
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
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return IdealAppScaffold(
      activeRoute: 'settings',
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.surface, AppColors.surfaceAlt],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage your preferences and account security',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _SettingsCard(
              title: 'General Settings',
              icon: Icons.language,
              children: [
                const _FieldLabel('Language'),
                DropdownButtonFormField<String>(
                  initialValue: _language,
                  items: const ['English', 'French', 'Arabic', 'Spanish']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _language = value);
                  },
                ),
                const SizedBox(height: 20),
                const _FieldLabel('Theme Mode'),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Light Mode'),
                      icon: Icon(Icons.wb_sunny),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Dark Mode'),
                      icon: Icon(Icons.nightlight_round),
                    ),
                  ],
                  selected: const {true},
                  onSelectionChanged: (_) => _comingSoon(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsCard(
              title: 'Notifications',
              icon: Icons.notifications,
              children: [
                _SwitchRow(
                  title: 'Push Notifications',
                  subtitle: 'Receive notifications for deal updates',
                  value: _pushNotifications,
                  onChanged: (value) =>
                      setState(() => _pushNotifications = value),
                ),
                const Divider(),
                _SwitchRow(
                  title: 'Email Updates',
                  subtitle: 'Receive email notifications',
                  value: _emailUpdates,
                  onChanged: (value) => setState(() => _emailUpdates = value),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsCard(
              title: 'Security',
              icon: Icons.lock,
              children: [
                _SwitchRow(
                  title: 'Two-Factor Authentication',
                  subtitle: 'Add an extra layer of security',
                  value: _twoFactor,
                  onChanged: (value) => setState(() => _twoFactor = value),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Change Password'),
                  subtitle: const Text('Update your password'),
                  trailing: ElevatedButton(
                    onPressed: () => _comingSoon(context),
                    child: const Text('Change'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsCard(
              title: 'Account Management',
              icon: Icons.person_outline,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _comingSoon(context),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active Sessions'),
                  subtitle: const Text('View signed-in devices'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _comingSoon(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsCard(
              title: 'Privacy',
              icon: Icons.security,
              children: [
                _SwitchRow(
                  title: 'Public Profile',
                  subtitle: 'Make your profile visible to others',
                  value: _publicProfile,
                  onChanged: (value) => setState(() => _publicProfile = value),
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
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.error),
                      SizedBox(width: 8),
                      Text(
                        'Danger Zone',
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
                      onPressed: () =>
                          ref.read(authProvider.notifier).signOut(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Log Out'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _comingSoon(context),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Delete Account'),
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
      const SnackBar(content: Text('This feature is still being built.')),
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
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
    );
  }
}
