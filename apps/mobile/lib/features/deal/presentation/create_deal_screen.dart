import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../domain/deal_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/ideal_ui.dart';

class CreateDealScreen extends ConsumerStatefulWidget {
  const CreateDealScreen({super.key});

  @override
  ConsumerState<CreateDealScreen> createState() => _CreateDealScreenState();
}

class _CreateDealScreenState extends ConsumerState<CreateDealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final List<TextEditingController> _participantControllers = [
    TextEditingController(),
  ];

  String _category = 'Partnership';
  final List<String> _participantRoles = ['Partner'];

  final List<String> _categories = [
    'Partnership',
    'Investment',
    'Service',
    'Supply',
    'License',
  ];
  final List<String> _roles = [
    'Owner',
    'Partner',
    'Investor',
    'Supplier',
    'Client',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    for (final controller in _participantControllers) {
      controller.dispose();
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _createDeal() async {
    if (!_formKey.currentState!.validate()) return;

    final participantSummary = List.generate(_participantControllers.length, (
      index,
    ) {
      return '- ${_participantControllers[index].text.trim()} (${_participantRoles[index]})';
    }).join('\n');

    final content =
        '''
Category: $_category
Expiration Date: ${_dateController.text.isEmpty ? 'Not set' : _dateController.text}

Participants:
$participantSummary

Description:
${_descriptionController.text.trim()}
''';

    final deal = await ref
        .read(dealProvider.notifier)
        .createDeal(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          content: content.trim(),
        );
    if (deal != null && mounted) {
      context.go(AppRoutes.dealDetail, extra: deal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dealAsync = ref.watch(dealProvider);
    final dealState = dealAsync.whenOrNull(data: (s) => s);
    final isCreating = dealState?.isCreating ?? false;

    ref.listen(dealProvider, (_, next) {
      final state = next.whenOrNull(data: (s) => s);
      if (state?.hasError == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state!.errorMessage ?? 'Failed to create deal.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return IdealAppScaffold(
      activeRoute: 'deals',
      showBack: true,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.surface, AppColors.surfaceAlt],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Deal',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Set up a new agreement with participants',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Deal Title *'),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Partnership Agreement with ABC Corp',
                        ),
                        validator: (value) =>
                            Validators.required(value, field: 'Title'),
                      ),
                      const SizedBox(height: 20),
                      const _FieldLabel('Description'),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Provide details about this deal...',
                        ),
                        validator: (value) =>
                            Validators.required(value, field: 'Description'),
                      ),
                      const SizedBox(height: 20),
                      const _FieldLabel('Category *'),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _category = value);
                        },
                      ),
                      const SizedBox(height: 20),
                      const _FieldLabel('Expiration Date'),
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
                      const Text(
                        'Participants',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _participantControllers.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _participantControllers[index],
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    hintText: 'participant@example.com',
                                  ),
                                  validator: Validators.email,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _participantRoles[index],
                                  items: _roles.map((role) {
                                    return DropdownMenuItem(
                                      value: role,
                                      child: Text(role),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _participantRoles[index] = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                              if (_participantControllers.length > 1) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _removeParticipant(index),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _addParticipant,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Participant'),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isCreating
                                  ? null
                                  : () => context.go(AppRoutes.deals),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isCreating ? null : _createDeal,
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
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
