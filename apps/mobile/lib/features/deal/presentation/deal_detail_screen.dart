import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/deal_model.dart';
import '../domain/deal_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/ideal_ui.dart';

class DealDetailScreen extends ConsumerWidget {
  final Deal deal;

  const DealDetailScreen({super.key, required this.deal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionsAsync = ref.watch(dealVersionsProvider(deal.id));
    final statusColor = _statusColor(deal.status);

    return IdealAppScaffold(
      activeRoute: 'deals',
      showBack: true,
      actions: [
        if (deal.isEditable)
          IconButton(
            icon: const Icon(Icons.send_outlined),
            tooltip: 'Send deal',
            onPressed: () => _sendDeal(context, ref),
          ),
      ],
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
                          deal.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StatusPill(
                              label: deal.statusLabel,
                              color: statusColor,
                            ),
                            if (deal.isFinalized)
                              const _InlineMeta(
                                icon: Icons.lock_outline,
                                label: 'Locked official version',
                                color: AppColors.success,
                              )
                            else
                              const _InlineMeta(
                                icon: Icons.lock_open_outlined,
                                label: 'Editable before approval',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _InfoGrid(deal: deal),
              const SizedBox(height: 22),
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
                        Tab(text: 'Actions'),
                      ],
                    ),
                    const Divider(height: 1),
                    SizedBox(
                      height: 460,
                      child: TabBarView(
                        children: [
                          _OverviewTab(deal: deal),
                          _VersionsTab(
                            versionsAsync: versionsAsync,
                            deal: deal,
                            onApprove: (version) => _showApprovalDialog(
                              context,
                              ref,
                              deal: deal,
                              version: version,
                              action: 'approve',
                            ),
                            onReject: (version) => _showApprovalDialog(
                              context,
                              ref,
                              deal: deal,
                              version: version,
                              action: 'reject',
                            ),
                            onModify: (version) => _showApprovalDialog(
                              context,
                              ref,
                              deal: deal,
                              version: version,
                              action: 'modify',
                            ),
                            onFinalize: (version) => _showFinalizeDialog(
                              context,
                              ref,
                              deal: deal,
                              version: version,
                            ),
                          ),
                          _ActionsTab(
                            deal: deal,
                            onSend: () => _sendDeal(context, ref),
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

  Future<void> _sendDeal(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send deal'),
        content: const Text('Send this deal to the other party for review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(dealProvider.notifier).sendDeal(deal.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deal sent successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(AppRoutes.deals);
      }
    }
  }

  Future<void> _showApprovalDialog(
    BuildContext context,
    WidgetRef ref, {
    required Deal deal,
    required DealVersion version,
    required String action,
  }) async {
    final commentController = TextEditingController();
    final title = action == 'approve'
        ? 'Approve deal'
        : action == 'reject'
        ? 'Reject deal'
        : 'Request modification';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              action == 'approve'
                  ? 'Are you sure you want to approve version ${version.versionNumber}?'
                  : action == 'reject'
                  ? 'Are you sure you want to reject this deal?'
                  : 'Describe what changes you need.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: action == 'modify'
                    ? 'Required changes'
                    : 'Comment (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: action == 'reject'
                ? ElevatedButton.styleFrom(backgroundColor: AppColors.error)
                : null,
            onPressed: () async {
              Navigator.pop(context);
              if (action == 'approve') {
                await ref
                    .read(dealProvider.notifier)
                    .approveDeal(
                      dealId: deal.id,
                      versionId: version.id,
                      comment: commentController.text.trim(),
                    );
              } else if (action == 'reject') {
                await ref
                    .read(dealProvider.notifier)
                    .rejectDeal(
                      dealId: deal.id,
                      versionId: version.id,
                      comment: commentController.text.trim(),
                    );
              } else {
                await ref
                    .read(dealProvider.notifier)
                    .requestModification(
                      dealId: deal.id,
                      versionId: version.id,
                      comment: commentController.text.trim(),
                    );
              }
              if (context.mounted) context.go(AppRoutes.deals);
            },
            child: Text(
              action == 'approve'
                  ? 'Approve'
                  : action == 'reject'
                  ? 'Reject'
                  : 'Request',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFinalizeDialog(
    BuildContext context,
    WidgetRef ref, {
    required Deal deal,
    required DealVersion version,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalize deal'),
        content: const Text(
          'This will permanently lock the deal. This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalize'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(dealProvider.notifier)
          .finalizeDeal(dealId: deal.id, versionId: version.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deal finalized and locked!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(AppRoutes.deals);
      }
    }
  }
}

class _InfoGrid extends StatelessWidget {
  final Deal deal;

  const _InfoGrid({required this.deal});

  @override
  Widget build(BuildContext context) {
    final items = [
      _InfoItem('Status', deal.statusLabel, Icons.flag_outlined),
      _InfoItem('Created', _formatDate(deal.createdAt), Icons.event_outlined),
      _InfoItem(
        'Versions',
        deal.versions.length.toString(),
        Icons.description_outlined,
      ),
      _InfoItem(
        'Lock',
        deal.isFinalized ? 'Final' : 'Open',
        deal.isFinalized ? Icons.lock_outline : Icons.lock_open_outlined,
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
            title: 'Draft and negotiate',
            subtitle: 'Terms remain editable until approval.',
          ),
          const _WorkflowStep(
            icon: Icons.task_alt_outlined,
            title: 'Approve same version',
            subtitle: 'Every required party accepts one version.',
          ),
          const _WorkflowStep(
            icon: Icons.lock_outline,
            title: 'Finalize contract',
            subtitle: 'The approved version becomes locked and official.',
          ),
        ],
      ),
    );
  }
}

class _VersionsTab extends StatelessWidget {
  final AsyncValue<List<DealVersion>> versionsAsync;
  final Deal deal;
  final ValueChanged<DealVersion> onApprove;
  final ValueChanged<DealVersion> onReject;
  final ValueChanged<DealVersion> onModify;
  final ValueChanged<DealVersion> onFinalize;

  const _VersionsTab({
    required this.versionsAsync,
    required this.deal,
    required this.onApprove,
    required this.onReject,
    required this.onModify,
    required this.onFinalize,
  });

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
          itemBuilder: (context, index) {
            final version = versions[index];
            return _VersionCard(
              version: version,
              deal: deal,
              onApprove: () => onApprove(version),
              onReject: () => onReject(version),
              onModify: () => onModify(version),
              onFinalize: () => onFinalize(version),
            );
          },
        );
      },
    );
  }
}

class _ActionsTab extends StatelessWidget {
  final Deal deal;
  final VoidCallback onSend;

  const _ActionsTab({required this.deal, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _ActionRow(
            icon: Icons.send_outlined,
            title: 'Send for review',
            subtitle: deal.isEditable
                ? 'Send the current draft to the other party.'
                : 'This deal cannot be sent in its current status.',
            enabled: deal.isEditable,
            onTap: onSend,
          ),
          const SizedBox(height: 12),
          const _ActionRow(
            icon: Icons.history_outlined,
            title: 'Version history',
            subtitle: 'Review submitted versions and approval actions.',
            enabled: false,
          ),
        ],
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  final DealVersion version;
  final Deal deal;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onModify;
  final VoidCallback onFinalize;

  const _VersionCard({
    required this.version,
    required this.deal,
    required this.onApprove,
    required this.onReject,
    required this.onModify,
    required this.onFinalize,
  });

  @override
  Widget build(BuildContext context) {
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
                const StatusPill(label: 'Final', color: AppColors.success),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            version.content,
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Text(
            _formatDateTime(version.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (!deal.isFinalized && !version.isFinal) ...[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onModify,
                    child: const Text('Modify'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
            if (deal.status == DealStatus.approved) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.lock_outlined),
                  label: const Text('Finalize & Lock'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  onPressed: onFinalize,
                ),
              ),
            ],
          ],
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

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: enabled ? AppColors.primary : AppColors.textSecondary,
            ),
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
                  const SizedBox(height: 3),
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
            Icon(
              Icons.chevron_right,
              color: enabled ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InlineMeta({
    required this.icon,
    required this.label,
    this.color,
  });

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

Color _statusColor(DealStatus status) {
  switch (status) {
    case DealStatus.draft:
      return AppColors.textSecondary;
    case DealStatus.sent:
      return AppColors.primary;
    case DealStatus.negotiating:
      return AppColors.warning;
    case DealStatus.approved:
      return AppColors.success;
    case DealStatus.rejected:
      return AppColors.error;
    case DealStatus.finalized:
      return AppColors.success;
  }
}

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

String _formatDateTime(DateTime date) {
  return '${_formatDate(date)} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
}
