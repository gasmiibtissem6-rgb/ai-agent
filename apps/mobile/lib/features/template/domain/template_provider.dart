import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/template_service.dart';
import 'template_model.dart';
import 'template_state.dart';

class TemplateNotifier extends AsyncNotifier<TemplateState> {
  @override
  Future<TemplateState> build() async {
    final templates = await TemplateService.getTemplates();
    return TemplateState.loaded(templates);
  }

  List<DealTemplate> get _current =>
      state.whenOrNull(data: (s) => s.templates) ?? const <DealTemplate>[];

  Future<void> loadTemplates() async {
    state = AsyncData(TemplateState.loading());
    try {
      state = AsyncData(TemplateState.loaded(await TemplateService.getTemplates()));
    } catch (e) {
      state = AsyncData(TemplateState.error('Failed to load templates.', const []));
    }
  }

  Future<DealTemplate?> createTemplate({
    required String name,
    required String description,
    required String category,
    required List<TemplateSection> sections,
  }) async {
    final previous = _current;
    state = AsyncData(TemplateState.saving(previous));
    try {
      final template = await TemplateService.createTemplate(
        name: name,
        description: description,
        category: category,
        sections: sections,
      );
      state = AsyncData(TemplateState.loaded([template, ...previous]));
      return template;
    } catch (e) {
      state = AsyncData(
        TemplateState.error('Failed to save template.', previous),
      );
      return null;
    }
  }

  Future<bool> updateTemplate(DealTemplate template) async {
    final previous = _current;
    state = AsyncData(TemplateState.saving(previous));
    try {
      await TemplateService.updateTemplate(template);
      state = AsyncData(
        TemplateState.loaded([
          for (final t in previous)
            if (t.id == template.id) template else t,
        ]),
      );
      return true;
    } catch (e) {
      state = AsyncData(
        TemplateState.error('Failed to update template.', previous),
      );
      return false;
    }
  }

  Future<void> deleteTemplate(String id) async {
    final previous = _current;
    state = AsyncData(TemplateState.saving(previous));
    try {
      await TemplateService.deleteTemplate(id);
      state = AsyncData(
        TemplateState.loaded(previous.where((t) => t.id != id).toList()),
      );
    } catch (e) {
      state = AsyncData(
        TemplateState.error('Failed to delete template.', previous),
      );
    }
  }
}

final templateProvider = AsyncNotifierProvider<TemplateNotifier, TemplateState>(
  TemplateNotifier.new,
);
