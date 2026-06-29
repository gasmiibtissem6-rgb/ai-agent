import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../shared/ideal_ui.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});
  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _isScanning = false;
  String _scannedText = '';
  final _editController = TextEditingController();
  List<Offset?> _signaturePoints = [];
  bool _showSignature = false;

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _pickFile({bool imageOnly = false}) {
    final input = html.FileUploadInputElement();
    input.accept = imageOnly ? 'image/*' : 'image/*,application/pdf';
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
        final raw = response.data;
        final data = raw is Map ? (raw['data'] ?? raw) : raw;
        final success = data['success'] == true;
        final text = (data['text'] ?? '') as String;
        if (success && text.isNotEmpty) {
          setState(() {
            _scannedText = text;
            _editController.text = text;
          });
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Document scanné !'), backgroundColor: Colors.green),
          );
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ ${data['message']}'), backgroundColor: Colors.orange),
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

  void _downloadPdf() async {
    try {
      final dio = Dio();
      final response = await dio.post(
        'http://localhost:3001/api/chat/generate-pdf',
        data: {'content': _editController.text, 'title': 'Contrat'},
        options: Options(responseType: ResponseType.bytes),
      );
      final blob = html.Blob([response.data], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'contrat.pdf')
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Erreur export PDF'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IdealAppScaffold(
      activeRoute: 'documents',
      body: IdealGradientBackground(
        child: _scannedText.isEmpty ? _buildImportScreen(colorScheme) : _buildEditScreen(colorScheme),
      ),
    );
  }

  Widget _buildImportScreen(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.document_scanner, size: 80, color: colorScheme.primary.withOpacity(0.5)),
            const SizedBox(height: 24),
            Text('Scanner & Importer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text('Scannez ou importez un contrat pour le modifier et le signer',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: 40),
            if (_isScanning)
              const CircularProgressIndicator()
            else ...[
              _buildCard(colorScheme, Icons.camera_alt, 'Prendre une photo', 'Appareil photo', Colors.blue, () => _pickFile(imageOnly: true)),
              const SizedBox(height: 16),
              _buildCard(colorScheme, Icons.upload_file, 'Importer un fichier', 'PDF ou image depuis votre appareil', Colors.green, () => _pickFile()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard(ColorScheme c, IconData icon, String title, String sub, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: c.onSurface, fontSize: 16)),
            Text(sub, style: TextStyle(color: c.onSurface.withOpacity(0.6), fontSize: 13)),
          ]),
          const Spacer(),
          Icon(Icons.arrow_forward_ios, color: color, size: 16),
        ]),
      ),
    );
  }

  Widget _buildEditScreen(ColorScheme colorScheme) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: colorScheme.surface,
        child: Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() { _scannedText = ''; _signaturePoints = []; })),
          const Text('Modifier le contrat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.draw, color: Colors.purple), tooltip: 'Signer',
            onPressed: () => setState(() => _showSignature = !_showSignature)),
          IconButton(icon: const Icon(Icons.picture_as_pdf, color: Colors.red), tooltip: 'Exporter PDF', onPressed: _downloadPdf),
        ]),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(
              controller: _editController,
              maxLines: null,
              style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
              decoration: InputDecoration(
                filled: true, fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            if (_showSignature) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.withOpacity(0.5))),
                child: Column(children: [
                  Padding(padding: const EdgeInsets.all(8),
                    child: Row(children: [
                      const Text('✍️ Zone de signature', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton(onPressed: () => setState(() => _signaturePoints = []),
                        child: const Text('Effacer', style: TextStyle(color: Colors.red))),
                    ])),
                  SizedBox(height: 150,
                    child: GestureDetector(
                      onPanUpdate: (d) => setState(() => _signaturePoints.add(d.localPosition)),
                      onPanEnd: (_) => setState(() => _signaturePoints.add(null)),
                      child: CustomPaint(painter: _SignaturePainter(_signaturePoints), child: Container()),
                    )),
                ]),
              ),
            ],
          ]),
        ),
      ),
    ]);
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  _SignaturePainter(this.points);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.purple..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) canvas.drawLine(points[i]!, points[i + 1]!, paint);
    }
  }
  @override
  bool shouldRepaint(_SignaturePainter old) => true;
}
