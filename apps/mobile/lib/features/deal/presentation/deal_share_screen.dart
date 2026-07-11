import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/deal_model.dart';
import '../domain/deal_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../services/deal_service.dart';
import '../../../shared/ideal_ui.dart';
import '../../../shared/qr_display.dart';

/// Post-creation step: shows the deal's auto reference, its invitation link and
/// QR code, and lets the creator attach the other party by username or email.
class DealShareScreen extends ConsumerStatefulWidget {
  final Deal deal;

  const DealShareScreen({super.key, required this.deal});

  @override
  ConsumerState<DealShareScreen> createState() => _DealShareScreenState();
}

class _DealShareScreenState extends ConsumerState<DealShareScreen> {
  final _partyController = TextEditingController();
  DealShareLink? _link;
  String? _linkError;
  bool _loadingLink = true;
  bool _addingParty = false;
  bool _partyAdded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_generateLink);
  }

  @override
  void dispose() {
    _partyController.dispose();
    super.dispose();
  }

  Future<void> _generateLink() async {
    setState(() {
      _loadingLink = true;
      _linkError = null;
    });
    try {
      final link = await DealService.shareDeal(widget.deal.id);
      if (!mounted) return;
      setState(() => _link = link);
    } catch (e) {
      if (!mounted) return;
      setState(() => _linkError = '$e');
    } finally {
      if (mounted) setState(() => _loadingLink = false);
    }
  }

  Future<void> _addParty() async {
    final identifier = _partyController.text.trim();
    if (identifier.isEmpty) return;
    setState(() => _addingParty = true);
    final result = await ref.read(dealProvider.notifier).addParty(
          dealId: widget.deal.id,
          identifier: identifier,
        );
    if (!mounted) return;
    setState(() => _addingParty = false);

    if (result != null) {
      setState(() => _partyAdded = true);
      _partyController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The other party has been invited.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final state = ref.read(dealProvider).whenOrNull(data: (s) => s);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state?.errorMessage ?? 'Could not add that party.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _copyLink() {
    final url = _link?.inviteUrl;
    if (url == null || url.isEmpty) return;
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deal = widget.deal;
    return IdealAppScaffold(
      activeRoute: 'deals',
      showBack: true,
      body: IdealGradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: FadeSlideIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(
                      title: 'Deal created 🎉',
                      subtitle: 'Share it and pick who you want to deal with.',
                    ),
                    const SizedBox(height: 20),
                    IdealCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _MetaLine(label: 'Title', value: deal.title),
                          const SizedBox(height: 8),
                          _MetaLine(label: 'Reference', value: deal.reference),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          if (_loadingLink)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (_linkError != null)
                            _LinkError(error: _linkError!, onRetry: _generateLink)
                          else if (_link != null) ...[
                            Center(
                              child: QrDisplay(
                                data: _link!.qrCodeData,
                                size: 180,
                                caption: 'Scan to open this deal',
                              ),
                            ),
                            const SizedBox(height: 16),
                            const FieldLabel('Invitation link'),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.input,
                                      borderRadius: BorderRadius.circular(10),
                                      border:
                                          Border.all(color: AppColors.border),
                                    ),
                                    child: Text(
                                      _link!.inviteUrl,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _copyLink,
                                  icon: const Icon(Icons.copy_outlined),
                                  tooltip: 'Copy link',
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    IdealCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add the other party',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enter their username or email. They will get a '
                            'notification to accept the deal.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _partyController,
                            decoration: const InputDecoration(
                              hintText: 'username or email@example.com',
                              prefixIcon: Icon(Icons.person_add_alt),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _addingParty ? null : _addParty,
                              icon: _addingParty
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send_outlined),
                              label: Text(
                                _partyAdded ? 'Invite another' : 'Invite party',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () =>
                            context.go(AppRoutes.dealDetail, extra: deal),
                        child: const Text('Go to deal'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final String label;
  final String value;

  const _MetaLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _LinkError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _LinkError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Could not generate the link.\n$error',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}
