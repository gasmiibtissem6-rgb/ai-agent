import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/deal_model.dart';
import '../domain/deal_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/ideal_ui.dart';

class DealsListScreen extends ConsumerStatefulWidget {
  const DealsListScreen({super.key});

  @override
  ConsumerState<DealsListScreen> createState() => _DealsListScreenState();
}

class _DealsListScreenState extends ConsumerState<DealsListScreen> {
  String _searchTerm = '';
  String _activeFilter = 'all';

  final List<String> _filters = [
    'All',
    'Draft',
    'Negotiation',
    'Approved',
    'Rejected',
    'Archived',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dealProvider.notifier).loadDeals());
  }

  @override
  Widget build(BuildContext context) {
    final dealAsync = ref.watch(dealProvider);

    return IdealAppScaffold(
      activeRoute: 'deals',
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
        child: dealAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (state) {
            if (state.isLoading) {
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
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _DealsHeader(
                          onCreate: () => context.go(AppRoutes.createDeal),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          onChanged: (value) =>
                              setState(() => _searchTerm = value),
                          decoration: InputDecoration(
                            hintText: 'Search deals...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: AppColors.card,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
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
                      ]),
                    ),
                  ),
                  if (state.deals.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.handshake_outlined,
                        title: 'No deals yet',
                        subtitle:
                            'Create your first deal to start negotiating.',
                        actionLabel: 'Create deal',
                        onAction: () => context.go(AppRoutes.createDeal),
                      ),
                    )
                  else if (filteredDeals.isEmpty)
                    const SliverFillRemaining(
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
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverList.separated(
                        itemCount: filteredDeals.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final deal = filteredDeals[index];
                          return _DealRow(
                            deal: deal,
                            onTap: () =>
                                context.go(AppRoutes.dealDetail, extra: deal),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _filterStatus(DealStatus status) {
    switch (status) {
      case DealStatus.draft:
        return 'draft';
      case DealStatus.sent:
      case DealStatus.negotiating:
        return 'negotiation';
      case DealStatus.approved:
      case DealStatus.finalized:
        return 'approved';
      case DealStatus.rejected:
        return 'rejected';
    }
  }
}

class _DealsHeader extends StatelessWidget {
  final VoidCallback onCreate;

  const _DealsHeader({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deals',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage and track all your deals',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Deal'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
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
      child: Container(
        height: 44,
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
    final statusColor = _statusColor(deal.status);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deal.title,
                    style: const TextStyle(
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
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(deal.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Icon(
                        Icons.people_outline,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '1 participant',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    deal.statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(DealStatus status) {
  switch (status) {
    case DealStatus.draft:
      return Colors.grey;
    case DealStatus.sent:
    case DealStatus.negotiating:
      return Colors.orange;
    case DealStatus.approved:
    case DealStatus.finalized:
      return Colors.green;
    case DealStatus.rejected:
      return Colors.red;
  }
}

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}
