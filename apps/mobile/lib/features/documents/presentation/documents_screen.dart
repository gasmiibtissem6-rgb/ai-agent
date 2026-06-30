import 'dart:html' as html;
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  bool _showSignature = false;
  String? _signatureImageBase64;

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _pickFile({bool imageOnly = false, bool useCamera = false}) {
    final input = html.FileUploadInputElement();
    input.accept = imageOnly ? 'image/*' : 'image/*,application/pdf';
    if (useCamera) {
      input.setAttribute('capture', 'environment');
    }
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
          final msg = (data['message'] ?? 'Aucun texte détecté') as String;
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Aucun texte détecté: $msg'), backgroundColor: Colors.orange),
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

  void _openCameraForImport() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Prendre une photo du document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _CameraCapture(
              onCaptured: (base64) async {
                if (base64.isEmpty) return;
                Navigator.pop(context);
                await _processScannedImage(base64);
              },
              capturedImage: null,
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ]),
        ),
      ),
    );
  }

  Future<void> _processScannedImage(String base64) async {
    setState(() => _isScanning = true);
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
        final msg = (data['message'] ?? 'Aucun texte détecté') as String;
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aucun texte détecté: $msg'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Erreur de scan'), backgroundColor: Colors.red),
      );
    }
    setState(() => _isScanning = false);
  }

  void _showSignatureDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SignatureDialog(
        onSigned: (signatureDataUrl) {
          setState(() {
            _showSignature = true;
            _signatureImageBase64 = signatureDataUrl.isNotEmpty ? signatureDataUrl : null;
            final marker = RegExp(r"\n\n--- Document signé électroniquement le .*? ---");
            _editController.text = _editController.text.replaceAll(marker, '').trimRight() +
                "\n\n--- Document signé électroniquement le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ---";
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Signature apposée !'), backgroundColor: Colors.green),
          );
        },
      ),
    );
  }

  void _downloadPdf() async {
    try {
      final dio = Dio();
      final response = await dio.post(
        'http://localhost:3001/api/chat/generate-pdf',
        data: {
          'content': _editController.text,
          'title': 'Contrat',
          if (_signatureImageBase64 != null) 'signatureImage': _signatureImageBase64,
        },
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
              _buildCard(colorScheme, Icons.camera_alt, 'Prendre une photo', 'Appareil photo', Colors.blue, () => _openCameraForImport()),
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
          IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() {
            _scannedText = '';
            _showSignature = false;
            _signatureImageBase64 = null;
          })),
          const Text('Modifier le contrat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.draw, color: _showSignature ? Colors.green : Colors.purple),
            tooltip: 'Signer',
            onPressed: _showSignatureDialog,
          ),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('Document signé électroniquement', style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
                  ]),
                  if (_signatureImageBase64 != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Image.network(_signatureImageBase64!, height: 80, fit: BoxFit.contain),
                    ),
                  ],
                ]),
              ),
            ],
          ]),
        ),
      ),
    ]);
  }
}

class _SignatureDialog extends StatefulWidget {
  final Function(String) onSigned;
  const _SignatureDialog({required this.onSigned});

  @override
  State<_SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<_SignatureDialog> {
  int _tab = 0; // 0=draw, 1=camera
  List<Offset?> _points = [];
  bool _hasSignature = false;
  String? _cameraSignatureDataUrl;
  String? _cameraImageBase64;
  bool _isProcessing = false;
  final GlobalKey _repaintKey = GlobalKey();

  Future<String?> _captureDrawing() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final pngBytes = byteData.buffer.asUint8List();
      final b64 = base64Encode(pngBytes);
      return 'data:image/png;base64,$b64';
    } catch (e) {
      return null;
    }
  }

  Future<void> _onTerminer() async {
    setState(() => _isProcessing = true);
    String? signature;
    if (_tab == 0) {
      signature = await _captureDrawing();
    } else {
      signature = _cameraImageBase64;
    }
    setState(() => _isProcessing = false);
    if (!mounted) return;
    Navigator.pop(context);
    widget.onSigned(signature ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              _tabBtn('✍️ Dessiner', 0),
              _tabBtn('📷 Caméra', 1),
            ]),
          ),
          const SizedBox(height: 16),

          if (_tab == 0) ...[
            Container(
              height: 200, width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: Container(
                    color: Colors.white,
                    child: Stack(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanUpdate: (d) => setState(() { _points.add(d.localPosition); _hasSignature = true; }),
                          onPanEnd: (_) => setState(() => _points.add(null)),
                          child: CustomPaint(
                            painter: _SigPainter(_points),
                            child: Container(color: Colors.transparent),
                          ),
                        ),
                        if (_points.isEmpty)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Center(child: Text('Dessinez votre signature ici', style: TextStyle(color: Colors.grey.shade400))),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Utilisez votre souris ou trackpad', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ] else ...[
            _CameraCapture(
              onCaptured: (base64) {
                setState(() {
                  _cameraImageBase64 = base64;
                  _hasSignature = true;
                });
              },
              capturedImage: _cameraImageBase64,
            ),
          ],

          const SizedBox(height: 16),
          Row(children: [
            TextButton(
              onPressed: () => setState(() { _points = []; _hasSignature = false; _cameraImageBase64 = null; }),
              child: const Text('Effacer', style: TextStyle(color: Colors.red)),
            ),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: (_hasSignature && !_isProcessing) ? _onTerminer : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: _isProcessing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Terminer', style: TextStyle(color: Colors.white)),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _tabBtn(String label, int idx) {
    final selected = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }
}

void _registerView(String viewId, html.VideoElement video) {
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int id) => video);
}

