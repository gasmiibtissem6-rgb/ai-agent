import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/domain/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IDEAL'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_forever_outlined,
              color: AppColors.error,
            ),
            tooltip: 'Delete account',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete account'),
                  content: const Text(
                    'This will permanently delete your account and all your data. This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authProvider.notifier).deleteAccount();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/logo/ideal-logo.png',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'IDEAL',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Trusted digital deals and contracts for people, companies, and every involved party.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Your account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.handshake_outlined,
                color: AppColors.primary,
              ),
              title: const Text('My Deals'),
              subtitle: const Text('Create and manage your deals'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.go(AppRoutes.deals),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.verified_user_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Identity Verification'),
              subtitle: const Text('Verify your ID to build trust'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.go(AppRoutes.kycStatus),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Main areas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _AreaCard(icon: Icons.people_outline, title: 'Users', description: 'Create accounts, manage profiles, and join deals.'),
          _AreaCard(icon: Icons.verified_user_outlined, title: 'Identity', description: 'Build trust with identity verification flows.'),
          _AreaCard(icon: Icons.handshake_outlined, title: 'Deals', description: 'Create agreements, invite parties, and negotiate terms.'),
          _AreaCard(icon: Icons.description_outlined, title: 'Contracts', description: 'Keep approved deal versions locked and official.'),
          _AreaCard(icon: Icons.check_circle_outline, title: 'Approvals', description: 'Confirm that every required party accepts the same version.'),
          _AreaCard(icon: Icons.notifications_outlined, title: 'Notifications', description: 'Stay updated on invitations, approvals, and changes.'),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _AreaCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
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
}