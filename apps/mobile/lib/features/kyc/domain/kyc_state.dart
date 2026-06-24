import 'kyc_model.dart';

enum KycLoadStatus { initial, loading, loaded, uploading, success, error }

class KycState {
  final KycLoadStatus status;
  final KycSubmission? submission;
  final String? errorMessage;
  final double uploadProgress;

  const KycState({
    required this.status,
    this.submission,
    this.errorMessage,
    this.uploadProgress = 0,
  });

  factory KycState.initial() =>
      const KycState(status: KycLoadStatus.initial);

  factory KycState.loading() =>
      const KycState(status: KycLoadStatus.loading);

  factory KycState.loaded(KycSubmission? submission) =>
      KycState(status: KycLoadStatus.loaded, submission: submission);

  factory KycState.uploading(double progress) =>
      KycState(status: KycLoadStatus.uploading, uploadProgress: progress);

  factory KycState.success(KycSubmission submission) =>
      KycState(status: KycLoadStatus.success, submission: submission);

  factory KycState.error(String message) =>
      KycState(status: KycLoadStatus.error, errorMessage: message);

  bool get isLoading => status == KycLoadStatus.loading;
  bool get isUploading => status == KycLoadStatus.uploading;
  bool get hasError => status == KycLoadStatus.error;
  bool get isSuccess => status == KycLoadStatus.success;
}