import 'package:family_budget_app/data/repositories/transaction_repository.dart';
import 'package:family_budget_app/domain/entities/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TimeFilter {
  daily,
  weekly,
  monthly,
  yearly
}

final timeFilterProvider = StateProvider<TimeFilter>((ref) => TimeFilter.monthly);

final transactionProvider = StateNotifierProvider<TransactionNotifier, AsyncValue<List<TransactionEntity>>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionNotifier(repository);
});

// Seçilen zaman aralığına göre filtrelenmiş işlemleri döndürür
final filteredTransactionsProvider = Provider<AsyncValue<List<TransactionEntity>>>((ref) {
  final asyncTransactions = ref.watch(transactionProvider);
  final filter = ref.watch(timeFilterProvider);

  return asyncTransactions.whenData((transactions) {
    final now = DateTime.now();
    return transactions.where((t) {
      switch (filter) {
        case TimeFilter.daily:
          return t.date.year == now.year && t.date.month == now.month && t.date.day == now.day;
        case TimeFilter.weekly:
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          return t.date.isAfter(startOfWeekDate.subtract(const Duration(seconds: 1)));
        case TimeFilter.monthly:
          return t.date.year == now.year && t.date.month == now.month;
        case TimeFilter.yearly:
          return t.date.year == now.year;
      }
    }).toList();
  });
});

class TransactionNotifier extends StateNotifier<AsyncValue<List<TransactionEntity>>> {
  final TransactionRepository _repository;

  TransactionNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    if (_repository.userId == null && _repository.familyId == null) {
      if (mounted) state = const AsyncValue.data([]);
      return;
    }

    try {
      final transactions = await _repository.getAllTransactions();
      if (mounted) state = AsyncValue.data(transactions);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTransaction(TransactionEntity transaction) async {
    await _repository.insert(transaction);
    await loadTransactions();
  }

  Future<void> deleteTransaction(int id) async {
    await _repository.delete(id);
    await loadTransactions();
  }

  Future<void> updateTransaction(TransactionEntity transaction) async {
    await _repository.update(transaction);
    await loadTransactions();
  }
}

// Yardımcı hesaplama fonksiyonları
double getTotalIncome(List<TransactionEntity> transactions) {
  return transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, item) => sum + item.amount);
}

double getTotalExpense(List<TransactionEntity> transactions) {
  return transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, item) => sum + item.amount);
}

double getTotalDebt(List<TransactionEntity> transactions) {
  return transactions
      .where((t) => t.type == TransactionType.debt)
      .fold(0.0, (sum, item) => sum + item.amount);
}

double getTotalInvestment(List<TransactionEntity> transactions) {
  return transactions
      .where((t) => t.type == TransactionType.investment)
      .fold(0.0, (sum, item) => sum + item.amount);
}

double getNetBalance(List<TransactionEntity> transactions) {
  return getTotalIncome(transactions) - getTotalExpense(transactions) - getTotalDebt(transactions) - getTotalInvestment(transactions);
}
