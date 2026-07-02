import 'dart:typed_data';

Future<void> saveFileBytes(
  Uint8List bytes,
  String fileName,
  String mimeType,
) async {
  throw UnsupportedError('Saving files is not supported on this platform.');
}
