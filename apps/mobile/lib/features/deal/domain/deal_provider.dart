import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/deal_service.dart';
import 'deal_model.dart';
import 'deal_state.dart';

class DealNotifier extends AsyncNotifier<DealState> {
  @override
  Future<DealState> build() async {
    final deals = await DealService.getMyDeals();
    return DealState.loaded(deals);
  }

  Future<void> loadDeals() async {
    state = AsyncData(DealState.loading());
    try {
      final deals = await DealService.getMyDeals();
      state = AsyncData(DealState.loaded(deals));
    } catch (e) {
      state = AsyncData(DealState.error(e.toString()));
    }
  }

  Future<Deal?> createDeal({
    required String title,
    required String description,
    required String content,
  }) async {
    state = AsyncData(DealState.creating());
    try {
      final deal = await DealService.createDeal(
        title: title,
        description: description,
        content: content,
      );
      final deals = await DealService.getMyDeals();
      state = AsyncData(DealState.success(deals, selectedDeal: deal));
      return deal;
    } catch (e) {
      state = AsyncData(DealState.error('Failed to create deal.'));
      return null;
    }
  }

  Future<void> sendDeal(String dealId) async {
    try {
      await DealService.sendDeal(dealId);
      await loadDeals();
    } catch (e) {
      state = AsyncData(DealState.error('Failed to send deal.'));
    }
  }

  Future<void> approveDeal({
    required String dealId,
    required String versionId,
    String? comment,
  }) async {
    try {
      await DealService.approveDeal(
        dealId: dealId,
        versionId: versionId,
        comment: comment,
      );
      await loadDeals();
    } catch (e) {
      state = AsyncData(DealState.error('Failed to approve deal.'));
    }
  }

  Future<void> rejectDeal({
    required String dealId,
    required String versionId,
    String? comment,
  }) async {
    try {
      await DealService.rejectDeal(
        dealId: dealId,
        versionId: versionId,
        comment: comment,
      );
      await loadDeals();
    } catch (e) {
      state = AsyncData(DealState.error('Failed to reject deal.'));
    }
  }

  Future<void> requestModification({
    required String dealId,
    required String versionId,
    required String comment,
  }) async {
    try {
      await DealService.requestModification(
        dealId: dealId,
        versionId: versionId,
        comment: comment,
      );
      await loadDeals();
    } catch (e) {
      state = AsyncData(DealState.error('Failed to request modification.'));
    }
  }

  Future<void> finalizeDeal({
    required String dealId,
    required String versionId,
  }) async {
    try {
      await DealService.finalizeDeal(
        dealId: dealId,
        versionId: versionId,
      );
      await loadDeals();
    } catch (e) {
      state = AsyncData(DealState.error('Failed to finalize deal.'));
    }
  }
}

final dealProvider = AsyncNotifierProvider<DealNotifier, DealState>(
  DealNotifier.new,
);

final dealVersionsProvider =
    FutureProvider.family<List<DealVersion>, String>((ref, dealId) async {
  return DealService.getDealVersions(dealId);
});