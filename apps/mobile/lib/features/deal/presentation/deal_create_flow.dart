import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/domain/auth_provider.dart';
import 'ai_placeholder.dart';
import '../../../core/constants/app_colors.dart';
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
                        const Expanded(
                          child: SectionTitle(
                            title: 'New Deal',
                            subtitle: 'Start a new agreement',
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
                        ownerName: profile?.displayNameOrEmail ?? 'You',
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'How do you want to build it?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ModeCard(
                        icon: Icons.edit_note_outlined,
                        title: 'Manual editing',
                        subtitle:
                            'Fill in the form with sections you can add yourself.',
                        primary: true,
                        onTap: () => context.go(AppRoutes.createDeal),
                      ),
                      const SizedBox(height: 12),
                      _ModeCard(
                        icon: Icons.smart_toy_outlined,
                        title: 'AI assistant',
                        subtitle:
                            'Let the assistant draft the deal for you (coming soon).',
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
                  'Identity verification required',
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
            'You must complete your KYC before you can create a deal. '
            'Verify your identity, then come back to start a new deal.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onStartKyc,
              icon: const Icon(Icons.badge_outlined),
              label: const Text('Complete KYC'),
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
            label: 'Reference',
            value: 'Generated automatically on creation',
          ),
          const SizedBox(height: 12),
          _MetaRow(
            icon: Icons.person_outline,
            label: 'Owner',
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
                        const Expanded(
                          child: SectionTitle(
                            title: 'AI assistant',
                            subtitle: 'Draft your deal with help (placeholder)',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const AiAssistantPanel(
                      title: 'Draft a deal with AI',
                      description:
                          'The assistant will interview you and generate a first '
                          'draft of the deal, including suggested sections and '
                          'clauses. This is a placeholder — nothing is generated yet.',
                      bullets: [
                        'Describe the deal in plain language.',
                        'Get a structured draft with sections.',
                        'Review and edit before creating.',
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go(AppRoutes.createDeal),
                        icon: const Icon(Icons.edit_note_outlined),
                        label: const Text('Switch to manual editing'),
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
