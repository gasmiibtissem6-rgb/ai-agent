import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/kyc_model.dart';
import '../domain/kyc_provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/ideal_ui.dart';

class KycUploadScreen extends ConsumerStatefulWidget {
  const KycUploadScreen({super.key});

  @override
  ConsumerState<KycUploadScreen> createState() => _KycUploadScreenState();
}

class _KycUploadScreenState extends ConsumerState<KycUploadScreen> {
  KycDocumentType _selectedType = KycDocumentType.nationalId;
  PlatformFile? _frontFile;
  PlatformFile? _backFile;
  PlatformFile? _selfieFile;

  Future<void> _pickFile(String slot) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        switch (slot) {
          case 'front':
            _frontFile = result.files.first;
            break;
          case 'back':
            _backFile = result.files.first;
            break;
          case 'selfie':
            _selfieFile = result.files.first;
            break;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_frontFile?.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload the front of your document.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_selfieFile?.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a selfie with your document.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    await ref
        .read(kycProvider.notifier)
        .submitKyc(
          documentType: _selectedType,
          frontBytes: _frontFile!.bytes!,
          frontFileName: _frontFile!.name,
          backBytes: _backFile?.bytes,
          backFileName: _backFile?.name,
          selfieBytes: _selfieFile!.bytes!,
          selfieFileName: _selfieFile!.name,
        );
  }

  @override
  Widget build(BuildContext context) {
    final kycAsync = ref.watch(kycProvider);
    final kycState = kycAsync.whenOrNull(data: (s) => s);
    final isUploading = kycState?.isUploading ?? false;
    final progress = kycState?.uploadProgress ?? 0;

    ref.listen(kycProvider, (_, next) {
      final state = next.whenOrNull(data: (s) => s);
      if (state?.isSuccess == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KYC submitted! We will review it shortly.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(AppRoutes.kycStatus);
      }
      if (state?.hasError == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state!.errorMessage ?? 'Upload failed.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return IdealAppScaffold(
      activeRoute: 'kyc',
      showBack: true,
      body: IdealGradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRoutes.kycStatus),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: SectionTitle(
                      title: 'Upload Documents',
                      subtitle: 'Submit identity files for secure review.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              IdealCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select document type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: KycDocumentType.values.map((type) {
                        final isSelected = type == _selectedType;
                        final label = type == KycDocumentType.nationalId
                            ? 'National ID'
                            : type == KycDocumentType.passport
                            ? 'Passport'
                            : 'Driver License';
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedType = type),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Upload documents',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FileUploadCard(
                      label: 'Front of document',
                      subtitle: 'Clear photo of the front side',
                      required: true,
                      file: _frontFile,
                      onTap: () => _pickFile('front'),
                    ),
                    const SizedBox(height: 12),
                    _FileUploadCard(
                      label: 'Back of document',
                      subtitle: 'Clear photo of the back side',
                      required: false,
                      file: _backFile,
                      onTap: () => _pickFile('back'),
                    ),
                    const SizedBox(height: 12),
                    _FileUploadCard(
                      label: 'Selfie with document',
                      subtitle: 'Hold your document next to your face',
                      required: true,
                      file: _selfieFile,
                      onTap: () => _pickFile('selfie'),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Security notice',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your documents are encrypted and stored in a private secure bucket. Only authorized reviewers can access them.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (isUploading) ...[
                      Text(
                        'Uploading... ${(progress * 100).toInt()}%',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton(
                      onPressed: isUploading ? null : _submit,
                      child: isUploading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Submit for verification'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileUploadCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool required;
  final PlatformFile? file;
  final VoidCallback onTap;

  const _FileUploadCard({
    required this.label,
    required this.subtitle,
    required this.required,
    required this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasFile
              ? AppColors.success.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? AppColors.success : AppColors.border,
            width: hasFile ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasFile
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasFile
                    ? Icons.check_circle_outline
                    : Icons.upload_file_outlined,
                color: hasFile ? AppColors.success : AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (required) ...[
                        const SizedBox(width: 4),
                        const Text(
                          '*',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasFile ? file!.name : subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasFile
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
