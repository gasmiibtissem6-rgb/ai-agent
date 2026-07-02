import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:dio/dio.dart';
import '../../../core/config/api_config.dart';
import '../../../shared/file_saver.dart';
import '../../../shared/ideal_ui.dart';
import '../../../shared/platform_file_picker.dart';

class MediaItem {
  final String type; // 'image' or 'video'
  final String data; // base64
  final String? thumbnail; // base64 thumbnail for videos
  String caption;
  String date;
  MediaItem({
    required this.type,
    required this.data,
    this.thumbnail,
    this.caption = '',
    required this.date,
  });
}

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});
  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  bool _isScanning = false;
  String _scannedText = '';
  final _editController = TextEditingController();
  bool _showSignature = false;
  String? _signatureImageBase64;
  final List<MediaItem> _mediaItems = [];

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _pickFile({bool imageOnly = false}) {
    _handlePickFile(imageOnly: imageOnly);
  }

  Future<void> _handlePickFile({bool imageOnly = false}) async {
    final file = await pickSingleFile(
      allowedExtensions: imageOnly
          ? ['png', 'jpg', 'jpeg', 'webp']
          : ['png', 'jpg', 'jpeg', 'webp', 'pdf'],
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
      final text = (data['text'] ?? '') as String;
      if (text.isNotEmpty) {
        setState(() {
          _scannedText = text;
          _editController.text = text;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document scanné !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun texte détecté'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur de scan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _isScanning = false);
  }

  void _addMedia({bool videoOnly = false}) {
    _handleAddMedia(videoOnly: videoOnly);
  }

  Future<void> _handleAddMedia({bool videoOnly = false}) async {
    final files = await pickMultipleFiles(
      allowedExtensions: videoOnly
          ? ['mp4', 'mov', 'avi', 'mkv']
          : ['png', 'jpg', 'jpeg', 'webp', 'mp4', 'mov', 'avi', 'mkv'],
    );
    if (files.isEmpty) return;

    for (final file in files) {
      final fileName = file.name.toLowerCase();
      final isVideo =
          fileName.endsWith('.mp4') ||
          fileName.endsWith('.mov') ||
          fileName.endsWith('.avi') ||
          fileName.endsWith('.mkv');
      setState(() {
        _mediaItems.add(
          MediaItem(
            type: isVideo ? 'video' : 'image',
            data: file.dataUrl,
            thumbnail: null,
            caption: file.name.split('.').first,
            date: DateTime.now().toLocal().toString().split(' ')[0],
          ),
        );
      });
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${files.length} fichier(s) ajouté(s)'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showSignatureDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SignatureDialog(
        onSigned: (sig) {
          setState(() {
            _showSignature = true;
            _signatureImageBase64 = sig.isNotEmpty ? sig : null;
            if (!_editController.text.contains('signé électroniquement')) {
              _editController.text +=
                  '\n\n--- Document signé électroniquement le '
                  '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ---';
            }
          });
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Signature apposée !'),
                backgroundColor: Colors.green,
              ),
            );
        },
      ),
    );
  }

  void _downloadPdf() async {
    try {
      final dio = Dio();
      final mediaPayload = _mediaItems
          .map(
            (m) => {
              'type': m.type,
              'data': m.type == 'image' ? m.data : (m.thumbnail ?? m.data),
              'thumbnail': m.thumbnail,
              'caption': m.caption,
              'date': m.date,
            },
          )
          .toList();
      final response = await dio.post(
        '${ApiConfig.baseUrl}/chat/generate-pdf',
        data: {
          'content': _editController.text,
          'title': 'Contrat',
          if (_signatureImageBase64 != null)
            'signatureImage': _signatureImageBase64,
          if (_mediaItems.isNotEmpty) 'mediaItems': mediaPayload,
        },
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data is Uint8List
          ? response.data as Uint8List
          : Uint8List.fromList(List<int>.from(response.data as List));
      await savePdfBytes(bytes, 'contrat.pdf');
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur export PDF'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IdealAppScaffold(
      activeRoute: 'documents',
      body: IdealGradientBackground(
        child: _scannedText.isEmpty
            ? _buildImportScreen(cs)
            : _buildEditScreen(cs),
      ),
    );
  }

  Widget _buildImportScreen(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.document_scanner,
              size: 80,
              color: cs.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Scanner & Importer',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scannez ou importez un contrat pour le modifier, ajouter des photos/vidéos et le signer',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 40),
            if (_isScanning)
              const CircularProgressIndicator()
            else ...[
              _buildCard(
                cs,
                Icons.camera_alt,
                'Prendre une photo',
                'Appareil photo ou fichier image',
                Colors.blue,
                () => _pickFile(imageOnly: true),
              ),
              const SizedBox(height: 16),
              _buildCard(
                cs,
                Icons.upload_file,
                'Importer un fichier',
                'PDF ou image depuis votre appareil',
                Colors.green,
                () => _pickFile(),
              ),
              const SizedBox(height: 16),
              _buildCard(
                cs,
                Icons.edit_document,
                'Nouveau contrat vide',
                'Rédiger depuis zéro',
                Colors.purple,
                () {
                  setState(() {
                    _scannedText = ' ';
                    _editController.text = '';
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    ColorScheme c,
    IconData icon,
    String title,
    String sub,
    Color color,
    VoidCallback onTap,
  ) {
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: c.onSurface,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    sub,
                    style: TextStyle(
                      color: c.onSurface.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEditScreen(ColorScheme cs) {
    return Column(
      children: [
        // Barre d'outils
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: cs.surface,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _scannedText = '';
                  _mediaItems.clear();
                  _showSignature = false;
                  _signatureImageBase64 = null;
                }),
              ),
              const Text(
                'Contrat',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_photo_alternate, color: Colors.teal),
                tooltip: 'Ajouter photo/vidéo',
                onPressed: _addMedia,
              ),
              IconButton(
                icon: Icon(
                  Icons.draw,
                  color: _showSignature ? Colors.green : Colors.purple,
                ),
                tooltip: 'Signer',
                onPressed: _showSignatureDialog,
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                tooltip: 'Exporter PDF',
                onPressed: _downloadPdf,
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Zone texte
                TextField(
                  controller: _editController,
                  maxLines: null,
                  style: TextStyle(color: cs.onSurface, fontSize: 13),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: cs.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    hintText: 'Contenu du contrat...',
                  ),
                ),

                // Galerie médias
                if (_mediaItems.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(
                        Icons.photo_library,
                        size: 18,
                        color: Colors.teal,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Pièces jointes (${_mediaItems.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.teal,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addMedia,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Ajouter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.3,
                        ),
                    itemCount: _mediaItems.length,
                    itemBuilder: (ctx, i) => _buildMediaCard(cs, i),
                  ),
                ],

                // Badge signature
                if (_showSignature) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Document signé électroniquement',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_signatureImageBase64 != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              _signatureImageBase64!,
                              height: 40,
                              fit: BoxFit.contain,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaCard(ColorScheme cs, int index) {
    final item = _mediaItems[index];
    final previewData = item.thumbnail ?? item.data;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: item.type == 'image'
                      ? Image.network(previewData, fit: BoxFit.cover)
                      : Container(
                          color: cs.surfaceContainerHigh,
                          child: const Center(
                            child: Icon(
                              Icons.videocam,
                              size: 36,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                ),
                if (item.type == 'video')
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => setState(() => _mediaItems.removeAt(index)),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: item.caption),
                    onChanged: (v) => item.caption = v,
                    style: const TextStyle(fontSize: 11),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Légende...',
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  item.date,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dialogue de signature ─────────────────────────────────────────────────
class _SignatureDialog extends StatefulWidget {
  final Function(String) onSigned;
  const _SignatureDialog({required this.onSigned});
  @override
  State<_SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<_SignatureDialog> {
  final GlobalKey _signatureBoundaryKey = GlobalKey();
  int _tab = 0;
  List<Offset?> _points = [];
  bool _hasSignature = false;
  bool _isProcessing = false;
  String? _cameraImageBase64;
  bool _useCameraCapture = false;

  Future<void> _onTerminer() async {
    setState(() => _isProcessing = true);
    String signature = '';
    if (_tab == 0) {
      signature = await _captureDrawing();
    } else {
      signature = _cameraImageBase64 ?? '';
    }
    setState(() => _isProcessing = false);
    if (!mounted) return;
    Navigator.pop(context);
    widget.onSigned(signature);
  }

  Future<String> _captureDrawing() async {
    try {
      final boundary =
          _signatureBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        return '';
      }
      final image = await boundary.toImage(pixelRatio: 2);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return '';
      }
      final bytes = byteData.buffer.asUint8List();
      return 'data:image/png;base64,${base64Encode(bytes)}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Signature',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [_tabBtn('✍️ Dessiner', 0), _tabBtn('📷 Caméra', 1)],
              ),
            ),
            const SizedBox(height: 12),
            if (_tab == 0)
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: RepaintBoundary(
                  key: _signatureBoundaryKey,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (d) => setState(() {
                        _points.add(d.localPosition);
                        _hasSignature = true;
                      }),
                      onPanEnd: (_) => setState(() => _points.add(null)),
                      child: CustomPaint(
                        painter: _SigPainter(_points),
                        child: _points.isEmpty
                            ? Center(
                                child: Text(
                                  'Dessinez votre signature',
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              )
            else if (!_useCameraCapture && _cameraImageBase64 == null)
              GestureDetector(
                onTap: () async {
                  final file = await pickSingleFile(
                    allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
                  );
                  if (file == null) return;
                  setState(() {
                    _cameraImageBase64 = file.dataUrl;
                    _hasSignature = true;
                  });
                },
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.4)),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.upload_file, size: 40, color: Colors.blue),
                        SizedBox(height: 8),
                        Text(
                          'Importer une photo de votre signature',
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '(signez sur papier blanc, prenez une photo)',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_cameraImageBase64 != null)
              Stack(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _cameraImageBase64!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _cameraImageBase64 = null;
                        _hasSignature = false;
                      }),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.refresh,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _points = [];
                    _hasSignature = false;
                    _cameraImageBase64 = null;
                  }),
                  child: const Text(
                    'Effacer',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: (_hasSignature && !_isProcessing)
                      ? _onTerminer
                      : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Terminer',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabBtn(String label, int idx) {
    final sel = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: sel ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}

class _SigPainter extends CustomPainter {
  final List<Offset?> points;
  _SigPainter(this.points);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null)
        canvas.drawLine(points[i]!, points[i + 1]!, p);
    }
  }

  @override
  bool shouldRepaint(_SigPainter old) => true;
}
