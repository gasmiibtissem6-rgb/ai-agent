import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/deal_model.dart';
import '../domain/deal_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/ideal_ui.dart';

class ContractsScreen extends ConsumerStatefulWidget {
  const ContractsScreen({super.key});

  @override
  ConsumerState<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends ConsumerState<ContractsScreen> {
  String _searchTerm = '';
  String _activeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final dealState = ref
        .watch(dealProvider)
        .whenOrNull(data: (state) => state);
    final contracts = (dealState?.deals ?? const <Deal>[])
        .where(
          (deal) =>
              deal.status == DealStatus.approved ||
              deal.status == DealStatus.finalized,
        )
        .where((deal) {
          final matchesFilter =
              _activeFilter == 'all' ||
              (_activeFilter == 'approved' &&
                  deal.status == DealStatus.approved) ||
              (_activeFilter == 'pending' &&
                  deal.status == DealStatus.finalized);
          final matchesSearch = deal.title.toLowerCase().contains(
            _searchTerm.toLowerCase(),
          );
          return matchesFilter && matchesSearch;
        })
        .toList();

    return IdealAppScaffold(
      activeRoute: 'contracts',
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
              'Contracts',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'View and manage all your finalized contracts',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              onChanged: (value) => setState(() => _searchTerm = value),
              decoration: const InputDecoration(
                hintText: 'Search contracts...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _FilterButton(
                  label: 'All',
                  selected: _activeFilter == 'all',
                  onTap: () => setState(() => _activeFilter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterButton(
                  label: 'Approved',
                  selected: _activeFilter == 'approved',
                  onTap: () => setState(() => _activeFilter = 'approved'),
                ),
                const SizedBox(width: 8),
                _FilterButton(
                  label: 'Pending',
                  selected: _activeFilter == 'pending',
                  onTap: () => setState(() => _activeFilter = 'pending'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (contracts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Text(
                    'No contracts found',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              for (final contract in contracts) ...[
                _ContractCard(deal: contract),
                const SizedBox(height: 14),
              ],
          ],
        ),
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  final Deal deal;

  const _ContractCard({required this.deal});

  @override
  Widget build(BuildContext context) {
    final approved = deal.status == DealStatus.approved;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
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
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Deal #${deal.id}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (approved ? Colors.green : Colors.orange).withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    approved ? 'Approved' : 'Pending',
                    style: TextStyle(
                      color: approved ? Colors.green : Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _comingSoon(context),
            icon: const Icon(Icons.visibility),
            color: AppColors.primary,
          ),
          IconButton(
            onPressed: () => _comingSoon(context),
            icon: const Icon(Icons.download),
            color: AppColors.primary,
          ),
          IconButton(
            onPressed: () => _comingSoon(context),
            icon: const Icon(Icons.share),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This feature is still being built.')),
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
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
