import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/domain/auth_provider.dart';
import 'ai_placeholder.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/ideal_ui.dart';

/// Entry point of deal creation.
///
/// Enforces the KYC gate (only a verified user can create a deal), previews the
/// auto-assigned reference + owner, then lets the user choose between the manual
/// form and the (placeholder) AI assistant.
class DealCreateStartScreen extends ConsumerWidget {
  const DealCreateStartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref
        .watch(authProvider)
        .whenOrNull(data: (s) => s.profile);
    final verified = profile?.isKycVerified ?? false;

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
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go(AppRoutes.deals),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SectionTitle(
                            title: context.l10n.tr('dcs.title'),
                            subtitle: context.l10n.tr('dcs.subtitle'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (!verified)
                      _KycRequiredCard(
                        onStartKyc: () => context.go(AppRoutes.kycStatus),
                      )
                    else ...[
                      _NewDealMeta(
                        ownerName: profile?.displayNameOrEmail ??
                            context.l10n.tr('dcs.ownerYou'),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.l10n.tr('dcs.howBuild'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ModeCard(
                        icon: Icons.edit_note_outlined,
                        title: context.l10n.tr('dcs.manual'),
                        subtitle: context.l10n.tr('dcs.manualSub'),
                        primary: true,
                        onTap: () => context.go(AppRoutes.createDeal),
                      ),
                      const SizedBox(height: 12),
                      _ModeCard(
                        icon: Icons.smart_toy_outlined,
                        title: context.l10n.tr('dcs.ai'),
                        subtitle: context.l10n.tr('dcs.aiSub'),
                        onTap: () => context.go(AppRoutes.dealAiAssistant),
                      ),
                    ],
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

class _KycRequiredCard extends StatelessWidget {
  final VoidCallback onStartKyc;

  const _KycRequiredCard({required this.onStartKyc});

  @override
  Widget build(BuildContext context) {
    return IdealCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.verified_user_outlined,
                    color: AppColors.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.tr('dcs.kycRequired'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.tr('dcs.kycBody'),
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onStartKyc,
              icon: const Icon(Icons.badge_outlined),
              label: Text(context.l10n.tr('dcs.completeKyc')),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewDealMeta extends StatelessWidget {
  final String ownerName;

  const _NewDealMeta({required this.ownerName});

  @override
  Widget build(BuildContext context) {
    return IdealCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetaRow(
            icon: Icons.tag,
            label: context.l10n.tr('dcs.reference'),
            value: context.l10n.tr('dcs.referenceValue'),
          ),
          const SizedBox(height: 12),
          _MetaRow(
            icon: Icons.person_outline,
            label: context.l10n.tr('dcs.owner'),
            value: ownerName,
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
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

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool primary;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primary
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.25),
            width: primary ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// AI-assisted deal creation — FRONT PLACEHOLDER ONLY (no AI logic/integration).
class AiDealAssistantScreen extends StatelessWidget {
  const AiDealAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.go(AppRoutes.dealCreateStart),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SectionTitle(
                            title: context.l10n.tr('aia.title'),
                            subtitle: context.l10n.tr('aia.subtitle'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AiAssistantPanel(
                      title: context.l10n.tr('aia.panelTitle'),
                      description: context.l10n.tr('aia.panelDesc'),
                      bullets: [
                        context.l10n.tr('aia.bullet1'),
                        context.l10n.tr('aia.bullet2'),
                        context.l10n.tr('aia.bullet3'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.createDeal),
                        icon: const Icon(Icons.edit_note_outlined),
                        label: Text(context.l10n.tr('aia.switchManual')),
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
