import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ideal_app/features/template/domain/template_model.dart';
import 'package:ideal_app/features/template/domain/template_provider.dart';
import 'package:ideal_app/services/template_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('TemplateService', () {
    test('returns an empty list when nothing was ever saved', () async {
      expect(await TemplateService.getTemplates(), isEmpty);
    });

    test('persists a created template and reads it back', () async {
      await TemplateService.createTemplate(
        name: 'Standard Partnership',
        description: 'Two-party partnership',
        category: 'Partnership',
        sections: const [
          TemplateSection(title: 'Payment Terms', body: 'Net 30.'),
          TemplateSection(title: 'Exit Clause', body: '60 days notice.'),
        ],
      );

      final templates = await TemplateService.getTemplates();
      expect(templates, hasLength(1));
      expect(templates.single.name, 'Standard Partnership');
      expect(templates.single.sections.map((s) => s.title), [
        'Payment Terms',
        'Exit Clause',
      ]);
    });

    test('deleting the only template leaves an empty list', () async {
      final template = await TemplateService.createTemplate(
        name: 'Throwaway',
        description: 'd',
        category: 'Service',
        sections: const [TemplateSection(title: 'T', body: 'b')],
      );

      await TemplateService.deleteTemplate(template.id);
      expect(await TemplateService.getTemplates(), isEmpty);
    });

    test('recovers from a corrupted blob instead of throwing', () async {
      FlutterSecureStorage.setMockInitialValues({
        'deal_templates_v1': 'not-json',
      });
      expect(await TemplateService.getTemplates(), isEmpty);
    });
  });

  group('DealTemplate', () {
    final template = DealTemplate(
      id: 'abc',
      name: 'N',
      description: 'Seed round terms',
      category: 'License',
      sections: const [TemplateSection(title: 'Valuation', body: '5M')],
      createdAt: DateTime.utc(2026, 7, 9),
    );

    test('round-trips through JSON', () {
      final restored = DealTemplate.fromJson(template.toJson());
      expect(restored.id, template.id);
      expect(restored.category, 'License');
      expect(restored.sections.single.title, 'Valuation');
      expect(restored.createdAt, template.createdAt);
    });

    test('renders its sections into the deal body', () {
      final content = template.toDealContent();
      expect(content, contains('Category: License'));
      expect(content, contains('Description:\nSeed round terms'));
      expect(content, contains('Valuation:\n5M'));
    });
  });

  group('templateProvider', () {
    test('create persists, then delete clears the state the UI reads', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(templateProvider.future);
      expect(container.read(templateProvider).requireValue.templates, isEmpty);

      final notifier = container.read(templateProvider.notifier);
      final created = await notifier.createTemplate(
        name: 'Investment Round',
        description: 'Seed round terms',
        category: 'Investment',
        sections: const [TemplateSection(title: 'Valuation', body: '5M')],
      );

      expect(created, isNotNull);
      var state = container.read(templateProvider).requireValue;
      expect(state.isSaving, isFalse);
      expect(state.templates.single.name, 'Investment Round');

      // A fresh container must see what was persisted — this is what makes a
      // created template reusable across app launches.
      final reloaded = ProviderContainer();
      addTearDown(reloaded.dispose);
      final reloadedState = await reloaded.read(templateProvider.future);
      expect(reloadedState.templates.single.id, created!.id);

      await notifier.deleteTemplate(created.id);
      state = container.read(templateProvider).requireValue;
      expect(state.templates, isEmpty);
    });
  });
}
