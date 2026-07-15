import 'deal_model.dart';

enum DealLoadStatus { initial, loading, loaded, creating, updating, success, error }

class DealState {
  final DealLoadStatus status;
  final List<Deal> deals;
  final Deal? selectedDeal;
  final String? errorMessage;

  const DealState({
    required this.status,
    this.deals = const [],
    this.selectedDeal,
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

  /// Keeps the current list on screen while a status change is in flight.
  factory DealState.updating(List<Deal> deals) =>
      DealState(status: DealLoadStatus.updating, deals: deals);

  factory DealState.success(List<Deal> deals, {Deal? selectedDeal}) =>
      DealState(
        status: DealLoadStatus.success,
        deals: deals,
        selectedDeal: selectedDeal,
      );

  factory DealState.error(String message, {List<Deal> deals = const []}) =>
      DealState(
        status: DealLoadStatus.error,
        deals: deals,
        errorMessage: message,
      );

  bool get isLoading => status == DealLoadStatus.loading;
  bool get isCreating => status == DealLoadStatus.creating;
  bool get isUpdating => status == DealLoadStatus.updating;
  bool get hasError => status == DealLoadStatus.error;
  bool get isSuccess => status == DealLoadStatus.success;
}
