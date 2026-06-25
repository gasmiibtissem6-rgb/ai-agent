import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/kyc_service.dart';
import '../../../services/supabase_service.dart';
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
      state = AsyncData(KycState.error(e.toString()));
    }
  }

  Future<void> submitKyc({
    required KycDocumentType documentType,
    required Uint8List frontBytes,
    required String frontFileName,
    Uint8List? backBytes,
    String? backFileName,
    Uint8List? selfieBytes,
    String? selfieFileName,
  }) async {
    state = AsyncData(KycState.uploading(0));
    try {
      final userId =
          SupabaseService.client?.auth.currentUser?.id ?? '';
      final docTypeStr = _documentTypeToString(documentType);

      state = AsyncData(KycState.uploading(0.2));
      final frontPath = await KycService.uploadDocument(
        userId: userId,
        fileBytes: frontBytes,
        fileName: frontFileName,
        fileType: 'front',
      );

      String? backPath;
      if (backBytes != null && backFileName != null) {
        state = AsyncData(KycState.uploading(0.5));
        backPath = await KycService.uploadDocument(
          userId: userId,
          fileBytes: backBytes,
          fileName: backFileName,
          fileType: 'back',
        );
      }

      String? selfiePath;
      if (selfieBytes != null && selfieFileName != null) {
        state = AsyncData(KycState.uploading(0.75));
        selfiePath = await KycService.uploadDocument(
          userId: userId,
          fileBytes: selfieBytes,
          fileName: selfieFileName,
          fileType: 'selfie',
        );
      }

      state = AsyncData(KycState.uploading(0.9));
      final submission = await KycService.submitKyc(
        documentType: docTypeStr,
        frontPath: frontPath,
        backPath: backPath,
        selfiePath: selfiePath,
      );

      state = AsyncData(KycState.success(submission));
    } catch (e) {
      state = AsyncData(KycState.error(
        'Failed to submit KYC. Please try again.',
      ));
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
}

final kycProvider = AsyncNotifierProvider<KycNotifier, KycState>(
  KycNotifier.new,
);