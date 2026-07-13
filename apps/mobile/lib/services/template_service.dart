import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../features/template/domain/template_model.dart';

/// Template Service — persists deal templates on-device.
///
/// There is no template resource on the NestJS API nor in the Prisma schema,
/// so templates live in secure storage as a single JSON blob keyed per user.
class TemplateService {
  const TemplateService._();

  static const _storage = FlutterSecureStorage();
  static const _key = 'deal_templates_v1';
  static const _uuid = Uuid();

  static Future<List<DealTemplate>> getTemplates() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List;
      final templates = decoded
          .map((e) => DealTemplate.fromJson(e as Map<String, dynamic>))
          .toList();
      templates.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return templates;
    } on FormatException {
      // A corrupted blob should not brick the Templates tab forever.
      await _storage.delete(key: _key);
      return const [];
    }
  }

  static Future<DealTemplate> createTemplate({
    required String name,
    required String description,
    required String category,
    required List<TemplateSection> sections,
  }) async {
    final template = DealTemplate(
      id: _uuid.v4(),
      name: name,
      description: description,
      category: category,
      sections: sections,
      createdAt: DateTime.now(),
    );
    final templates = await getTemplates();
    await _writeAll([template, ...templates]);
    return template;
  }

  static Future<DealTemplate> updateTemplate(DealTemplate template) async {
    final templates = await getTemplates();
    final index = templates.indexWhere((t) => t.id == template.id);
    if (index == -1) {
      throw StateError('Template ${template.id} no longer exists.');
    }
    templates[index] = template;
    await _writeAll(templates);
    return template;
  }

  static Future<void> deleteTemplate(String id) async {
    final templates = await getTemplates();
    await _writeAll(templates.where((t) => t.id != id).toList());
  }

  static Future<void> _writeAll(List<DealTemplate> templates) async {
    final payload = jsonEncode(templates.map((t) => t.toJson()).toList());
    await _storage.write(key: _key, value: payload);
  }
}
