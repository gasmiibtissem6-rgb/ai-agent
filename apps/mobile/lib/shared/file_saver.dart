import 'dart:typed_data';

import 'file_saver_stub.dart'
    if (dart.library.js_interop) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_io.dart';

Future<void> savePdfBytes(Uint8List bytes, String fileName) {
  return saveFileBytes(bytes, fileName, 'application/pdf');
}
