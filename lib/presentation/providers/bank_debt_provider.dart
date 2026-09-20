import 'package:family_budget_app/data/repositories/bank_debt_repository.dart';
import 'package:family_budget_app/domain/entities/bank_debt.dart';
import 'package:family_budget_app/presentation/providers/transaction_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bankDebtProvider = StateNotifierProvider<BankDebtNotifier, AsyncValue<List<BankDebtEntity>>>((ref) {
  final repository = ref.watch(bankDebtRepositoryProvider);
  return BankDebtNotifier(repository);
});

class BankDebtNotifier extends StateNotifier<AsyncValue<List<BankDebtEntity>>> {
  final BankDebtRepository _repository;

  BankDebtNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadDebts();
  }

  Future<void> loadDebts() async {
    if (_repository.userId == null && _repository.familyId == null) {
      if (mounted) state = const AsyncValue.data([]);
      return;
    }
    try {
      final debts = await _repository.getAllDebts();
      if (mounted) state = AsyncValue.data(debts);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> addDebt(BankDebtEntity debt) async {
    await _repository.insert(debt);
    await loadDebts();
  }

  Future<void> deleteDebt(int id) async {
    await _repository.delete(id);
    await loadDebts();
  }
}

// Zaman filtresine göre banka borçlarını hesaplar
double getBankDebtForFilter(List<BankDebtEntity> debts, TimeFilter filter) {
  double total = 0.0;
  for (var debt in debts) {
    switch (filter) {
      case TimeFilter.daily:
      case TimeFilter.weekly:
        break;
      case TimeFilter.monthly:
        total += debt.monthlyInstallmentAmount;
        break;
      case TimeFilter.yearly:
        total += debt.totalAmount;
        break;
    }
  }
  return total;
}
