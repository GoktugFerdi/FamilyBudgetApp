import 'package:family_budget_app/domain/entities/goal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_budget_app/presentation/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';

final goalRepositoryProvider = Provider((ref) {
  final auth = ref.watch(authProvider);
  return GoalRepository(
    activePlan: auth.activePlan,
    userId: auth.userId,
    familyId: auth.familyId,
  );
});

class GoalRepository {
  final String activePlan;
  final String? userId;
  final String? familyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  GoalRepository({required this.activePlan, this.userId, this.familyId});

  CollectionReference? get _collection {
    if (activePlan == 'family' && familyId != null) {
      return _firestore
          .collection('goals_family')
          .doc(familyId)
          .collection('items');
    } else if (userId != null) {
      return _firestore
          .collection('goals_personal')
          .doc(userId)
          .collection('items');
    } else {
      return null;
    }
  }

  Future<List<GoalEntity>> getAllGoals() async {
    final col = _collection;
    if (col == null) return [];
    try {
      final snapshot = await col.get();
      final goals = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return GoalEntity(
          id: data['id'] as int?,
          title: data['title'] as String? ?? '',
          targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 0.0,
          currentAmount: (data['currentAmount'] as num?)?.toDouble() ?? 0.0,
          deadline: DateTime.tryParse(data['deadline'] as String? ?? '') ?? DateTime.now(),
          iconName: data['iconName'] as String?,
        );
      }).toList();

      goals.sort((a, b) => a.deadline.compareTo(b.deadline));
      return goals;
    } catch (e) {
      debugPrint('Firestore getAllGoals error: $e');
      return [];
    }
  }

  Future<int> insert(GoalEntity goal) async {
    final col = _collection;
    if (col == null) return 0;
    try {
      final newId = DateTime.now().millisecondsSinceEpoch;
      final newGoal = goal.copyWith(id: newId);

      await col.doc(newId.toString()).set({
        'id': newId,
        'title': newGoal.title,
        'targetAmount': newGoal.targetAmount,
        'currentAmount': newGoal.currentAmount,
        'deadline': newGoal.deadline.toIso8601String(),
        'iconName': newGoal.iconName,
      });

      return newId;
    } catch (e) {
      debugPrint('Firestore insert goal error: $e');
      return 0;
    }
  }

  Future<int> updateCurrentAmount(int id, double newAmount) async {
    final col = _collection;
    if (col == null) return 0;
    try {
      await col.doc(id.toString()).update({'currentAmount': newAmount});
      return id;
    } catch (e) {
      debugPrint('Firestore update goal error: $e');
      return 0;
    }
  }

  Future<int> delete(int id) async {
    final col = _collection;
    if (col == null) return 0;
    try {
      await col.doc(id.toString()).delete();
      return id;
    } catch (e) {
      debugPrint('Firestore delete goal error: $e');
      return 0;
    }
  }
}
