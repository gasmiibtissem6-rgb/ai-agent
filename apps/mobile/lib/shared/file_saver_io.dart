import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<void> saveFileBytes(
  Uint8List bytes,
  String fileName,
  String mimeType,
) async {
  final outputPath = await FilePicker.platform.saveFile(
    dialogTitle: 'Save file',
    fileName: fileName,
    bytes: bytes,
  );

  if (outputPath == null) {
    return;
  }

  await File(outputPath).writeAsBytes(bytes, flush: true);
}
