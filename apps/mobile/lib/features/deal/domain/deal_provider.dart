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

  /// Creator attaches a counterparty by username or email.
  Future<Deal?> addParty({
    required String dealId,
    required String identifier,
    String? role,
  }) async {
    return _runAndRefresh(
      () => DealService.addParty(
        dealId: dealId,
        identifier: identifier,
        role: role,
      ),
      'Failed to add the other party.',
    );
  }

  /// Invited party accepts or refuses the deal.
  Future<Deal?> respondToDeal({
    required String dealId,
    required bool accept,
  }) async {
    return _runAndRefresh(
      () => DealService.respondToDeal(dealId: dealId, accept: accept),
      'Failed to respond to the deal.',
    );
  }

  /// Creator submits a version for the accepted parties to approve.
  Future<Deal?> submitVersion({
    required String dealId,
    required String versionId,
  }) async {
    return _runAndRefresh(
      () => DealService.submitVersion(dealId: dealId, versionId: versionId),
      'Failed to submit the version.',
    );
  }

  /// A required party approves or rejects a submitted version.
  Future<Deal?> decideVersion({
    required String dealId,
    required String versionId,
    required bool approve,
    String? reason,
  }) async {
    return _runAndRefresh(
      () => DealService.decideVersion(
        dealId: dealId,
        versionId: versionId,
        approve: approve,
        reason: reason,
      ),
      'Failed to record your decision.',
    );
  }

  /// Runs a mutating deal action, then refreshes the list from the backend.
  Future<Deal?> _runAndRefresh(
    Future<Deal> Function() action,
    String fallback,
  ) async {
    final previous = _current;
    state = AsyncData(DealState.updating(previous));
    try {
      final updated = await action();
      final deals = await DealService.getMyDeals();
      state = AsyncData(DealState.success(deals, selectedDeal: updated));
      return updated;
    } catch (e) {
      state = AsyncData(
        DealState.error(_message(e, fallback), deals: previous),
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

/// Full deal detail (parties + versions) used to drive the detail workflow UI.
final dealByIdProvider = FutureProvider.family<Deal, String>((
  ref,
  dealId,
) async {
  return DealService.getDeal(dealId);
});
