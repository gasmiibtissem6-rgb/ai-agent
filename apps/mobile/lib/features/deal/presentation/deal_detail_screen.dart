import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/deal_model.dart';
import '../domain/deal_provider.dart';
import 'ai_placeholder.dart';
import 'deal_status_ui.dart';
import '../../auth/domain/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../services/deal_service.dart';
import '../../../services/document_service.dart';
import '../../../shared/file_saver.dart';
import '../../../shared/ideal_ui.dart';

class DealDetailScreen extends ConsumerWidget {
  final Deal deal;

  const DealDetailScreen({super.key, required this.deal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionsAsync = ref.watch(dealVersionsProvider(deal.id));
    final fullDealAsync = ref.watch(dealByIdProvider(deal.id));
    final dealState = ref.watch(dealProvider).whenOrNull(data: (s) => s);

    // Prefer the full deal (parties + versions). Fall back to the list, then to
    // the deal handed over by the router on first paint.
    final current = fullDealAsync.whenOrNull(data: (d) => d) ??
        dealState?.deals.firstWhere(
          (d) => d.id == deal.id,
          orElse: () => deal,
        ) ??
        deal;

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
              FadeSlideIn(
                child: _DealWorkflowCard(deal: current, profileId: profileId),
              ),
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

    if (updated != null) {
      ref.invalidate(dealByIdProvider(deal.id));
      ref.invalidate(dealVersionsProvider(deal.id));
    }
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

/// Role- and status-aware workflow actions: accept/refuse (invited party),
/// submit for approval (creator), approve/reject a version (required party),
/// open the party discussion, read with the AI (placeholder) or manually, and
/// propose a new version after discussion.
class _DealWorkflowCard extends ConsumerStatefulWidget {
  final Deal deal;
  final String? profileId;

  const _DealWorkflowCard({required this.deal, required this.profileId});

  @override
  ConsumerState<_DealWorkflowCard> createState() => _DealWorkflowCardState();
}

class _DealWorkflowCardState extends ConsumerState<_DealWorkflowCard> {
  bool _busy = false;

  Deal get deal => widget.deal;

  DealVersion? get _currentVersion {
    if (deal.versions.isEmpty) return null;
    for (final v in deal.versions) {
      if (v.id == deal.currentVersionId) return v;
    }
    return deal.versions.last;
  }

  Future<void> _run(Future<Deal?> Function() action) async {
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (result != null) {
      ref.invalidate(dealByIdProvider(deal.id));
      ref.invalidate(dealVersionsProvider(deal.id));
    } else {
      final state = ref.read(dealProvider).whenOrNull(data: (s) => s);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state?.errorMessage ?? 'Something went wrong.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _accept(bool accept) => _run(
        () => ref
            .read(dealProvider.notifier)
            .respondToDeal(dealId: deal.id, accept: accept),
      );

  Future<void> _submit(String versionId) => _run(
        () => ref
            .read(dealProvider.notifier)
            .submitVersion(dealId: deal.id, versionId: versionId),
      );

  Future<void> _decide(String versionId, bool approve, {String? reason}) => _run(
        () => ref.read(dealProvider.notifier).decideVersion(
              dealId: deal.id,
              versionId: versionId,
              approve: approve,
              reason: reason,
            ),
      );

  void _openChat() => context.go(AppRoutes.dealChat, extra: deal);

  void _readWithAi() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, controller) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: const [
              AiAssistantPanel(
                title: 'Read this deal with AI',
                description:
                    'The assistant will summarise the deal and flag clauses '
                    'you should pay attention to before deciding. This is a '
                    'placeholder — no AI is running yet.',
                bullets: [
                  'Plain-language summary of each section.',
                  'Highlights of risky or unusual clauses.',
                  'Suggested questions to raise in the discussion.',
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _readManually() {
    final document = _currentVersion?.document ?? '';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deal document'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              document.isEmpty ? 'No document content.' : document,
              style: TextStyle(color: AppColors.textPrimary, height: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectWithReason(String versionId) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request changes'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'What should change? (optional)',
          ),
        ),
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
    final reason = controller.text;
    controller.dispose();
    if (confirmed == true) {
      await _decide(versionId, false, reason: reason);
    }
  }

  Future<void> _proposeNewVersion() async {
    final base = _currentVersion;
    final controller = TextEditingController(text: base?.document ?? '');
    final summaryController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Propose a new version'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: summaryController,
                decoration: const InputDecoration(
                  labelText: 'What changed (summary)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 8,
                minLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Updated document',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create version'),
          ),
        ],
      ),
    );

    final document = controller.text.trim();
    final summary = summaryController.text.trim();
    controller.dispose();
    summaryController.dispose();
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final terms = <String, dynamic>{
        ...?base?.terms,
        'document': document,
      };
      await DealService.createVersion(
        dealId: deal.id,
        terms: terms,
        summary: summary.isEmpty ? null : summary,
      );
      if (!mounted) return;
      ref.invalidate(dealByIdProvider(deal.id));
      ref.invalidate(dealVersionsProvider(deal.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New version created.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreator = deal.isCreatedBy(widget.profileId);
    final myParty = deal.partyFor(widget.profileId);
    final version = _currentVersion;
    final versionPending = version?.status == DealStatus.pendingApproval;
    final versionOpen = version != null &&
        !version.isFinal &&
        (version.status == DealStatus.draft ||
            version.status == DealStatus.changesRequested);

    final children = <Widget>[];

    // Invited party who hasn't answered yet.
    if (!isCreator && myParty != null && myParty.isInvited) {
      children.addAll([
        Text(
          'You have been invited to this deal. Read it, then accept or refuse.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _readWithAi,
                icon: const Icon(Icons.smart_toy_outlined),
                label: const Text('Read with AI'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _readManually,
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Read manually'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _busy ? null : () => _accept(true),
                icon: const Icon(Icons.check),
                label: const Text('Accept'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error),
                onPressed: _busy ? null : () => _accept(false),
                icon: const Icon(Icons.close),
                label: const Text('Refuse'),
              ),
            ),
          ],
        ),
      ]);
    }

    // Accepted party.
    if (!isCreator && myParty != null && myParty.isAccepted) {
      children.add(Text(
        'You accepted this deal. Discuss changes in the chat; the creator '
        'turns the outcome into new versions.',
        style: TextStyle(color: AppColors.textSecondary, height: 1.5),
      ));
      children.add(const SizedBox(height: 14));
      children.add(SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _openChat,
          icon: const Icon(Icons.forum_outlined),
          label: const Text('Open discussion'),
        ),
      ));
      if (versionPending && myParty.requiredApproval && version != null) {
        children.add(const SizedBox(height: 10));
        children.add(Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _busy ? null : () => _decide(version.id, true),
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Approve version'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _rejectWithReason(version.id),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Request changes'),
              ),
            ),
          ],
        ));
      }
    }

    // Refused party.
    if (!isCreator && myParty != null && myParty.isDeclined) {
      children.add(Text(
        'You refused this deal.',
        style: TextStyle(color: AppColors.textSecondary),
      ));
    }

    // Creator view.
    if (isCreator) {
      if (!deal.hasAcceptedParty) {
        children.add(Text(
          'Waiting for the other party to accept. Share the deal link/QR or '
          'add them by username/email.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ));
        children.add(const SizedBox(height: 12));
        children.add(SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.dealShare, extra: deal),
            icon: const Icon(Icons.ios_share_outlined),
            label: const Text('Share / add party'),
          ),
        ));
      } else {
        children.add(Text(
          'A party has accepted. Discuss changes, submit a version for approval, '
          'or propose a new version.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ));
        children.add(const SizedBox(height: 12));
        children.add(SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openChat,
            icon: const Icon(Icons.forum_outlined),
            label: const Text('Open discussion'),
          ),
        ));
        if (versionOpen) {
          children.add(const SizedBox(height: 10));
          children.add(SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : () => _submit(version.id),
              icon: const Icon(Icons.how_to_reg_outlined),
              label: Text(
                'Submit V${version.versionNumber - 1} for approval',
              ),
            ),
          ));
        }
        if (versionPending) {
          children.add(const SizedBox(height: 10));
          children.add(_InlinePendingNote());
        }
        children.add(const SizedBox(height: 10));
        children.add(SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _proposeNewVersion,
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('Propose new version'),
          ),
        ));
      }
    }

    if (children.isEmpty) {
      children.add(Text(
        'No actions available for you on this deal right now.',
        style: TextStyle(color: AppColors.textSecondary),
      ));
    }

    return IdealCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Workflow',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (_busy)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InlinePendingNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_bottom_outlined,
              size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Submitted — waiting for the other party to approve.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
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
              if (version.isFinal) ...[
                const Icon(Icons.lock_outline,
                    size: 16, color: AppColors.success),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  // The initial version (number 1) is the official V0.
                  'V${version.versionNumber - 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (version.isFinal)
                const StatusPill(label: 'Locked', color: AppColors.success)
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
