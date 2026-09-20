import 'package:family_budget_app/data/repositories/subscription_repository.dart';
import 'package:family_budget_app/domain/entities/subscription.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, AsyncValue<List<Subscription>>>((ref) {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return SubscriptionNotifier(repository);
});

class SubscriptionNotifier extends StateNotifier<AsyncValue<List<Subscription>>> {
  final SubscriptionRepository _repository;

  SubscriptionNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSubscriptions();
  }

  Future<void> loadSubscriptions() async {
    if (_repository.userId == null && _repository.familyId == null) {
      if (mounted) state = const AsyncValue.data([]);
      return;
    }
    try {
      final subs = await _repository.getAllSubscriptions();
      if (mounted) state = AsyncValue.data(subs);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> addSubscription(Subscription sub) async {
    await _repository.addSubscription(sub);
    await loadSubscriptions();
  }

  Future<void> deleteSubscription(String id) async {
    await _repository.deleteSubscription(id);
    await loadSubscriptions();
  }
}