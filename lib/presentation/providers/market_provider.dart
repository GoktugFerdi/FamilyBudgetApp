import 'package:family_budget_app/data/services/market_api_service.dart';
import 'package:family_budget_app/domain/entities/market_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final marketApiService = Provider((ref) => MarketApiService());

final marketProvider = StateNotifierProvider<MarketNotifier, AsyncValue<List<MarketItem>>>((ref) {
  final service = ref.watch(marketApiService);
  return MarketNotifier(service);
});

class MarketNotifier extends StateNotifier<AsyncValue<List<MarketItem>>> {
  final MarketApiService _service;

  MarketNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchRates();
  }

  Future<void> fetchRates() async {
    state = const AsyncValue.loading();
    try {
      final items = await _service.fetchLiveRates();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
