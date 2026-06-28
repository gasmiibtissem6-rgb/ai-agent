import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ScanContractButton extends StatefulWidget {
  final Function(String text) onTextExtracted;
  const ScanContractButton({super.key, required this.onTextExtracted});

  @override
  State<ScanContractButton> createState() => _ScanContractButtonState();
}

class _ScanContractButtonState extends State<ScanContractButton> {
  bool _isScanning = false;

  void _pickAndScan() {
    final input = html.FileUploadInputElement();
    input.accept = 'image/*';
    input.click();
    input.onChange.listen((e) async {
      final file = input.files?.first;
      if (file == null) return;
      setState(() => _isScanning = true);
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      await reader.onLoad.first;
      final base64 = reader.result as String;
      try {
        final dio = Dio();
        final response = await dio.post(
          'http://localhost:3001/api/chat/scan-contract',
          data: {'image': base64, 'lang': 'fra+eng+ara'},
        );
        if (response.data['success'] == true) {
          widget.onTextExtracted(response.data['text'] as String);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Contrat scanné !'), backgroundColor: Colors.green),
          );
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ ${response.data['message']}'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Erreur de scan'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isScanning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isScanning
        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
        : IconButton(
            icon: const Icon(Icons.document_scanner),
            tooltip: 'Scanner un contrat papier',
            color: Theme.of(context).colorScheme.primary,
            onPressed: _pickAndScan,
          );
  }
}
