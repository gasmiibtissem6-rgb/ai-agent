import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../domain/deal_model.dart';
import '../domain/deal_provider.dart';
import 'deal_status_ui.dart';
import '../../template/domain/template_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../services/deal_service.dart';
import '../../../services/document_service.dart';
import '../../../shared/file_saver.dart';
import '../../../shared/ideal_ui.dart';
import '../../../shared/platform_file_picker.dart';

/// Creates a deal, optionally seeded from the [template] passed as route extra.
class CreateDealScreen extends ConsumerStatefulWidget {
  final DealTemplate? template;

  const CreateDealScreen({super.key, this.template});

  @override
  ConsumerState<CreateDealScreen> createState() => _CreateDealScreenState();
}

/// Title + body pair for one user-added section of the deal body.
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

class _CreateDealScreenState extends ConsumerState<CreateDealScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final _dateController = TextEditingController();

  final List<TextEditingController> _participantControllers = [
    TextEditingController(),
  ];
  final List<String> _participantRoles = ['Partner'];

  late String _category;
  late final List<_SectionControllers> _sections;

  DealContentType _contentType = DealContentType.document;
  PickedFileData? _attachment;
  String _ocrText = '';
  bool _isScanning = false;

  DealTemplate? get _template => widget.template;

  @override
  void initState() {
    super.initState();
    final template = _template;
    _titleController = TextEditingController(text: template?.name ?? '');
    _descriptionController = TextEditingController(
      text: template?.description ?? '',
    );
    _category = template?.category ?? kDealCategories.first;
    _sections = [
      for (final section in template?.sections ?? const <TemplateSection>[])
        _SectionControllers(title: section.title, body: section.body),
    ];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    for (final controller in _participantControllers) {
      controller.dispose();
    }
    for (final section in _sections) {
      section.dispose();
    }
    super.dispose();
  }

  void _addParticipant() {
    setState(() {
      _participantControllers.add(TextEditingController());
      _participantRoles.add('Partner');
    });
  }

  void _removeParticipant(int index) {
    if (_participantControllers.length <= 1) return;
    setState(() {
      _participantControllers.removeAt(index).dispose();
      _participantRoles.removeAt(index);
    });
  }

  void _addSection() => setState(() => _sections.add(_SectionControllers()));

  void _removeSection(int index) =>
      setState(() => _sections.removeAt(index).dispose());

  void _selectContentType(DealContentType type) {
    if (type == _contentType) return;
    setState(() {
      _contentType = type;
      _attachment = null;
      _ocrText = '';
    });
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365 * 5)),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickAttachment() async {
    final extensions = switch (_contentType) {
      DealContentType.video => ['mp4', 'mov', 'avi', 'mkv'],
      DealContentType.scanned => ['png', 'jpg', 'jpeg', 'webp'],
      DealContentType.document => null,
    };

    final file = await pickSingleFile(allowedExtensions: extensions);
    if (file == null || !mounted) return;

    setState(() {
      _attachment = file;
      _ocrText = '';
    });

    if (_contentType != DealContentType.scanned) return;

    setState(() => _isScanning = true);
    try {
      final text = await DocumentService.scanDocument(
        imageDataUrl: file.dataUrl,
      );
      if (!mounted) return;
      setState(() => _ocrText = text);
      if (text.isEmpty) {
        _snack('No text was detected in that image.', AppColors.warning);
      }
    } catch (e) {
      if (mounted) _snack('$e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  List<DealPartyInput> _buildParties() {
    final parties = <DealPartyInput>[];
    for (var i = 0; i < _participantControllers.length; i++) {
      final email = _participantControllers[i].text.trim();
      if (email.isEmpty) continue;
      parties.add(DealPartyInput(email: email, role: _participantRoles[i]));
    }
    return parties;
  }

  /// The human-readable document rendered into the PDF and stored on the
  /// version's `termsJson.document`.
  String _renderDocument() {
    final buffer = StringBuffer()
      ..writeln(_titleController.text.trim())
      ..writeln()
      ..writeln('Category: $_category')
      ..writeln('Content type: ${_contentType.label}')
      ..writeln(
        'Creation date: '
        '${_dateController.text.isEmpty ? 'Not set' : _dateController.text}',
      );

    if (_template != null) {
      buffer.writeln('Template: ${_template!.name}');
    }

    final parties = _buildParties();
    if (parties.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Participants:');
      for (final party in parties) {
        buffer.writeln('- ${party.email} (${party.role})');
      }
    }

    buffer
      ..writeln()
      ..writeln('Description:')
      ..writeln(_descriptionController.text.trim());

    for (final section in _sections) {
      buffer
        ..writeln()
        ..writeln('${section.title.text.trim()}:')
        ..writeln(section.body.text.trim());
    }

    if (_attachment != null) {
      buffer
        ..writeln()
        ..writeln('Attachment:')
        ..writeln('- ${_attachment!.name} (${_contentType.label})');
    }

    if (_ocrText.trim().isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Scanned content (OCR):')
        ..writeln(_ocrText.trim());
    }

    return buffer.toString().trim();
  }

  /// Structured terms persisted on the initial draft version.
  ///
  /// Attachment *bytes* are deliberately excluded — `terms_json` is a jsonb
  /// column, not a blob store. Only the file's identity is recorded.
  Map<String, dynamic> _buildTerms() => {
    'category': _category,
    'contentType': _contentType.wireValue,
    'creationDate': _dateController.text.isEmpty ? null : _dateController.text,
    'description': _descriptionController.text.trim(),
    'sections': [
      for (final section in _sections)
        {'title': section.title.text.trim(), 'body': section.body.text.trim()},
    ],
    'participants': [
      for (final party in _buildParties())
        {'email': party.email, 'role': party.role},
    ],
    if (_template != null) 'templateName': _template!.name,
    if (_attachment != null)
      'attachment': {
        'name': _attachment!.name,
        'mimeType': _attachment!.mimeType,
      },
    if (_ocrText.trim().isNotEmpty) 'ocrText': _ocrText.trim(),
    'document': _renderDocument(),
  };

  Future<void> _createDeal() async {
    if (!_formKey.currentState!.validate()) return;

    if (_contentType != DealContentType.document && _attachment == null) {
      _snack(
        'Attach a ${_contentType.label.toLowerCase()} first.',
        AppColors.warning,
      );
      return;
    }

    final document = _renderDocument();
    final deal = await ref
        .read(dealProvider.notifier)
        .createDeal(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          terms: _buildTerms(),
          contentType: _contentType,
          parties: _buildParties(),
        );
    if (deal == null || !mounted) return;

    await _offerDocument(deal.title, document);
    // Next step of the flow: show the deal's link + QR and attach the other party.
    if (mounted) context.go(AppRoutes.dealShare, extra: deal);
  }

  /// Generates the deal document and hands it to the user. A failure here must
  /// not look like the deal itself failed — it is already persisted.
  Future<void> _offerDocument(String title, String content) async {
    try {
      final media = <DocumentMedia>[
        if (_contentType == DealContentType.scanned && _attachment != null)
          DocumentMedia(
            dataUrl: _attachment!.dataUrl,
            caption: _attachment!.name,
          ),
      ];
      final bytes = await DocumentService.generatePdf(
        title: title,
        content: content,
        media: media,
      );
      await savePdfBytes(bytes, '${_fileSafe(title)}.pdf');
    } catch (e) {
      if (mounted) {
        _snack('Deal created, but the document failed: $e', AppColors.warning);
      }
    }
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    final dealState = ref.watch(dealProvider).whenOrNull(data: (s) => s);
    final isCreating = dealState?.isCreating ?? false;
    final busy = isCreating || _isScanning;

    ref.listen(dealProvider, (_, next) {
      final state = next.whenOrNull(data: (s) => s);
      if (state?.hasError == true) {
        _snack(
          state!.errorMessage ?? 'Failed to create deal.',
          AppColors.error,
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
                        const Expanded(
                          child: SectionTitle(
                            title: 'Create New Deal',
                            subtitle:
                                'Set up a new agreement with participants',
                          ),
                        ),
                      ],
                    ),
                    if (_template != null) ...[
                      const SizedBox(height: 16),
                      _TemplateBanner(name: _template!.name),
                    ],
                    const SizedBox(height: 20),
                    IdealCard(
                      padding: const EdgeInsets.all(22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const FieldLabel('Content Type *'),
                            _ContentTypePicker(
                              selected: _contentType,
                              onChanged: _selectContentType,
                            ),
                            if (_contentType != DealContentType.document) ...[
                              const SizedBox(height: 14),
                              _AttachmentPicker(
                                contentType: _contentType,
                                attachment: _attachment,
                                isScanning: _isScanning,
                                ocrText: _ocrText,
                                onPick: busy ? null : _pickAttachment,
                                onClear: busy
                                    ? null
                                    : () => setState(() {
                                        _attachment = null;
                                        _ocrText = '';
                                      }),
                              ),
                            ],
                            const SizedBox(height: 20),
                            const FieldLabel('Deal Title *'),
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                hintText:
                                    'e.g., Partnership Agreement with ABC Corp',
                              ),
                              validator: (value) =>
                                  Validators.required(value, field: 'Title'),
                            ),
                            const SizedBox(height: 18),
                            const FieldLabel('Description *'),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText: 'Provide details about this deal...',
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
                            const SizedBox(height: 18),
                            const FieldLabel('Creation Date'),
                            TextFormField(
                              controller: _dateController,
                              readOnly: true,
                              onTap: _selectDate,
                              decoration: const InputDecoration(
                                hintText: 'Select date',
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),
                            _SubHeading(
                              title: 'Participants',
                              count: _buildParties().length,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Optional. Leave blank to invite people later.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            for (
                              var i = 0;
                              i < _participantControllers.length;
                              i++
                            ) ...[
                              _ParticipantRow(
                                key: ValueKey(_participantControllers[i]),
                                emailController: _participantControllers[i],
                                role: _participantRoles[i],
                                onRoleChanged: (value) => setState(
                                  () => _participantRoles[i] = value,
                                ),
                                onRemove: _participantControllers.length > 1
                                    ? () => _removeParticipant(i)
                                    : null,
                              ),
                              const SizedBox(height: 12),
                            ],
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _addParticipant,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Participant'),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 16),
                            _SubHeading(
                              title: 'Additional Sections',
                              count: _sections.length,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add as many titled blocks as the agreement needs.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (_sections.isEmpty)
                              _NoSectionsHint(onAdd: _addSection)
                            else
                              for (var i = 0; i < _sections.length; i++) ...[
                                _DealSectionEditor(
                                  key: ValueKey(_sections[i]),
                                  index: i,
                                  controllers: _sections[i],
                                  onRemove: () => _removeSection(i),
                                ),
                                const SizedBox(height: 12),
                              ],
                            if (_sections.isNotEmpty)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: _addSection,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add section'),
                                ),
                              ),
                            const SizedBox(height: 20),
                            const _DocumentNotice(),
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: busy
                                        ? null
                                        : () => context.go(AppRoutes.deals),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: busy ? null : _createDeal,
                                    child: isCreating
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Create Deal'),
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
  return cleaned.isEmpty ? 'deal' : cleaned;
}

class _ContentTypePicker extends StatelessWidget {
  final DealContentType selected;
  final ValueChanged<DealContentType> onChanged;

  const _ContentTypePicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final type in DealContentType.values) ...[
          _ContentTypeTile(
            type: type,
            selected: type == selected,
            onTap: () => onChanged(type),
          ),
          if (type != DealContentType.values.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ContentTypeTile extends StatelessWidget {
  final DealContentType type;
  final bool selected;
  final VoidCallback onTap;

  const _ContentTypeTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              dealContentTypeIcon(type),
              size: 20,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _AttachmentPicker extends StatelessWidget {
  final DealContentType contentType;
  final PickedFileData? attachment;
  final bool isScanning;
  final String ocrText;
  final VoidCallback? onPick;
  final VoidCallback? onClear;

  const _AttachmentPicker({
    required this.contentType,
    required this.attachment,
    required this.isScanning,
    required this.ocrText,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                dealContentTypeIcon(contentType),
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  attachment?.name ??
                      'No ${contentType.label.toLowerCase()} attached',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: attachment == null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              if (attachment != null && onClear != null)
                IconButton(
                  onPressed: onClear,
                  tooltip: 'Remove attachment',
                  icon: Icon(Icons.delete_outline, color: AppColors.error),
                ),
              TextButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload_file_outlined, size: 18),
                label: Text(attachment == null ? 'Attach' : 'Replace'),
              ),
            ],
          ),
          if (isScanning) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  'Reading the document with OCR…',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ] else if (ocrText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Extracted text',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ocrText,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DocumentNotice extends StatelessWidget {
  const _DocumentNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.picture_as_pdf_outlined,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'A PDF document with everything you entered is generated once the deal is created.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubHeading extends StatelessWidget {
  final String title;
  final int count;

  const _SubHeading({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TemplateBanner extends StatelessWidget {
  final String name;

  const _TemplateBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_outlined, size: 18, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Prefilled from template "$name"',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  final TextEditingController emailController;
  final String role;
  final ValueChanged<String> onRoleChanged;
  final VoidCallback? onRemove;

  const _ParticipantRow({
    super.key,
    required this.emailController,
    required this.role,
    required this.onRoleChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'participant@example.com',
              isDense: true,
            ),
            // Participants are optional; only a non-empty value must be valid.
            validator: (value) => (value == null || value.trim().isEmpty)
                ? null
                : Validators.email(value),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            initialValue: role,
            isDense: true,
            items: [
              for (final r in kDealRoles)
                DropdownMenuItem(value: r, child: Text(r)),
            ],
            onChanged: (value) {
              if (value != null) onRoleChanged(value);
            },
          ),
        ),
        if (onRemove != null) ...[
          const SizedBox(width: 4),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove participant',
            icon: Icon(Icons.delete_outline, color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

class _DealSectionEditor extends StatelessWidget {
  final int index;
  final _SectionControllers controllers;
  final VoidCallback onRemove;

  const _DealSectionEditor({
    super.key,
    required this.index,
    required this.controllers,
    required this.onRemove,
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
              const SizedBox(width: 6),
              IconButton(
                onPressed: onRemove,
                tooltip: 'Remove section',
                icon: Icon(Icons.delete_outline, color: AppColors.error),
              ),
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

class _NoSectionsHint extends StatelessWidget {
  final VoidCallback onAdd;

  const _NoSectionsHint({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          color: AppColors.surface.withValues(alpha: 0.3),
        ),
        child: Column(
          children: [
            Icon(Icons.add_circle_outline, color: AppColors.primary, size: 26),
            const SizedBox(height: 8),
            Text(
              'Add a section',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Payment terms, deliverables, exit clauses…',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}
