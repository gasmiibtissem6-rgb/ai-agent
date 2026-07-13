import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/domain/auth_profile.dart';
import '../../auth/domain/auth_provider.dart';
import '../../profile/presentation/qr_scan_screen.dart';
import '../domain/deal_model.dart';
import '../domain/deal_provider.dart';
import 'deal_status_ui.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/theme_toggle_button.dart';
import '../../../services/profile_service.dart';
import '../../../shared/ideal_ui.dart';
import '../../../shared/qr_display.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The theme toggle lives in this screen's header. AppColors resolves
    // against the current mode at build time, so the screen must rebuild in
    // place when the theme flips (as the old Settings-hosted toggle did).
    ref.watch(themeProvider);
    final authState = ref
        .watch(authProvider)
        .whenOrNull(data: (state) => state);
    final dealState = ref
        .watch(dealProvider)
        .whenOrNull(data: (state) => state);
    final deals = dealState?.deals ?? const <Deal>[];
    final l10n = context.l10n;
    final displayName =
        authState?.profile?.displayNameOrEmail ?? l10n.tr('home.there');

    return IdealAppScaffold(
      activeRoute: 'home',
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_outlined),
          tooltip: l10n.tr('home.signOut'),
          onPressed: () async {
            await ref.read(authProvider.notifier).signOut();
          },
        ),
        // Profile now lives here (top-right), replacing the old "Delete account".
        IconButton(
          icon: const Icon(Icons.person_outline),
          tooltip: l10n.tr('home.profile'),
          onPressed: () => context.go(AppRoutes.editProfile),
        ),
        // Theme toggle sits in the top-right corner of the Home page header.
        const ThemeToggleButton(),
      ],
      body: IdealGradientBackground(
        child: RefreshIndicator(
          onRefresh: () => ref.read(dealProvider.notifier).loadDeals(),
          child: Center(
            child: ConstrainedBox(
              // Keeps cards and sections readable on tablets and desktops;
              // narrower screens are unaffected (same cap as the deals list).
              constraints: const BoxConstraints(maxWidth: 860),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                children: [
                  FadeSlideIn(
                    child: SectionTitle(
                      title: l10n.trp('home.welcome', {'name': displayName}),
                      subtitle: l10n.tr('home.welcomeSub'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (authState?.profile != null)
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: _ProfileSection(profile: authState!.profile!),
                    ),
                  if (authState?.profile != null) const SizedBox(height: 24),
                  _StatsGrid(deals: deals),
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 220),
                    child: _QuickActions(
                      onCreate: () => context.go(AppRoutes.dealCreateStart),
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
                        l10n.tr('home.recentDeals'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.deals),
                        child: Text(l10n.tr('home.viewAll')),
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
                            child: Icon(
                              Icons.handshake_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              l10n.tr('home.emptyRecent'),
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

/// Home profile card: avatar, name, verification emoji, public/private toggle,
/// the user's own profile QR, and a scanner for another user's profile QR.
class _ProfileSection extends ConsumerStatefulWidget {
  final AuthProfile profile;

  const _ProfileSection({required this.profile});

  @override
  ConsumerState<_ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends ConsumerState<_ProfileSection> {
  bool _busy = false;

  Future<void> _togglePublic(bool value) async {
    setState(() => _busy = true);
    final error = await ref
        .read(authProvider.notifier)
        .updateProfile(isPublic: value);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _scanProfile() async {
    final payload = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => QrScanScreen(title: context.l10n.tr('home.scanProfileTitle')),
      ),
    );
    if (payload == null || !mounted) return;

    final query = _extractProfileQuery(payload);
    if (query == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tr('home.notIdealQr'))),
      );
      return;
    }

    setState(() => _busy = true);
    final found = await ProfileService.lookup(query);
    if (!mounted) return;
    setState(() => _busy = false);
    _showScanResult(found);
  }

  /// Parses `ideal://profile/<handle>` or `ideal://profile/id/<uuid>`.
  String? _extractProfileQuery(String payload) {
    final value = payload.trim();
    const prefix = 'ideal://profile/';
    if (!value.startsWith(prefix)) return null;
    var rest = value.substring(prefix.length);
    if (rest.startsWith('id/')) rest = rest.substring(3);
    return rest.isEmpty ? null : rest;
  }

  void _showScanResult(AuthProfile? profile) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (profile == null) ...[
              Icon(
                Icons.person_off_outlined,
                size: 40,
                color: AppColors.warning,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.tr('home.profileNotFound'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.tr('home.profilePrivate'),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ] else ...[
              _ProfileAvatar(profile: profile, size: 64),
              const SizedBox(height: 12),
              Text(
                '${profile.displayNameOrEmail} ${profile.verifiedEmoji}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                profile.handleOrName,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                profile.isKycVerified
                    ? context.l10n.tr('home.verifiedAccount')
                    : context.l10n.tr('home.notVerifiedYet'),
                style: TextStyle(
                  color: profile.isKycVerified
                      ? AppColors.success
                      : AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.tr('common.close')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return IdealCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ProfileAvatar(profile: profile, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            profile.displayNameOrEmail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          profile.verifiedEmoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.handleOrName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatusPill(
                      label: profile.isKycVerified
                          ? context.l10n.tr('home.kycVerified')
                          : context.l10n.tr('home.notVerified'),
                      color: profile.isKycVerified
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                profile.isPublic ? Icons.public : Icons.lock_outline,
                size: 20,
                color: profile.isPublic
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.isPublic
                          ? context.l10n.tr('home.publicProfile')
                          : context.l10n.tr('home.privateProfile'),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      profile.isPublic
                          ? context.l10n.tr('home.publicSub')
                          : context.l10n.tr('home.privateSub'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_busy)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Switch(value: profile.isPublic, onChanged: _togglePublic),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: QrDisplay(
              data: profile.qrPayload,
              size: 160,
              caption: context.l10n.tr('home.qrCaption'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _scanProfile,
              icon: const Icon(Icons.qr_code_scanner_outlined),
              label: Text(context.l10n.tr('home.scanAnother')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final AuthProfile profile;
  final double size;

  const _ProfileAvatar({required this.profile, required this.size});

  @override
  Widget build(BuildContext context) {
    final url = profile.avatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        backgroundImage: NetworkImage(url),
      );
    }
    final label = profile.displayNameOrEmail;
    final initial = (label.isEmpty ? '?' : label.substring(0, 1)).toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
        ),
      ),
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

    final l10n = context.l10n;
    final items = [
      _StatItem(
        l10n.tr('home.statSuccessful'),
        successfulDeals.toString(),
        Icons.check_circle_outline,
        [const Color(0xFF34D399), AppColors.success],
      ),
      _StatItem(
        l10n.tr('home.statBridged'),
        bridgedDeals.toString(),
        Icons.compare_arrows_outlined,
        const [Color(0xFF38BDF8), AppColors.accent],
      ),
      _StatItem(
        l10n.tr('home.statActive'),
        activeDeals.toString(),
        Icons.insights_outlined,
        [AppColors.accent, AppColors.primary],
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
        final l10n = context.l10n;
        final createPanel = _ActionPanel(
          title: l10n.tr('home.createDeal'),
          subtitle: l10n.tr('home.createDealSub'),
          icon: Icons.add_circle_outline,
          onTap: onCreate,
          primary: true,
        );
        final dealsPanel = _ActionPanel(
          title: l10n.tr('home.viewDeals'),
          subtitle: l10n.tr('home.viewDealsSub'),
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
    final l10n = context.l10n;
    final actions = [
      _MiniAction(
        l10n.tr('home.miniIdentity'),
        Icons.verified_user_outlined,
        onIdentity,
      ),
      _MiniAction(l10n.tr('nav.deals'), Icons.handshake_outlined, onDeals),
      _MiniAction(
        l10n.tr('nav.documents'),
        Icons.description_outlined,
        onDocuments,
      ),
      _MiniAction(
        l10n.tr('home.miniApprovals'),
        Icons.task_alt_outlined,
        onApprovals,
      ),
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
            StatusPill(label: dealStatusLabel(context, deal.status), color: color),
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
