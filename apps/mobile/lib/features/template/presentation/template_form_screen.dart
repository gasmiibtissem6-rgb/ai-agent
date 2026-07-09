import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../services/document_service.dart';
import '../../../shared/file_saver.dart';
import '../../../shared/ideal_ui.dart';
import '../../deal/domain/deal_model.dart';
import '../domain/template_model.dart';
import '../domain/template_provider.dart';

/// Creates a template, or edits the one passed as the route's `extra`.
class TemplateFormScreen extends ConsumerStatefulWidget {
  final DealTemplate? template;

  const TemplateFormScreen({super.key, this.template});

  @override
  ConsumerState<TemplateFormScreen> createState() => _TemplateFormScreenState();
}

class _SectionControllers {
  final TextEditingController title;
  final TextEditingController body;

  _SectionControllers({String title = '', String body = ''})
    : title = TextEditingController(text: title),
      body = TextEditingController(text: body);

  void dispose() {
    title.dispose();
    body.dispose();
  }
}

class _TemplateFormScreenState extends ConsumerState<TemplateFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _category;
  late final List<_SectionControllers> _sections;

  bool get _isEditing => widget.template != null;

  @override
  void initState() {
    super.initState();
    final template = widget.template;
    _nameController = TextEditingController(text: template?.name ?? '');
    _descriptionController = TextEditingController(
      text: template?.description ?? '',
    );
    _category = template?.category ?? kDealCategories.first;
    final existing = template?.sections ?? const <TemplateSection>[];
    _sections = existing.isEmpty
        ? [_SectionControllers(title: 'Terms')]
        : [
            for (final section in existing)
              _SectionControllers(title: section.title, body: section.body),
          ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final section in _sections) {
      section.dispose();
    }
    super.dispose();
  }

  void _addSection() {
    setState(() => _sections.add(_SectionControllers()));
  }

  void _removeSection(int index) {
    if (_sections.length <= 1) return;
    setState(() => _sections.removeAt(index).dispose());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final sections = [
      for (final section in _sections)
        TemplateSection(
          title: section.title.text.trim(),
          body: section.body.text.trim(),
        ),
    ];

    final notifier = ref.read(templateProvider.notifier);
    final DealTemplate? saved;
    if (_isEditing) {
      final updated = widget.template!.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        sections: sections,
      );
      saved = await notifier.updateTemplate(updated) ? updated : null;
    } else {
      saved = await notifier.createTemplate(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        sections: sections,
      );
    }

    if (saved == null || !mounted) return;

    await _offerDocument(saved);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing ? 'Template updated.' : 'Template saved and ready to use.',
        ),
        backgroundColor: AppColors.success,
      ),
    );
    context.go(AppRoutes.deals);
  }

  /// Renders the saved template into a PDF. The template is already persisted,
  /// so a generation failure is a warning, not a save failure.
  Future<void> _offerDocument(DealTemplate template) async {
    try {
      final bytes = await DocumentService.generatePdf(
        title: template.name,
        content: template.toDealContent(),
      );
      await savePdfBytes(bytes, '${_fileSafe(template.name)}.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template saved, but the document failed: $e'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final templateState = ref
        .watch(templateProvider)
        .whenOrNull(data: (s) => s);
    final isSaving = templateState?.isSaving ?? false;

    ref.listen(templateProvider, (_, next) {
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
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
                            title: _isEditing
                                ? 'Edit Template'
                                : 'New Template',
                            subtitle:
                                'Reusable structure you can apply to any new deal.',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    IdealCard(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FieldLabel('Template Name *'),
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: 'e.g., Standard Partnership Agreement',
                              ),
                              validator: (value) => Validators.required(
                                value,
                                field: 'Template name',
                              ),
                            ),
                            const SizedBox(height: 18),
                            const FieldLabel('Description *'),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText:
                                    'What kind of deal is this template for?',
                              ),
                              validator: (value) => Validators.required(
                                value,
                                field: 'Description',
                              ),
                            ),
                            const SizedBox(height: 18),
                            const FieldLabel('Category *'),
                            DropdownButtonFormField<String>(
                              initialValue: _category,
                              items: [
                                for (final category in kDealCategories)
                                  DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _category = value);
                                }
                              },
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Sections',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${_sections.length}',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Each section becomes a titled block in the deal body.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 14),
                            for (var i = 0; i < _sections.length; i++) ...[
                              _SectionEditor(
                                key: ValueKey(_sections[i]),
                                index: i,
                                controllers: _sections[i],
                                onRemove: _sections.length > 1
                                    ? () => _removeSection(i)
                                    : null,
                              ),
                              const SizedBox(height: 12),
                            ],
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _addSection,
                                icon: const Icon(Icons.add),
                                label: const Text('Add section'),
                              ),
                            ),
                            const SizedBox(height: 26),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: isSaving
                                        ? null
                                        : () => context.go(AppRoutes.deals),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isSaving ? null : _save,
                                    child: isSaving
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            _isEditing
                                                ? 'Save changes'
                                                : 'Create Template',
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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

String _fileSafe(String value) {
  final cleaned = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_');
  return cleaned.isEmpty ? 'template' : cleaned;
}

class _SectionEditor extends StatelessWidget {
  final int index;
  final _SectionControllers controllers;
  final VoidCallback? onRemove;

  const _SectionEditor({
    super.key,
    required this.index,
    required this.controllers,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controllers.title,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Section title, e.g., Payment Terms',
                    isDense: true,
                  ),
                  validator: (value) =>
                      Validators.required(value, field: 'Section title'),
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  onPressed: onRemove,
                  tooltip: 'Remove section',
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controllers.body,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'What this section should say...',
            ),
            validator: (value) =>
                Validators.required(value, field: 'Section content'),
          ),
        ],
      ),
    );
  }
}
