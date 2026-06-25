// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/responsive_scaffold.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends State<IdentityVerificationScreen> {
  int _step = 1;
  String _selectedDocType = 'National ID Card';
  
  String? _idFileName;
  bool _idUploading = false;
  double _idUploadProgress = 0.0;
  
  String? _selfieFileName;
  bool _selfieUploading = false;
  double _selfieUploadProgress = 0.0;

  final List<Map<String, dynamic>> _docTypes = [
    {
      'type': 'National ID Card',
      'description': 'Government issued national identity card.',
      'icon': Icons.badge_outlined,
    },
    {
      'type': 'Passport',
      'description': 'International passport document page.',
      'icon': Icons.import_contacts_outlined,
    },
    {
      'type': 'Driver\'s License',
      'description': 'Valid driver\'s permit card.',
      'icon': Icons.drive_eta_outlined,
    },
  ];

  void _showImageSourcePicker(String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF121C2F) 
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : const Color(0xFF0C1D33);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Select Image Source',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.camera_alt_outlined, color: theme.primaryColor),
                  title: Text('Take Photo (Camera)', style: TextStyle(color: textColor)),
                  onTap: () {
                    Navigator.pop(context);
                    _simulateUpload(type, 'camera');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.photo_library_outlined, color: theme.primaryColor),
                  title: Text('Choose from Gallery', style: TextStyle(color: textColor)),
                  onTap: () {
                    Navigator.pop(context);
                    _simulateUpload(type, 'gallery');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _simulateUpload(String type, String source) {
    setState(() {
      if (type == 'id') {
        _idUploading = true;
        _idUploadProgress = 0.0;
        _idFileName = null;
      } else {
        _selfieUploading = true;
        _selfieUploadProgress = 0.0;
        _selfieFileName = null;
      }
    });

    double progress = 0.0;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      progress += 0.1;
      if (progress >= 1.0) {
        progress = 1.0;
        timer.cancel();
        setState(() {
          if (type == 'id') {
            _idUploading = false;
            _idFileName = '${_selectedDocType.toLowerCase().replaceAll(' ', '_')}_$source.jpg';
          } else {
            _selfieUploading = false;
            _selfieFileName = 'selfie_$source.jpg';
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type == 'id' ? _selectedDocType : 'Selfie'} captured via $source successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          if (type == 'id') {
            _idUploadProgress = progress;
          } else {
            _selfieUploadProgress = progress;
          }
        });
      }
    });
  }

  void _handleNext() {
    if (_step < 4) {
      setState(() => _step++);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Identity verification submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/profile');
    }
  }

  void _handleBack() {
    if (_step > 1) {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bool nextDisabled = 
        (_step == 2 && _idFileName == null && !_idUploading) || 
        (_step == 3 && _selfieFileName == null && !_selfieUploading) ||
        (_step == 2 && _idUploading) ||
        (_step == 3 && _selfieUploading);

    return ResponsiveScaffold(
      activeRoute: 'settings',
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0B1220), const Color(0xFF121C2F)]
                : [const Color(0xFFF3F7FA), const Color(0xFFD6E2EE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/profile'),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KYC Verification',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Secure identity verification for secure deal closing',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Step Stepper Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF121C2F) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFD6E2EE),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildStepNode(1, _step),
                        _buildStepLine(1, _step, theme),
                        _buildStepNode(2, _step),
                        _buildStepLine(2, _step, theme),
                        _buildStepNode(3, _step),
                        _buildStepLine(3, _step, theme),
                        _buildStepNode(4, _step),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Select Doc', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('Upload ID', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('Selfie', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Text('Review', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Main Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF121C2F) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFD6E2EE),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Step 1: Selection
                    if (_step == 1) ...[
                      const Text(
                        'Select Document Type',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose one of the following official government documents to verify your identity.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      ..._docTypes.map((doc) {
                        final isSelected = _selectedDocType == doc['type'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedDocType = doc['type']),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? theme.primaryColor.withValues(alpha: 0.05) 
                                  : (isDark ? const Color(0xFF0B1220) : const Color(0xFFF3F7FA)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? theme.primaryColor 
                                    : (isDark ? const Color(0xFF1E2D4A) : const Color(0xFFD6E2EE)),
                                width: isSelected ? 2.0 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  doc['icon'] as IconData,
                                  size: 28,
                                  color: isSelected ? theme.primaryColor : Colors.grey,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doc['type'] as String,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isDark ? Colors.white : const Color(0xFF0C1D33),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        doc['description'] as String,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Radio<String>(
                                  value: doc['type'] as String,
                                  groupValue: _selectedDocType,
                                  activeColor: theme.primaryColor,
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedDocType = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],

                    // Step 2: Upload Document Photo
                    if (_step == 2) ...[
                      Text(
                        'Upload $_selectedDocType',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Provide a clear, readable digital image of your $_selectedDocType. Ensure all text and corners are visible.',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      _buildUploadSection(
                        type: 'id',
                        fileName: _idFileName,
                        isUploading: _idUploading,
                        progress: _idUploadProgress,
                        isDark: isDark,
                        theme: theme,
                      ),
                    ],

                    // Step 3: Selfie Verification
                    if (_step == 3) ...[
                      const Text(
                        'Take a Selfie',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please verify your face structure. Hold your camera straight and ensure your face is fully lit and uncovered.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      _buildUploadSection(
                        type: 'selfie',
                        fileName: _selfieFileName,
                        isUploading: _selfieUploading,
                        progress: _selfieUploadProgress,
                        isDark: isDark,
                        theme: theme,
                      ),
                    ],

                    // Step 4: Final Review
                    if (_step == 4) ...[
                      const Text(
                        'Verification Review',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Verify all parameters are correct. Your data will be safely encrypted and checked.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      
                      // Review details
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0B1220) : const Color(0xFFF3F7FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFD6E2EE),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildReviewRow('Selected Document', _selectedDocType),
                            const Divider(height: 24),
                            _buildReviewRow('Document File', _idFileName ?? ''),
                            const Divider(height: 24),
                            _buildReviewRow('Selfie File', _selfieFileName ?? ''),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Security guarantee banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.shield_outlined, color: Colors.green, size: 24),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Secure Fintech Layer',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'All credentials are fully hashed via military-grade SSL standards. Documents are automatically deleted from server caches after confirmation.',
                                    style: TextStyle(fontSize: 12, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Actions
                    Row(
                      children: [
                        if (_step > 1) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _handleBack,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: BorderSide(color: theme.primaryColor),
                              ),
                              child: Text('Back', style: TextStyle(color: theme.primaryColor)),
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        Expanded(
                          child: ElevatedButton(
                            onPressed: nextDisabled ? null : _handleNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              _step == 4 ? 'Confirm & Submit' : 'Next',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildStepNode(int nodeStep, int currentStep) {
    final bool isCompleted = currentStep > nodeStep;
    final bool isActive = currentStep == nodeStep;
    return Container(
      height: 32,
      width: 32,
      decoration: BoxDecoration(
        color: isCompleted || isActive ? const Color(0xFF02529C) : Colors.grey.shade300,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? Colors.white : Colors.transparent,
          width: 2,
        ),
        boxShadow: isActive ? [
          const BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ] : null,
      ),
      alignment: Alignment.center,
      child: isCompleted
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : Text(
              nodeStep.toString(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
    );
  }

  Widget _buildStepLine(int startStep, int currentStep, ThemeData theme) {
    final bool isCompleted = currentStep > startStep;
    return Expanded(
      child: Container(
        height: 3,
        color: isCompleted ? const Color(0xFF02529C) : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildUploadSection({
    required String type,
    required String? fileName,
    required bool isUploading,
    required double progress,
    required bool isDark,
    required ThemeData theme,
  }) {
    if (isUploading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B1220) : const Color(0xFFF3F7FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Uploading to secure server... ${(progress * 100).toInt()}%',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            ),
          ],
        ),
      );
    }

    if (fileName != null) {
      // Preview State
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B1220) : const Color(0xFFF3F7FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_outlined, size: 20, color: Colors.grey),
                  onPressed: () => _showImageSourcePicker(type),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Mock preview card layout depending on file type
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF121C2F) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Mock Document Template Graphics
                    Opacity(
                      opacity: 0.15,
                      child: Icon(
                        type == 'id' ? Icons.badge : Icons.face,
                        size: 90,
                        color: theme.primaryColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            type == 'id' ? Icons.verified_user : Icons.portrait,
                            color: theme.primaryColor,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            type == 'id' ? 'KYC: $_selectedDocType' : 'Face Verification Portrait',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Metadata: JPEG 2048x1536 • 2.4 MB',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PREVIEW READY',
                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1220) : const Color(0xFFF3F7FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E2D4A) : const Color(0xFFD6E2EE),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            type == 'id' ? Icons.cloud_upload_outlined : Icons.portrait_outlined,
            size: 48,
            color: theme.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            type == 'id' ? 'Upload $_selectedDocType' : 'Provide Facial Selfie',
            style: TextStyle(fontWeight: FontWeight.bold, color: theme.primaryColor, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ensure the image is sharp and without light reflections.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showImageSourcePicker(type),
                icon: const Icon(Icons.camera_alt_outlined, size: 18, color: Colors.white),
                label: const Text('Capture Image', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey),
        ),
        Text(
          value.isEmpty ? 'Not Provided' : value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: value.isEmpty ? Colors.red : Colors.green,
          ),
        ),
      ],
    );
  }
}
