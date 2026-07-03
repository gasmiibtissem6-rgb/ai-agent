import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/ideal_ui.dart';
import '../../documents/presentation/create_contract_screen.dart';
import '../../../core/locale/app_strings.dart';
import '../../../core/locale/locale_provider.dart';

class ContractsScreen extends StatefulWidget {
  const ContractsScreen({super.key});

  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen> {
  static const _baseUrl = 'http://localhost:3001/api/contracts';
  String _tr(WidgetRef ref, String key) => AppStrings.get(ref.watch(localeProvider).languageCode, key);

  String _searchTerm = '';
  String _activeFilter = 'all';
  bool _isLoading = true;
  String? _error;
  List<dynamic> _contracts = [];

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = Dio();
      final response = await dio.get(_baseUrl);
      final data = response.data['data'] ?? response.data;
      setState(() => _contracts = data as List<dynamic>);
    } catch (e) {
      setState(() => _error = 'Impossible de charger les contrats : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, _) {
    final filtered = _contracts.where((c) {
      final status = (c['status'] ?? '').toString();
      final matchesFilter = _activeFilter == 'all' ||
          (_activeFilter == 'draft' && status == 'DRAFT') ||
          (_activeFilter == 'sent' && status == 'SENT') ||
          (_activeFilter == 'signed' && status == 'SIGNED');
      final title = (c['title'] ?? '').toString().toLowerCase();
      final matchesSearch = title.contains(_searchTerm.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    return IdealAppScaffold(
      activeRoute: 'contracts',
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
        child: RefreshIndicator(
          onRefresh: _loadContracts,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              Text(
                _tr(ref, 'myContracts_title'),
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                _tr(ref, 'myContracts_subtitle'),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextField(
                onChanged: (value) => setState(() => _searchTerm = value),
                decoration: InputDecoration(
                  hintText: _tr(ref, 'myContracts_search'),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _FilterButton(label: _tr(ref, 'myContracts_filter_all'), selected: _activeFilter == 'all', onTap: () => setState(() => _activeFilter = 'all')),
                  const SizedBox(width: 8),
                  _FilterButton(label: _tr(ref, 'myContracts_filter_draft'), selected: _activeFilter == 'draft', onTap: () => setState(() => _activeFilter = 'draft')),
                  const SizedBox(width: 8),
                  _FilterButton(label: _tr(ref, 'myContracts_filter_sent'), selected: _activeFilter == 'sent', onTap: () => setState(() => _activeFilter = 'sent')),
                  const SizedBox(width: 8),
                  _FilterButton(label: _tr(ref, 'myContracts_filter_signed'), selected: _activeFilter == 'signed', onTap: () => setState(() => _activeFilter = 'signed')),
                ],
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 48), child: CircularProgressIndicator()))
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(children: [
                      Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _loadContracts, child: Text(_tr(ref, 'myContracts_retry'))),
                    ]),
                  ),
                )
              else if (filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Text(_tr(ref, 'myContracts_no_contract_found'), style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  ),
                )
              else
                for (final contract in filtered) ...[
                  _ContractCard(
                    ref: ref,
                    contract: contract,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CreateContractScreen(contractId: contract['id'])),
                      );
                      _loadContracts();
                    },
                  ),
                  const SizedBox(height: 14),
                ],
            ],
          ),
        ),
      ),
    );
    });
  }
}

class _ContractCard extends StatelessWidget {
  final WidgetRef ref;
  final dynamic contract;
  final VoidCallback onTap;

  const _ContractCard({required this.ref, required this.contract, required this.onTap});

  String _tr(String key) => AppStrings.get(ref.watch(localeProvider).languageCode, key);

  @override
  Widget build(BuildContext context) {
    final status = (contract['status'] ?? 'DRAFT').toString();
    final colors = {'DRAFT': Colors.grey, 'SENT': Colors.orange, 'SIGNED': Colors.green, 'CANCELLED': Colors.red};
    final labels = {'DRAFT': _tr('myContracts_status_draft'), 'SENT': _tr('myContracts_status_sent'), 'SIGNED': _tr('myContracts_status_signed'), 'CANCELLED': _tr('myContracts_status_cancelled')};
    final color = colors[status] ?? Colors.grey;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  Text(contract['title'] ?? 'Sans titre', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(
                    (contract['description'] ?? '').toString().isEmpty ? 'Aucune description' : contract['description'],
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                    child: Text(labels[status] ?? status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterButton({required this.label, required this.selected, required this.onTap});

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
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 13),
        ),
      ),
    );
  }
}
