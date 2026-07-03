import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class PickedFileData {
  PickedFileData({required this.name, required this.bytes, this.mimeType});

  final String name;
  final Uint8List bytes;
  final String? mimeType;

  String get dataUrl {
    final resolvedMimeType = mimeType ?? _mimeTypeFromName(name);
    return 'data:$resolvedMimeType;base64,${base64Encode(bytes)}';
  }
}

Future<PickedFileData?> pickSingleFile({
  List<String>? allowedExtensions,
}) async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    type: allowedExtensions == null ? FileType.any : FileType.custom,
    allowedExtensions: allowedExtensions,
    withData: true,
  );

  final files = result?.files;
  final file = files == null || files.isEmpty ? null : files.first;
  final bytes = file?.bytes;
  if (file == null || bytes == null) {
    return null;
  }

  return PickedFileData(
    name: file.name,
    bytes: bytes,
    mimeType: file.extension == null ? null : _mimeTypeFromName(file.name),
  );
}

Future<List<PickedFileData>> pickMultipleFiles({
  List<String>? allowedExtensions,
}) async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: true,
    type: allowedExtensions == null ? FileType.any : FileType.custom,
    allowedExtensions: allowedExtensions,
    withData: true,
  );

  if (result == null) {
    return const [];
  }

  return result.files
      .where((file) => file.bytes != null)
      .map(
        (file) => PickedFileData(
          name: file.name,
          bytes: file.bytes!,
          mimeType: file.extension == null
              ? null
              : _mimeTypeFromName(file.name),
        ),
      )
      .toList();
}

String _mimeTypeFromName(String name) {
  switch (path.extension(name).toLowerCase()) {
    case '.png':
      return 'image/png';
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.gif':
      return 'image/gif';
    case '.webp':
      return 'image/webp';
    case '.pdf':
      return 'application/pdf';
    case '.mp4':
      return 'video/mp4';
    case '.mov':
      return 'video/quicktime';
    case '.avi':
      return 'video/x-msvideo';
    case '.mkv':
      return 'video/x-matroska';
    default:
      return 'application/octet-stream';
  }
}
