import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/ideal_ui.dart';

/// Front-only placeholder for the (not-yet-integrated) AI assistant.
///
/// IMPORTANT: this widget contains NO AI logic, NO network calls and NO
/// integration. It only marks, visually, WHERE the AI would be wired in later.
/// The `// AI-INTEGRATION-POINT` comments below are the seams to fill in.
class AiAssistantPanel extends StatelessWidget {
  final String title;
  final String description;
  final List<String> bullets;

  const AiAssistantPanel({
    super.key,
    required this.title,
    required this.description,
    this.bullets = const [],
  });

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
                  gradient: LinearGradient(
                    colors: [AppColors.accent, AppColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.smart_toy_outlined,
                    color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const StatusPill(
                      label: 'Coming soon',
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final bullet in bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome_outlined,
                        size: 16, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bullet,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 8),
          // AI-INTEGRATION-POINT: the assistant's input box and streamed
          // response would render here. Left as an inert placeholder on purpose.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI assistant will plug in here. No AI is running yet.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
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
