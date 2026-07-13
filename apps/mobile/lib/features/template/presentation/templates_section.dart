import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/ideal_ui.dart';
import '../domain/template_model.dart';
import '../domain/template_provider.dart';

/// Templates tab of the Deals screen: list, create, edit, delete and apply.
class TemplatesSection extends ConsumerWidget {
  const TemplatesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templateAsync = ref.watch(templateProvider);

    return templateAsync.when(
      loading: () => const _SectionPlaceholder(
        child: CircularProgressIndicator(),
      ),
      error: (e, _) => _SectionPlaceholder(
        child: Text(
          'Could not load templates.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
      data: (state) {
        if (state.isLoading) {
          return const _SectionPlaceholder(
            child: CircularProgressIndicator(),
          );
        }

        if (state.isEmpty) {
          return FadeSlideIn(
            child: _EmptyTemplates(
              onCreate: () => context.go(AppRoutes.templateForm),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${state.templates.length} template'
                    '${state.templates.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.go(AppRoutes.templateForm),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New template'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < state.templates.length; i++) ...[
              FadeSlideIn(
                delay: Duration(milliseconds: 50 * i),
                child: _TemplateCard(
                  template: state.templates[i],
                  onUse: () => context.go(
                    AppRoutes.createDeal,
                    extra: state.templates[i],
                  ),
                  onEdit: () => context.go(
                    AppRoutes.templateForm,
                    extra: state.templates[i],
                  ),
                  onDelete: () =>
                      _confirmDelete(context, ref, state.templates[i]),
                ),
              ),
              const SizedBox(height: 14),
            ],
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DealTemplate template,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete template'),
        content: Text('"${template.name}" will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(templateProvider.notifier).deleteTemplate(template.id);
  }
}

/// Bounded box for centered placeholders, since this section is rendered
/// inside a SliverToBoxAdapter where the height is unbounded.
class _SectionPlaceholder extends StatelessWidget {
  final Widget child;

  const _SectionPlaceholder({required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 180, child: Center(child: child));
  }
}

class _TemplateCard extends StatelessWidget {
  final DealTemplate template;
  final VoidCallback onUse;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.onUse,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return IdealCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.dashboard_customize_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      template.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: template.category, color: AppColors.accent),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _MetaChip(
                icon: Icons.segment,
                label: '${template.sections.length} section'
                    '${template.sections.length == 1 ? '' : 's'}',
              ),
              for (final section in template.sections.take(2))
                _MetaChip(icon: Icons.label_outline, label: section.title),
              if (template.sections.length > 2)
                _MetaChip(
                  icon: Icons.more_horiz,
                  label: '+${template.sections.length - 2}',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onUse,
                  icon: const Icon(Icons.bolt_outlined, size: 18),
                  label: const Text('Use template'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onEdit,
                tooltip: 'Edit template',
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.primary,
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Delete template',
                icon: const Icon(Icons.delete_outline),
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTemplates extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyTemplates({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    // EmptyState centers itself, so it needs a bounded height here: this
    // section is laid out inside a SliverToBoxAdapter, not a SliverFillRemaining.
    return SizedBox(
      height: 400,
      child: EmptyState(
        icon: Icons.dashboard_customize_outlined,
        title: 'No templates yet',
        subtitle:
            'Build a reusable structure once, then spin up new deals from it in a single tap.',
        actionLabel: 'Create template',
        onAction: onCreate,
      ),
    );
  }
}
