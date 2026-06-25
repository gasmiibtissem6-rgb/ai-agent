import 'deal_model.dart';

enum DealLoadStatus { initial, loading, loaded, creating, success, error }

class DealState {
  final DealLoadStatus status;
  final List<Deal> deals;
  final Deal? selectedDeal;
  final List<DealVersion> versions;
  final String? errorMessage;

  const DealState({
    required this.status,
    this.deals = const [],
    this.selectedDeal,
    this.versions = const [],
    this.errorMessage,
  });

  factory DealState.initial() =>
      const DealState(status: DealLoadStatus.initial);

  factory DealState.loading() =>
      const DealState(status: DealLoadStatus.loading);

  factory DealState.loaded(List<Deal> deals) =>
      DealState(status: DealLoadStatus.loaded, deals: deals);

  factory DealState.creating() =>
      const DealState(status: DealLoadStatus.creating);

  factory DealState.success(List<Deal> deals, {Deal? selectedDeal}) =>
      DealState(
        status: DealLoadStatus.success,
        deals: deals,
        selectedDeal: selectedDeal,
      );

  factory DealState.error(String message) =>
      DealState(status: DealLoadStatus.error, errorMessage: message);

  bool get isLoading => status == DealLoadStatus.loading;
  bool get isCreating => status == DealLoadStatus.creating;
  bool get hasError => status == DealLoadStatus.error;
  bool get isSuccess => status == DealLoadStatus.success;
}