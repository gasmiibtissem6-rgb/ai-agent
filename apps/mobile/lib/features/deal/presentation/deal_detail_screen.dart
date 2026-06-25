import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/deal_model.dart';
import '../domain/deal_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';

class DealDetailScreen extends ConsumerWidget {
  final Deal deal;

  const DealDetailScreen({super.key, required this.deal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionsAsync = ref.watch(dealVersionsProvider(deal.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(deal.title),
        actions: [
          if (deal.isEditable)
            IconButton(
              icon: const Icon(Icons.send_outlined),
              tooltip: 'Send deal',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Send deal'),
                    content: const Text(
                        'Send this deal to the other party for review?'),
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
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(deal.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _statusColor(deal.status).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    deal.statusLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _statusColor(deal.status),
                    ),
                  ),
                ),
                if (deal.isFinalized) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.lock_outlined,
                      size: 16, color: AppColors.success),
                  const SizedBox(width: 4),
                  const Text(
                    'Locked',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (deal.description != null) ...[
              Text(
                deal.description!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Versions
            const Text(
              'Version history',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            versionsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Text('Error loading versions: $e'),
              data: (versions) {
                if (versions.isEmpty) {
                  return const Text(
                    'No versions yet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  );
                }
                return Column(
                  children: versions
                      .map((v) => _VersionCard(
                            version: v,
                            deal: deal,
                            onApprove: () => _showApprovalDialog(
                              context,
                              ref,
                              deal: deal,
                              version: v,
                              action: 'approve',
                            ),
                            onReject: () => _showApprovalDialog(
                              context,
                              ref,
                              deal: deal,
                              version: v,
                              action: 'reject',
                            ),
                            onModify: () => _showApprovalDialog(
                              context,
                              ref,
                              deal: deal,
                              version: v,
                              action: 'modify',
                            ),
                            onFinalize: () => _showFinalizeDialog(
                              context,
                              ref,
                              deal: deal,
                              version: v,
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
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
                ? ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error)
                : null,
            onPressed: () async {
              Navigator.pop(context);
              if (action == 'approve') {
                await ref.read(dealProvider.notifier).approveDeal(
                      dealId: deal.id,
                      versionId: version.id,
                      comment: commentController.text.trim(),
                    );
              } else if (action == 'reject') {
                await ref.read(dealProvider.notifier).rejectDeal(
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
              if (context.mounted) {
                context.go(AppRoutes.deals);
              }
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
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalize'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(dealProvider.notifier).finalizeDeal(
            dealId: deal.id,
            versionId: version.id,
          );
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Version ${version.versionNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (version.isFinal)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Final',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              version.content,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text(
              _formatDate(version.createdAt),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (!deal.isFinalized && !version.isFinal) ...[
              const SizedBox(height: 16),
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
              const SizedBox(height: 8),
              if (deal.status == DealStatus.approved)
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
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}