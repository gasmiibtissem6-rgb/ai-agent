import 'template_model.dart';

enum TemplateLoadStatus { loading, loaded, saving, error }

class TemplateState {
  final TemplateLoadStatus status;
  final List<DealTemplate> templates;
  final String? errorMessage;

  const TemplateState({
    required this.status,
    this.templates = const [],
    this.errorMessage,
  });

  factory TemplateState.loading() =>
      const TemplateState(status: TemplateLoadStatus.loading);

  factory TemplateState.loaded(List<DealTemplate> templates) =>
      TemplateState(status: TemplateLoadStatus.loaded, templates: templates);

  factory TemplateState.saving(List<DealTemplate> templates) =>
      TemplateState(status: TemplateLoadStatus.saving, templates: templates);

  factory TemplateState.error(String message, List<DealTemplate> templates) =>
      TemplateState(
        status: TemplateLoadStatus.error,
        templates: templates,
        errorMessage: message,
      );

  bool get isLoading => status == TemplateLoadStatus.loading;
  bool get isSaving => status == TemplateLoadStatus.saving;
  bool get hasError => status == TemplateLoadStatus.error;
  bool get isEmpty => templates.isEmpty;
}
