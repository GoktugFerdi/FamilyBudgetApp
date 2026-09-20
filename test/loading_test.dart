import 'package:flutter_test/flutter_test.dart';
import 'package:family_budget_app/domain/entities/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('transaction provider completes', (tester) async {
    const state = AsyncValue<List<TransactionEntity>>.loading();

    expect(state, isA<AsyncLoading<List<TransactionEntity>>>());
  });
}
