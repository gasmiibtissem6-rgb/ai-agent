import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/kyc_model.dart';
import '../domain/kyc_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/ideal_ui.dart';

class KycStatusScreen extends ConsumerStatefulWidget {
  const KycStatusScreen({super.key});

  @override
  ConsumerState<KycStatusScreen> createState() => _KycStatusScreenState();
}

class _KycStatusScreenState extends ConsumerState<KycStatusScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(kycProvider.notifier).loadKyc());
  }

  @override
  Widget build(BuildContext context) {
    final kycAsync = ref.watch(kycProvider);

    return IdealAppScaffold(
      activeRoute: 'kyc',
      body: IdealGradientBackground(
        child: kycAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (kycState) {
            if (kycState.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final submission = kycState.submission;
            if (submission == null ||
                submission.status == KycStatus.notSubmitted) {
              return _NotSubmittedView(
                onStartVerification: () => context.go(AppRoutes.kycUpload),
              );
            }
            return _StatusView(submission: submission);
          },
        ),
      ),
    );
  }
}

class _NotSubmittedView extends StatelessWidget {
  final VoidCallback onStartVerification;

  const _NotSubmittedView({required this.onStartVerification});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: IdealCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusIcon(
                icon: Icons.verified_user_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Verify your identity',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'To participate in deals and build trust with other parties, verify your identity with a government-issued ID.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              const _InfoRow(
                icon: Icons.lock_outlined,
                text: 'Your documents are stored securely and privately',
              ),
              const SizedBox(height: 12),
              const _InfoRow(
                icon: Icons.access_time_outlined,
                text: 'Verification usually takes 1-2 business days',
              ),
              const SizedBox(height: 12),
              const _InfoRow(
                icon: Icons.shield_outlined,
                text: 'Only authorized reviewers can access your documents',
              ),
              const SizedBox(height: 36),
              ElevatedButton(
                onPressed: onStartVerification,
                child: const Text('Start Verification'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  final KycSubmission submission;

  const _StatusView({required this.submission});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(submission.status);
    final icon = _statusIcon(submission.status);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: IdealCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusIcon(icon: icon, color: color),
              const SizedBox(height: 24),
              Text(
                submission.statusLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _statusMessage(submission.status),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              if (submission.status == KycStatus.rejected &&
                  submission.rejectionReason != null) ...[
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rejection reason',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        submission.rejectionReason!,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.kycUpload),
                  child: const Text('Resubmit Documents'),
                ),
              ],
              const SizedBox(height: 28),
              _InfoCard(submission: submission),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final KycSubmission submission;

  const _InfoCard({required this.submission});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Submission details',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'Document type',
            value: submission.documentTypeLabel,
          ),
          if (submission.createdAt != null)
            _DetailRow(
              label: 'Submitted on',
              value: _formatDate(submission.createdAt!),
            ),
          if (submission.reviewedAt != null)
            _DetailRow(
              label: 'Reviewed on',
              value: _formatDate(submission.reviewedAt!),
            ),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _StatusIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(icon, size: 48, color: color),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

Color _statusColor(KycStatus status) {
  switch (status) {
    case KycStatus.pending:
      return AppColors.warning;
    case KycStatus.approved:
      return AppColors.success;
    case KycStatus.rejected:
      return AppColors.error;
    default:
      return AppColors.textSecondary;
  }
}

IconData _statusIcon(KycStatus status) {
  switch (status) {
    case KycStatus.pending:
      return Icons.hourglass_empty_outlined;
    case KycStatus.approved:
      return Icons.verified_outlined;
    case KycStatus.rejected:
      return Icons.cancel_outlined;
    default:
      return Icons.help_outline;
  }
}

String _statusMessage(KycStatus status) {
  switch (status) {
    case KycStatus.pending:
      return 'Your documents are being reviewed. This usually takes 1-2 business days.';
    case KycStatus.approved:
      return 'Your identity has been verified. You can now participate in deals.';
    case KycStatus.rejected:
      return 'Your verification was rejected. Please review the reason and resubmit.';
    default:
      return '';
  }
}

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}
