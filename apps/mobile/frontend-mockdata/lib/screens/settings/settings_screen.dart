import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/responsive_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailUpdates = true;
  bool _twoFactor = true;
  bool _publicProfile = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final appProvider = Provider.of<AppProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final List<String> languages = ['English', 'French', 'Arabic', 'Spanish'];
    final currentLanguage = appProvider.language == 'en' 
        ? 'English' 
        : (appProvider.language == 'fr' ? 'French' : 'Arabic');

    return ResponsiveScaffold(
      activeRoute: 'settings',
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                : [const Color(0xFFF8FAFC), const Color(0xFFEFF6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Settings',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage your preferences and account security',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // General Settings
              _buildSettingsCard(
                isDark: isDark,
                title: 'General Settings',
                icon: Icons.language,
                children: [
                  const Text('Language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: currentLanguage,
                    items: languages.map((l) {
                      return DropdownMenuItem(value: l, child: Text(l));
                    }).toList(),
                    onChanged: (val) {
                      if (val == 'English') appProvider.setLanguage('en');
                      if (val == 'French') appProvider.setLanguage('fr');
                      if (val == 'Arabic') appProvider.setLanguage('ar');
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Light Mode'), icon: Icon(Icons.wb_sunny)),
                          ButtonSegment(value: true, label: Text('Dark Mode'), icon: Icon(Icons.nightlight_round)),
                        ],
                        selected: {appProvider.isDarkMode},
                        onSelectionChanged: (Set<bool> newSelection) {
                          if (newSelection.first != appProvider.isDarkMode) {
                            appProvider.toggleTheme();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Notifications Settings
              _buildSettingsCard(
                isDark: isDark,
                title: 'Notifications',
                icon: Icons.notifications,
                children: [
                  _buildToggleRow(
                    title: 'Push Notifications',
                    subtitle: 'Receive notifications for deal updates',
                    value: _pushNotifications,
                    onChanged: (val) => setState(() => _pushNotifications = val),
                  ),
                  const Divider(),
                  _buildToggleRow(
                    title: 'Email Updates',
                    subtitle: 'Receive email notifications',
                    value: _emailUpdates,
                    onChanged: (val) => setState(() => _emailUpdates = val),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Security Settings
              _buildSettingsCard(
                isDark: isDark,
                title: 'Security',
                icon: Icons.lock,
                children: [
                  _buildToggleRow(
                    title: 'Two-Factor Authentication',
                    subtitle: 'Add an extra layer of security',
                    value: _twoFactor,
                    onChanged: (val) => setState(() => _twoFactor = val),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Update your password'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password reset email sent!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(elevation: 0),
                      child: const Text('Change'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Account settings
              _buildSettingsCard(
                isDark: isDark,
                title: 'Account Management',
                icon: Icons.person_outline,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/profile'),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active Sessions', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Viewing 1 active session (this device)')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Privacy Settings
              _buildSettingsCard(
                isDark: isDark,
                title: 'Privacy',
                icon: Icons.security,
                children: [
                  _buildToggleRow(
                    title: 'Public Profile',
                    subtitle: 'Make your profile visible to others',
                    value: _publicProfile,
                    onChanged: (val) => setState(() => _publicProfile = val),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Danger Zone Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red.shade400),
                        const SizedBox(width: 8),
                        Text(
                          'Danger Zone',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red.shade400),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          authProvider.logout();
                          context.go('/splash');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Logged out successfully!')),
                          );
                        },
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Log Out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade400,
                          side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mock account deletion requested!')),
                          );
                        },
                        icon: const Icon(Icons.delete_forever, size: 18),
                        label: const Text('Delete Account'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade400,
                          side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: Theme.of(context).primaryColor,
    );
  }
}
