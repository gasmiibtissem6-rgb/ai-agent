import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../shared/platform_file_picker.dart';

class ScanContractButton extends StatefulWidget {
  final Function(String text, String imageBase64) onTextExtracted;
  const ScanContractButton({super.key, required this.onTextExtracted});

  @override
  State<ScanContractButton> createState() => _ScanContractButtonState();
}

class _ScanContractButtonState extends State<ScanContractButton> {
  bool _isScanning = false;

  Future<void> _pickAndScan() async {
    final file = await pickSingleFile(
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
    );
    if (file == null) return;

    setState(() => _isScanning = true);
    try {
      final dio = Dio();
      final response = await dio.post(
        '${ApiConfig.baseUrl}/chat/scan-contract',
        data: {'image': file.dataUrl, 'lang': 'fra+eng+ara'},
      );
      final raw = response.data;
      final data = raw is Map ? (raw['data'] ?? raw) : raw;
      final success = data['success'] == true;
      final text = (data['text'] ?? '') as String;
      if (success && text.isNotEmpty) {
        widget.onTextExtracted(text, file.dataUrl);
      } else if (data['message'] == null && text.isEmpty) {
        widget.onTextExtracted('', file.dataUrl);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Contrat scanné !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final msg = (data['message'] ?? 'Aucun texte détecté') as String;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ $msg'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erreur de scan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _isScanning = false);
  }

  @override
  Widget build(BuildContext context) {
    return _isScanning
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : IconButton(
            icon: const Icon(Icons.document_scanner),
            tooltip: 'Scanner un contrat papier',
            color: Theme.of(context).colorScheme.primary,
            onPressed: _pickAndScan,
          );
  }
}
