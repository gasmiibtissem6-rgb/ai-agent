import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/deal_model.dart';
import '../domain/deal_provider.dart';
import 'deal_status_ui.dart';
import '../../template/presentation/templates_section.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/ideal_ui.dart';

enum _DealsTab { deals, templates }

class DealsListScreen extends ConsumerStatefulWidget {
  const DealsListScreen({super.key});

  @override
  ConsumerState<DealsListScreen> createState() => _DealsListScreenState();
}

class _DealsListScreenState extends ConsumerState<DealsListScreen> {
  String _searchTerm = '';
  String _activeFilter = 'all';
  _DealsTab _tab = _DealsTab.deals;

  static const _filters = ['All', 'Draft', 'Bridged', 'Approved', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dealProvider.notifier).loadDeals());
  }

  @override
  Widget build(BuildContext context) {
    final dealAsync = ref.watch(dealProvider);
    final showingTemplates = _tab == _DealsTab.templates;

    return IdealAppScaffold(
      activeRoute: 'deals',
      body: IdealGradientBackground(
        child: dealAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (state) {
            if (state.isLoading && !showingTemplates) {
              return const Center(child: CircularProgressIndicator());
            }

            final filteredDeals = state.deals.where((deal) {
              final matchesFilter =
                  _activeFilter == 'all' ||
                  _filterStatus(deal.status) == _activeFilter;
              final query = _searchTerm.toLowerCase();
              final matchesSearch =
                  deal.title.toLowerCase().contains(query) ||
                  (deal.description ?? '').toLowerCase().contains(query);
              return matchesFilter && matchesSearch;
            }).toList();

            return RefreshIndicator(
              onRefresh: () => ref.read(dealProvider.notifier).loadDeals(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: [
                              _DealsHeader(
                                onCreate: () =>
                                    context.go(AppRoutes.dealCreateStart),
                              ),
                              const SizedBox(height: 26),
                              _TabSwitcher(
                                active: _tab,
                                onChanged: (tab) => setState(() => _tab = tab),
                              ),
                              const SizedBox(height: 22),
                              if (!showingTemplates) ...[
                                TextField(
                                  onChanged: (value) =>
                                      setState(() => _searchTerm = value),
                                  decoration: const InputDecoration(
                                    hintText: 'Search deals...',
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _FilterBar(
                                  filters: _filters,
                                  activeFilter: _activeFilter,
                                  onSelected: (filter) =>
                                      setState(() => _activeFilter = filter),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (showingTemplates)
                        const SliverPadding(
                          padding: EdgeInsets.fromLTRB(20, 0, 20, 28),
                          sliver: SliverToBoxAdapter(child: TemplatesSection()),
                        )
                      else if (state.deals.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyState(
                            icon: Icons.handshake_outlined,
                            title: 'No deals yet',
                            subtitle:
                                'Create your first deal to start negotiating.',
                            actionLabel: 'Create deal',
                            onAction: () =>
                                context.go(AppRoutes.dealCreateStart),
                          ),
                        )
                      else if (filteredDeals.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              'No deals found',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                          sliver: SliverList.separated(
                            itemCount: filteredDeals.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final deal = filteredDeals[index];
                              return FadeSlideIn(
                                key: ValueKey(deal.id),
                                delay: Duration(
                                  milliseconds: 40 * (index.clamp(0, 6)),
                                ),
                                child: _DealRow(
                                  deal: deal,
                                  onTap: () => context.go(
                                    AppRoutes.dealDetail,
                                    extra: deal,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Maps a wire status onto the coarse filter chips shown above the list.
  String _filterStatus(DealStatus status) => switch (status) {
    DealStatus.draft || DealStatus.changesRequested => 'draft',
    DealStatus.negotiation || DealStatus.pendingApproval => 'bridged',
    DealStatus.approved || DealStatus.locked => 'approved',
    DealStatus.rejected ||
    DealStatus.cancelled ||
    DealStatus.archived => 'cancelled',
  };
}

/// Centered title, subtitle and primary call to action.
class _DealsHeader extends StatelessWidget {
  final VoidCallback onCreate;

  const _DealsHeader({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Deals',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Manage and track all your deals',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Create Deal'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 52),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  final _DealsTab active;
  final ValueChanged<_DealsTab> onChanged;

  const _TabSwitcher({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TabButton(
              label: 'Deals',
              icon: Icons.handshake_outlined,
              selected: active == _DealsTab.deals,
              onTap: () => onChanged(_DealsTab.deals),
            ),
            const SizedBox(width: 4),
            _TabButton(
              label: 'Templates',
              icon: Icons.dashboard_customize_outlined,
              selected: active == _DealsTab.templates,
              onTap: () => onChanged(_DealsTab.templates),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final List<String> filters;
  final String activeFilter;
  final ValueChanged<String> onSelected;

  const _FilterBar({
    required this.filters,
    required this.activeFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters) ...[
            _FilterButton(
              label: filter,
              selected: activeFilter == filter.toLowerCase(),
              onTap: () => onSelected(filter.toLowerCase()),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _DealRow extends StatelessWidget {
  final Deal deal;
  final VoidCallback onTap;

  const _DealRow({required this.deal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = dealStatusColor(deal.status);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: IdealCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deal.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(deal.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (deal.contentType != null) ...[
                        const SizedBox(width: 20),
                        Icon(
                          dealContentTypeIcon(deal.contentType!),
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          deal.contentType!.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            StatusPill(label: deal.statusLabel, color: statusColor),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}
