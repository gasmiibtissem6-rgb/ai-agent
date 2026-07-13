import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../services/kyc_service.dart';
import 'kyc_model.dart';
import 'kyc_state.dart';

class KycNotifier extends AsyncNotifier<KycState> {
  @override
  Future<KycState> build() async {
    final submission = await KycService.getMyKyc();
    return KycState.loaded(submission);
  }

  Future<void> loadKyc() async {
    state = AsyncData(KycState.loading());
    try {
      final submission = await KycService.getMyKyc();
      state = AsyncData(KycState.loaded(submission));
    } catch (e) {
      state = AsyncData(KycState.error(_message(e)));
    }
  }

  /// Uploads each document through NestJS (authorize → signed PUT) then submits.
  /// The selfie is required by the backend, so it is mandatory here too.
  Future<void> submitKyc({
    required KycDocumentType documentType,
    required Uint8List frontBytes,
    required String frontFileName,
    Uint8List? backBytes,
    String? backFileName,
    required Uint8List selfieBytes,
    required String selfieFileName,
  }) async {
    state = AsyncData(KycState.uploading(0));
    try {
      final docTypeStr = _documentTypeToString(documentType);

      state = AsyncData(KycState.uploading(0.2));
      final frontPath = await KycService.uploadDocument(
        fileBytes: frontBytes,
        fileName: frontFileName,
        documentSide: 'front',
      );

      String? backPath;
      if (backBytes != null && backFileName != null) {
        state = AsyncData(KycState.uploading(0.45));
        backPath = await KycService.uploadDocument(
          fileBytes: backBytes,
          fileName: backFileName,
          documentSide: 'back',
        );
      }

      state = AsyncData(KycState.uploading(0.7));
      final selfiePath = await KycService.uploadDocument(
        fileBytes: selfieBytes,
        fileName: selfieFileName,
        documentSide: 'selfie',
      );

      state = AsyncData(KycState.uploading(0.9));
      final submission = await KycService.submitKyc(
        documentType: docTypeStr,
        storagePathFront: frontPath,
        storagePathBack: backPath,
        storagePathSelfie: selfiePath,
      );

      state = AsyncData(KycState.success(submission));
    } catch (e) {
      state = AsyncData(KycState.error(_message(e)));
    }
  }

  String _documentTypeToString(KycDocumentType type) {
    switch (type) {
      case KycDocumentType.nationalId:
        return 'national_id';
      case KycDocumentType.passport:
        return 'passport';
      case KycDocumentType.driverLicense:
        return 'driver_license';
    }
  }

  /// Surfaces the backend's message (e.g. "A submission is already under
  /// review") instead of a generic string.
  String _message(Object error) => error is AppException
      ? error.message
      : 'Failed to submit KYC. Please try again.';
}

final kycProvider = AsyncNotifierProvider<KycNotifier, KycState>(
  KycNotifier.new,
);
