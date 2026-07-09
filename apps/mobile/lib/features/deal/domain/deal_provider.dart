import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../services/deal_service.dart';
import 'deal_model.dart';
import 'deal_state.dart';

class DealNotifier extends AsyncNotifier<DealState> {
  @override
  Future<DealState> build() async {
    final deals = await DealService.getMyDeals();
    return DealState.loaded(deals);
  }

  List<Deal> get _current => state.whenOrNull(data: (s) => s.deals) ?? const [];

  Future<void> loadDeals() async {
    state = AsyncData(DealState.loading());
    try {
      state = AsyncData(DealState.loaded(await DealService.getMyDeals()));
    } catch (e) {
      state = AsyncData(DealState.error(_message(e, 'Failed to load deals.')));
    }
  }

  Future<Deal?> createDeal({
    required String title,
    required String description,
    required Map<String, dynamic> terms,
    DealContentType? contentType,
    List<DealPartyInput> parties = const [],
  }) async {
    state = AsyncData(DealState.creating());
    try {
      final deal = await DealService.createDeal(
        title: title,
        description: description,
        terms: terms,
        contentType: contentType,
        parties: parties,
      );
      final deals = await DealService.getMyDeals();
      state = AsyncData(DealState.success(deals, selectedDeal: deal));
      return deal;
    } catch (e) {
      state = AsyncData(DealState.error(_message(e, 'Failed to create deal.')));
      return null;
    }
  }

  /// Creator-only transition to Approved, Bridged (NEGOTIATION) or Cancelled.
  Future<Deal?> updateStatus({
    required String dealId,
    required DealStatus status,
    String? reason,
  }) async {
    final previous = _current;
    state = AsyncData(DealState.updating(previous));
    try {
      final updated = await DealService.updateStatus(
        dealId: dealId,
        status: status,
        reason: reason,
      );
      final deals = await DealService.getMyDeals();
      state = AsyncData(DealState.success(deals, selectedDeal: updated));
      return updated;
    } catch (e) {
      state = AsyncData(
        DealState.error(
          _message(e, 'Failed to update the deal status.'),
          deals: previous,
        ),
      );
      return null;
    }
  }

  /// Surfaces the backend's message (403 "Only the deal creator…", quota, KYC)
  /// instead of swallowing it behind a generic string.
  String _message(Object error, String fallback) =>
      error is AppException ? error.message : fallback;
}

final dealProvider = AsyncNotifierProvider<DealNotifier, DealState>(
  DealNotifier.new,
);

/// Versions are embedded in GET /deals/:id; this refetches the deal for them.
final dealVersionsProvider = FutureProvider.family<List<DealVersion>, String>((
  ref,
  dealId,
) async {
  return DealService.getDealVersions(dealId);
});
