import 'package:family_budget_app/data/repositories/goal_repository.dart';
import 'package:family_budget_app/domain/entities/goal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final goalProvider = StateNotifierProvider<GoalNotifier, AsyncValue<List<GoalEntity>>>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return GoalNotifier(repository);
});

class GoalNotifier extends StateNotifier<AsyncValue<List<GoalEntity>>> {
  final GoalRepository _repository;

  GoalNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    if (_repository.userId == null && _repository.familyId == null) {
      if (mounted) state = const AsyncValue.data([]);
      return;
    }
    try {
      final goals = await _repository.getAllGoals();
      if (mounted) state = AsyncValue.data(goals);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> addGoal(GoalEntity goal) async {
    await _repository.insert(goal);
    await loadGoals();
  }

  Future<void> updateGoalProgress(int id, double newCurrentAmount) async {
    await _repository.updateCurrentAmount(id, newCurrentAmount);
    await loadGoals();
  }

  Future<void> deleteGoal(int id) async {
    await _repository.delete(id);
    await loadGoals();
  }
}
