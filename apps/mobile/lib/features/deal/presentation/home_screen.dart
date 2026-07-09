import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/domain/auth_provider.dart';
import '../domain/deal_model.dart';
import '../domain/deal_provider.dart';
import 'deal_status_ui.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/ideal_ui.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref
        .watch(authProvider)
        .whenOrNull(data: (state) => state);
    final dealState = ref
        .watch(dealProvider)
        .whenOrNull(data: (state) => state);
    final deals = dealState?.deals ?? const <Deal>[];
    final displayName = authState?.profile?.displayNameOrEmail ?? 'there';

    return IdealAppScaffold(
      activeRoute: 'home',
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_outlined),
          tooltip: 'Sign out',
          onPressed: () async {
            await ref.read(authProvider.notifier).signOut();
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_forever_outlined),
          color: AppColors.error,
          tooltip: 'Delete account',
          onPressed: () => _confirmDeleteAccount(context, ref),
        ),
      ],
      body: IdealGradientBackground(
        child: RefreshIndicator(
          onRefresh: () => ref.read(dealProvider.notifier).loadDeals(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
            children: [
              FadeSlideIn(
                child: SectionTitle(
                  title: 'Welcome back, $displayName',
                  subtitle: "Here's what's happening with your deals today.",
                ),
              ),
              const SizedBox(height: 24),
              _StatsGrid(deals: deals),
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: const Duration(milliseconds: 220),
                child: _QuickActions(
                  onCreate: () => context.go(AppRoutes.createDeal),
                  onDeals: () => context.go(AppRoutes.deals),
                ),
              ),
              const SizedBox(height: 24),
              FadeSlideIn(
                delay: const Duration(milliseconds: 280),
                child: _ActionGrid(
                  onIdentity: () => context.go(AppRoutes.kycStatus),
                  onDeals: () => context.go(AppRoutes.deals),
                  onDocuments: () => context.go(AppRoutes.documents),
                  onApprovals: () => _comingSoon(context),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Deals',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.deals),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (deals.isEmpty)
                IdealCard(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.handshake_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Create your first deal to start tracking agreements.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...deals
                    .take(4)
                    .map(
                      (deal) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RecentDealTile(
                          deal: deal,
                          onTap: () =>
                              context.go(AppRoutes.dealDetail, extra: deal),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
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
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authProvider.notifier).deleteAccount();
    }
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This feature is still being built.')),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final List<Deal> deals;

  const _StatsGrid({required this.deals});

  @override
  Widget build(BuildContext context) {
    final successfulDeals = deals
        .where(
          (deal) =>
              deal.status == DealStatus.approved ||
              deal.status == DealStatus.locked,
        )
        .length;
    // "Bridged" is the product label for the NEGOTIATION wire status.
    final bridgedDeals = deals
        .where((deal) => deal.status == DealStatus.negotiation)
        .length;
    const closedStatuses = {
      DealStatus.rejected,
      DealStatus.cancelled,
      DealStatus.locked,
      DealStatus.archived,
    };
    final activeDeals = deals
        .where((deal) => !closedStatuses.contains(deal.status))
        .length;

    final items = [
      _StatItem(
        'Successful Deals',
        successfulDeals.toString(),
        Icons.check_circle_outline,
        const [Color(0xFF34D399), AppColors.success],
      ),
      _StatItem(
        'Bridged Deals',
        bridgedDeals.toString(),
        Icons.compare_arrows_outlined,
        const [Color(0xFF38BDF8), AppColors.accent],
      ),
      _StatItem(
        'Active Deals',
        activeDeals.toString(),
        Icons.insights_outlined,
        const [AppColors.accent, AppColors.primary],
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 640 ? 3 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 3.6 : 1.75,
          ),
          itemBuilder: (context, index) => FadeSlideIn(
            delay: Duration(milliseconds: 60 * index),
            child: _StatCard(item: items[index]),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatItem item;

  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return IdealCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: item.colors),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(item.icon, color: Colors.white, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.1,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onDeals;

  const _QuickActions({required this.onCreate, required this.onDeals});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 560;
        final createPanel = _ActionPanel(
          title: 'Create Deal',
          subtitle: 'Start a new agreement',
          icon: Icons.add_circle_outline,
          onTap: onCreate,
          primary: true,
        );
        final dealsPanel = _ActionPanel(
          title: 'View Deals',
          subtitle: 'Track active work',
          icon: Icons.business_center_outlined,
          onTap: onDeals,
        );
        if (stack) {
          return Column(
            children: [createPanel, const SizedBox(height: 14), dealsPanel],
          );
        }
        return Row(
          children: [
            Expanded(child: createPanel),
            const SizedBox(width: 14),
            Expanded(child: dealsPanel),
          ],
        );
      },
    );
  }
}

class _ActionPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  const _ActionPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = primary ? Colors.white : AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: primary ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primary
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: foreground, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: primary
                          ? Colors.white.withValues(alpha: 0.82)
                          : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: foreground),
          ],
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  final VoidCallback onIdentity;
  final VoidCallback onDeals;
  final VoidCallback onDocuments;
  final VoidCallback onApprovals;

  const _ActionGrid({
    required this.onIdentity,
    required this.onDeals,
    required this.onDocuments,
    required this.onApprovals,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _MiniAction('Identity', Icons.verified_user_outlined, onIdentity),
      _MiniAction('Deals', Icons.handshake_outlined, onDeals),
      _MiniAction('Documents', Icons.description_outlined, onDocuments),
      _MiniAction('Approvals', Icons.task_alt_outlined, onApprovals),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth > 700 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return InkWell(
              onTap: action.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(action.icon, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        action.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RecentDealTile extends StatelessWidget {
  final Deal deal;
  final VoidCallback onTap;

  const _RecentDealTile({required this.deal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = dealStatusColor(deal.status);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: IdealCard(
        child: Row(
          children: [
            Icon(Icons.description_outlined, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deal.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(deal.createdAt),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            StatusPill(label: deal.statusLabel, color: color),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> colors;

  const _StatItem(this.label, this.value, this.icon, this.colors);
}

class _MiniAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _MiniAction(this.label, this.icon, this.onTap);
}

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}
