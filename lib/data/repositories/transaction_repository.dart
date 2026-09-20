import 'package:family_budget_app/domain/entities/transaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_budget_app/presentation/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';

final transactionRepositoryProvider = Provider((ref) {
  final auth = ref.watch(authProvider);
  return TransactionRepository(
    activePlan: auth.activePlan,
    userId: auth.userId,
    familyId: auth.familyId,
  );
});

class TransactionRepository {
  final String activePlan;
  final String? userId;
  final String? familyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TransactionRepository({required this.activePlan, this.userId, this.familyId});

  CollectionReference? get _collection {
    if (activePlan == 'family' && familyId != null) {
      return _firestore
          .collection('transactions_family')
          .doc(familyId)
          .collection('items');
    } else if (userId != null) {
      return _firestore
          .collection('transactions_personal')
          .doc(userId)
          .collection('items');
    } else {
      return null;
    }
  }

  Future<List<TransactionEntity>> getAllTransactions() async {
    final col = _collection;
    if (col == null) return [];
    try {
      final snapshot = await col.get();
      final transactions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return TransactionEntity(
          id: data['id'] as int?,
          title: data['title'] as String? ?? '',
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
          date: DateTime.tryParse(data['date'] as String? ?? '') ?? DateTime.now(),
          type: TransactionType.values[(data['type'] as int?) ?? 0],
          description: data['description'] as String?,
          creatorName: data['creatorName'] as String?,
        );
      }).toList();

      transactions.sort((a, b) => b.date.compareTo(a.date));
      return transactions;
    } catch (e) {
      debugPrint('Firestore getAllTransactions error: $e');
      return [];
    }
  }

  Future<int> insert(TransactionEntity transaction) async {
    final col = _collection;
    if (col == null) return 0;
    try {
      final newId = DateTime.now().millisecondsSinceEpoch;
      final newTransaction = transaction.copyWith(id: newId);

      await col.doc(newId.toString()).set({
        'id': newId,
        'title': newTransaction.title,
        'amount': newTransaction.amount,
        'date': newTransaction.date.toIso8601String(),
        'type': newTransaction.type.index,
        'description': newTransaction.description,
        'creatorName': newTransaction.creatorName,
      });

      return newId;
    } catch (e) {
      debugPrint('Firestore insert error: $e');
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
      debugPrint('Firestore delete error: $e');
      return 0;
    }
  }

  Future<int> update(TransactionEntity transaction) async {
    final col = _collection;
    if (col == null || transaction.id == null) return 0;
    try {
      await col.doc(transaction.id.toString()).update({
        'title': transaction.title,
        'amount': transaction.amount,
        'date': transaction.date.toIso8601String(),
        'type': transaction.type.index,
        'description': transaction.description,
        'creatorName': transaction.creatorName,
      });
      return transaction.id!;
    } catch (e) {
      debugPrint('Firestore update error: $e');
      return 0;
    }
  }
}
