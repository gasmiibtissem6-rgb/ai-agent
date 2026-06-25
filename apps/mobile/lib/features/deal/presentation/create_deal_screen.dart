import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/deal_provider.dart';
import '../domain/deal_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';

class CreateDealScreen extends ConsumerStatefulWidget {
  const CreateDealScreen({super.key});

  @override
  ConsumerState<CreateDealScreen> createState() => _CreateDealScreenState();
}

class _CreateDealScreenState extends ConsumerState<CreateDealScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _createDeal() async {
    if (!_formKey.currentState!.validate()) return;
    final deal = await ref.read(dealProvider.notifier).createDeal(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          content: _contentController.text.trim(),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Create Deal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deal details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Deal title',
                  prefixIcon: Icon(Icons.title_outlined),
                ),
                validator: (v) => Validators.required(v, field: 'Title'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                textInputAction: TextInputAction.next,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Short description',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                validator: (v) =>
                    Validators.required(v, field: 'Description'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Deal terms',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Write the full terms and conditions of this deal.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                maxLines: 10,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Deal content',
                  alignLabelWithHint: true,
                ),
                validator: (v) => Validators.required(v, field: 'Content'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
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
                    : const Text('Create deal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}