class _CameraCapture extends StatefulWidget {
  final Function(String) onCaptured;
  final String? capturedImage;
  const _CameraCapture({required this.onCaptured, this.capturedImage});

  @override
  State<_CameraCapture> createState() => _CameraCaptureState();
}

class _CameraCaptureState extends State<_CameraCapture> {
  html.VideoElement? _video;
  html.MediaStream? _stream;
  bool _starting = false;
  String? _error;
  final String _viewId = 'cam-view-${DateTime.now().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    if (widget.capturedImage == null) _startCamera();
  }

  Future<void> _startCamera() async {
    setState(() { _starting = true; _error = null; });
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) throw 'Caméra non disponible sur ce navigateur';
      final stream = await mediaDevices.getUserMedia({'video': true, 'audio': false});
      _stream = stream;
      _video = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..srcObject = stream;
      // Register for Flutter Web
      _registerView(_viewId, _video!);
    } catch (e) {
      setState(() => _error = 'Impossible d\'accéder à la caméra : autorisez l\'accès dans votre navigateur.');
    }
    setState(() => _starting = false);
  }

  Future<String> _cropSignature(String dataUrl) async {
    try {
      final img = html.ImageElement();
      img.src = dataUrl;
      await img.onLoad.first;

      final w = img.naturalWidth;
      final h = img.naturalHeight;

      // Étape 1 : isoler la zone du cadre-guide (80% largeur, 50% hauteur, centré)
      final cropW = (w * 0.8).round();
      final cropH = (h * 0.5).round();
      final offsetX = ((w - cropW) / 2).round();
      final offsetY = ((h - cropH) / 2).round();

      final cropCanvas = html.CanvasElement(width: cropW, height: cropH);
      final cropCtx = cropCanvas.context2D;
      cropCtx.drawImageScaledFromSource(
        img, offsetX, offsetY, cropW, cropH, 0, 0, cropW, cropH,
      );
      final imageData = cropCtx.getImageData(0, 0, cropW, cropH);
      final data = imageData.data;

      // Étape 2 : ne garder que les pixels foncés (encre), tout le reste devient blanc
      // Seuil adaptatif : on calcule la luminosité moyenne pour s'adapter à l'éclairage
      int total = 0;
      for (int i = 0; i < data.length; i += 4) {
        total += ((data[i] + data[i + 1] + data[i + 2]) / 3).round();
      }
      final avgLum = total / (data.length / 4);
      final threshold = (avgLum * 0.65).clamp(60, 180);

      final outCanvas = html.CanvasElement(width: cropW, height: cropH);
      final outCtx = outCanvas.context2D;
      outCtx.fillStyle = 'white';
      outCtx.fillRect(0, 0, cropW, cropH);
      final outData = outCtx.getImageData(0, 0, cropW, cropH);
      final outPixels = outData.data;

      for (int i = 0; i < data.length; i += 4) {
        final r = data[i];
        final g = data[i + 1];
        final b = data[i + 2];
        final lum = (r + g + b) / 3;
        if (lum < threshold) {
          outPixels[i] = r;
          outPixels[i + 1] = g;
          outPixels[i + 2] = b;
          outPixels[i + 3] = 255;
        } else {
          outPixels[i] = 255;
          outPixels[i + 1] = 255;
          outPixels[i + 2] = 255;
          outPixels[i + 3] = 255;
        }
      }
      outCtx.putImageData(outData, 0, 0);

      return outCanvas.toDataUrl('image/png');
    } catch (e) {
      return dataUrl;
    }
  }

  bool _isCropping = false;

  Future<void> _capture() async {
    if (_video == null) return;
    final canvas = html.CanvasElement(width: _video!.videoWidth, height: _video!.videoHeight);
    final ctx = canvas.context2D;
    ctx.drawImage(_video!, 0, 0);
    final rawDataUrl = canvas.toDataUrl('image/png');
    setState(() => _isCropping = true);
    final croppedDataUrl = await _cropSignature(rawDataUrl);
    setState(() => _isCropping = false);
    _stopCamera();
    widget.onCaptured(croppedDataUrl);
  }

  void _retake() {
    widget.onCaptured('');
    _startCamera();
  }

  void _stopCamera() {
    _stream?.getTracks().forEach((t) => t.stop());
    _stream = null;
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.capturedImage != null && widget.capturedImage!.isNotEmpty) {
      return Column(children: [
        Container(
          height: 200, width: double.infinity,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(widget.capturedImage!, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(onPressed: _retake, icon: const Icon(Icons.refresh), label: const Text('Reprendre la photo')),
      ]);
    }

    if (_error != null) {
      return Container(
        height: 200, width: double.infinity,
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.all(16),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.videocam_off, color: Colors.red, size: 40),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 13)),
          const SizedBox(height: 8),
          TextButton(onPressed: _startCamera, child: const Text('Réessayer')),
        ])),
      );
    }

    if (_starting) {
      return Container(
        height: 200, width: double.infinity,
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Column(children: [
      Stack(children: [
        Container(
          height: 200, width: double.infinity,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.black),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: HtmlElementView(viewType: _viewId),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.8,
              heightFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.yellow, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 6),
      const Text('Placez votre signature dans le cadre jaune', style: TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(height: 8),
      ElevatedButton.icon(
        onPressed: _isCropping ? null : _capture,
        icon: _isCropping
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.camera_alt),
        label: Text(_isCropping ? 'Recadrage en cours...' : 'Prendre la photo'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
      ),
    ]);
  }
}

class _SigPainter extends CustomPainter {
  final List<Offset?> points;
  _SigPainter(this.points);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) canvas.drawLine(points[i]!, points[i + 1]!, paint);
    }
  }
  @override
  bool shouldRepaint(_SigPainter old) => true;
}
