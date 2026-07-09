import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/deal_model.dart';
import '../domain/deal_provider.dart';
import 'deal_status_ui.dart';
import '../../auth/domain/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../services/document_service.dart';
import '../../../shared/file_saver.dart';
import '../../../shared/ideal_ui.dart';

class DealDetailScreen extends ConsumerWidget {
  final Deal deal;

  const DealDetailScreen({super.key, required this.deal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionsAsync = ref.watch(dealVersionsProvider(deal.id));
    final dealState = ref.watch(dealProvider).whenOrNull(data: (s) => s);

    // The list is the source of truth after a status change; fall back to the
    // deal handed over by the router on first paint.
    final current = dealState?.deals.firstWhere(
      (d) => d.id == deal.id,
      orElse: () => deal,
    ) ?? deal;

    final profileId = ref
        .watch(authProvider)
        .whenOrNull(data: (s) => s.profile?.id);
    final isCreator = current.isCreatedBy(profileId);
    final isUpdating = dealState?.isUpdating ?? false;

    ref.listen(dealProvider, (_, next) {
      final state = next.whenOrNull(data: (s) => s);
      if (state?.hasError == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state!.errorMessage ?? 'Something went wrong.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return IdealAppScaffold(
      activeRoute: 'deals',
      showBack: true,
      body: IdealGradientBackground(
        child: DefaultTabController(
          length: 3,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRoutes.deals),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          current.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StatusPill(
                              label: current.statusLabel,
                              color: dealStatusColor(current.status),
                            ),
                            if (current.contentType != null)
                              _InlineMeta(
                                icon: dealContentTypeIcon(current.contentType!),
                                label: current.contentType!.label,
                              ),
                            if (current.isLocked)
                              const _InlineMeta(
                                icon: Icons.lock_outline,
                                label: 'Locked official version',
                                color: AppColors.success,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _InfoGrid(deal: current),
              const SizedBox(height: 22),
              if (isCreator)
                FadeSlideIn(
                  child: _StatusChanger(
                    deal: current,
                    isUpdating: isUpdating,
                    onChange: (status) =>
                        _confirmStatusChange(context, ref, current, status),
                  ),
                ),
              if (isCreator) const SizedBox(height: 22),
              IdealCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textSecondary,
                      indicatorColor: AppColors.primary,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Versions'),
                        Tab(text: 'Document'),
                      ],
                    ),
                    const Divider(height: 1),
                    SizedBox(
                      height: 460,
                      child: TabBarView(
                        children: [
                          _OverviewTab(deal: current),
                          _VersionsTab(versionsAsync: versionsAsync),
                          _DocumentTab(
                            deal: current,
                            versionsAsync: versionsAsync,
                          ),
                        ],
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

  Future<void> _confirmStatusChange(
    BuildContext context,
    WidgetRef ref,
    Deal deal,
    DealStatus target,
  ) async {
    final reasonController = TextEditingController();
    final destructive = target == DealStatus.cancelled;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set status to ${target.label}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              destructive
                  ? 'Cancelling records a cancellation date on the deal. Participants will see it as Cancelled.'
                  : 'This change is recorded in the deal audit trail.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: destructive
                ? ElevatedButton.styleFrom(backgroundColor: AppColors.error)
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(destructive ? 'Cancel deal' : 'Confirm'),
          ),
        ],
      ),
    );

    final reason = reasonController.text;
    reasonController.dispose();
    if (confirm != true) return;

    final updated = await ref
        .read(dealProvider.notifier)
        .updateStatus(
          dealId: deal.id,
          status: target,
          reason: reason,
        );

    if (updated != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deal is now ${updated.statusLabel}.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

/// Creator-only control to move the deal between Approved, Bridged and Cancelled.
class _StatusChanger extends StatelessWidget {
  final Deal deal;
  final bool isUpdating;
  final ValueChanged<DealStatus> onChange;

  const _StatusChanger({
    required this.deal,
    required this.isUpdating,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final terminal = deal.isTerminal;

    return IdealCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Deal status',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (isUpdating)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            terminal
                ? 'A ${deal.statusLabel.toLowerCase()} deal can no longer change status.'
                : 'As the creator, you can move this deal between these states.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in kCreatorSettableStatuses)
                _StatusChoice(
                  status: status,
                  selected: deal.status == status,
                  enabled: !terminal && !isUpdating && deal.status != status,
                  onTap: () => onChange(status),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChoice extends StatelessWidget {
  final DealStatus status;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _StatusChoice({
    required this.status,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = dealStatusColor(status);
    final foreground = selected
        ? Colors.white
        : enabled
        ? color
        : AppColors.textSecondary;

    return Opacity(
      opacity: enabled || selected ? 1 : 0.5,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(dealStatusIcon(status), size: 16, color: foreground),
              const SizedBox(width: 8),
              Text(
                status.label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check, size: 14, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final Deal deal;

  const _InfoGrid({required this.deal});

  @override
  Widget build(BuildContext context) {
    final items = [
      _InfoItem('Status', deal.statusLabel, dealStatusIcon(deal.status)),
      _InfoItem('Created', _formatDate(deal.createdAt), Icons.event_outlined),
      _InfoItem(
        'Type',
        deal.contentType?.label ?? 'Document',
        deal.contentType == null
            ? Icons.description_outlined
            : dealContentTypeIcon(deal.contentType!),
      ),
      _InfoItem(
        'Lock',
        deal.isLocked ? 'Final' : 'Open',
        deal.isLocked ? Icons.lock_outline : Icons.lock_open_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth > 700 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return IdealCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(item.icon, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Deal deal;

  const _OverviewTab({required this.deal});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            deal.description?.isNotEmpty == true
                ? deal.description!
                : 'No description provided.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Workflow',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const _WorkflowStep(
            icon: Icons.edit_note_outlined,
            title: 'Draft',
            subtitle: 'Terms remain editable while the deal is a draft.',
          ),
          const _WorkflowStep(
            icon: Icons.compare_arrows_outlined,
            title: 'Bridged',
            subtitle: 'The deal is in flight between the parties.',
          ),
          const _WorkflowStep(
            icon: Icons.check_circle_outline,
            title: 'Approved',
            subtitle: 'All parties agree on the current version.',
          ),
        ],
      ),
    );
  }
}

class _VersionsTab extends StatelessWidget {
  final AsyncValue<List<DealVersion>> versionsAsync;

  const _VersionsTab({required this.versionsAsync});

  @override
  Widget build(BuildContext context) {
    return versionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading versions: $e')),
      data: (versions) {
        if (versions.isEmpty) {
          return Center(
            child: Text(
              'No versions yet.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: versions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _VersionCard(version: versions[index]),
        );
      },
    );
  }
}

/// Lets the user regenerate and download the deal's document at any time.
class _DocumentTab extends ConsumerStatefulWidget {
  final Deal deal;
  final AsyncValue<List<DealVersion>> versionsAsync;

  const _DocumentTab({required this.deal, required this.versionsAsync});

  @override
  ConsumerState<_DocumentTab> createState() => _DocumentTabState();
}

class _DocumentTabState extends ConsumerState<_DocumentTab> {
  bool _isGenerating = false;

  Future<void> _download(String content) async {
    setState(() => _isGenerating = true);
    try {
      final bytes = await DocumentService.generatePdf(
        title: widget.deal.title,
        content: content,
      );
      await savePdfBytes(bytes, '${_fileSafe(widget.deal.title)}.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.versionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading document: $e')),
      data: (versions) {
        final document = versions.isEmpty ? '' : versions.first.document;
        if (document.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'This deal has no generated document.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Text(
                  document,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    height: 1.6,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : () => _download(document),
                  icon: _isGenerating
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_outlined),
                  label: Text(
                    _isGenerating ? 'Generating…' : 'Download PDF',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

String _fileSafe(String value) {
  final cleaned = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
  return cleaned.isEmpty ? 'deal' : cleaned;
}

class _VersionCard extends StatelessWidget {
  final DealVersion version;

  const _VersionCard({required this.version});

  @override
  Widget build(BuildContext context) {
    final preview = version.document.isEmpty
        ? (version.summary ?? 'No content.')
        : version.document;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Version ${version.versionNumber}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (version.isFinal)
                const StatusPill(label: 'Final', color: AppColors.success)
              else
                StatusPill(
                  label: version.status.label,
                  color: dealStatusColor(version.status),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            preview,
            style: TextStyle(color: AppColors.textSecondary, height: 1.45),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Text(
            _formatDateTime(version.createdAt),
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _WorkflowStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _WorkflowStep({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InlineMeta({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? AppColors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: displayColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: displayColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InfoItem {
  final String title;
  final String value;
  final IconData icon;

  const _InfoItem(this.title, this.value, this.icon);
}

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

String _formatDateTime(DateTime date) {
  return '${_formatDate(date)} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}
