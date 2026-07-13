/// A named, reusable block of a deal template.
class TemplateSection {
  final String title;
  final String body;

  const TemplateSection({required this.title, required this.body});

  factory TemplateSection.fromJson(Map<String, dynamic> json) {
    return TemplateSection(
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'title': title, 'body': body};

  TemplateSection copyWith({String? title, String? body}) {
    return TemplateSection(title: title ?? this.title, body: body ?? this.body);
  }
}

/// A reusable deal blueprint, stored on-device.
///
/// The backend has no template resource, so templates never leave the device.
/// They only ever seed a [Deal] draft, which is what gets persisted remotely.
class DealTemplate {
  final String id;
  final String name;
  final String description;
  final String category;
  final List<TemplateSection> sections;
  final DateTime createdAt;

  const DealTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.sections,
    required this.createdAt,
  });

  factory DealTemplate.fromJson(Map<String, dynamic> json) {
    return DealTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Partnership',
      sections: (json['sections'] as List? ?? [])
          .map((e) => TemplateSection.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category,
    'sections': sections.map((s) => s.toJson()).toList(),
    'created_at': createdAt.toIso8601String(),
  };

  DealTemplate copyWith({
    String? name,
    String? description,
    String? category,
    List<TemplateSection>? sections,
  }) {
    return DealTemplate(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      sections: sections ?? this.sections,
      createdAt: createdAt,
    );
  }

  /// Renders the template into the plain-text body a deal version stores.
  String toDealContent() {
    final buffer = StringBuffer()..writeln('Category: $category');
    if (description.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Description:')
        ..writeln(description.trim());
    }
    for (final section in sections) {
      buffer
        ..writeln()
        ..writeln('${section.title}:')
        ..writeln(section.body.trim());
    }
    return buffer.toString().trim();
  }
}
