import 'package:family_budget_app/domain/entities/budget_limits.dart';
import 'package:family_budget_app/presentation/providers/transaction_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_budget_app/presentation/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';

final budgetLimitProvider =
    StateNotifierProvider<BudgetLimitNotifier, BudgetLimits>((ref) {
      final auth = ref.watch(authProvider);
      return BudgetLimitNotifier(
        activePlan: auth.activePlan,
        userId: auth.userId,
        familyId: auth.familyId,
      );
    });

class BudgetLimitNotifier extends StateNotifier<BudgetLimits> {
  final String activePlan;
  final String? userId;
  final String? familyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BudgetLimitNotifier({required this.activePlan, this.userId, this.familyId})
    : super(BudgetLimits()) {
    _loadLimits();
  }

  DocumentReference? get _docRef {
    if (activePlan == 'family' && familyId != null) {
      return _firestore.collection('budget_limits_family').doc(familyId);
    } else if (userId != null) {
      return _firestore.collection('budget_limits_personal').doc(userId);
    } else {
      return null;
    }
  }

  Future<void> _loadLimits() async {
    final ref = _docRef;
    if (ref == null) {
      state = BudgetLimits();
      return;
    }
    try {
      final doc = await ref.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        state = BudgetLimits(
          dailyLimit: (data['limit_daily'] as num?)?.toDouble(),
          weeklyLimit: (data['limit_weekly'] as num?)?.toDouble(),
          monthlyLimit: (data['limit_monthly'] as num?)?.toDouble(),
          yearlyLimit: (data['limit_yearly'] as num?)?.toDouble(),
        );
      } else {
        state = BudgetLimits();
      }
    } catch (e) {
      debugPrint('Firestore load budget limits error: $e');
    }
  }

  Future<void> updateLimit(TimeFilter filter, double? limit) async {
    final ref = _docRef;
    if (ref == null) return;
    try {
      String fieldName = '';

      switch (filter) {
        case TimeFilter.daily:
          fieldName = 'limit_daily';
          state = state.copyWith(dailyLimit: limit, clearDaily: limit == null);
          break;
        case TimeFilter.weekly:
          fieldName = 'limit_weekly';
          state = state.copyWith(
            weeklyLimit: limit,
            clearWeekly: limit == null,
          );
          break;
        case TimeFilter.monthly:
          fieldName = 'limit_monthly';
          state = state.copyWith(
            monthlyLimit: limit,
            clearMonthly: limit == null,
          );
          break;
        case TimeFilter.yearly:
          fieldName = 'limit_yearly';
          state = state.copyWith(
            yearlyLimit: limit,
            clearYearly: limit == null,
          );
          break;
      }

      await ref.set({fieldName: limit}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore update budget limit error: $e');
    }
  }
}
