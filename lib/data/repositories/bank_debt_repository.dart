import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_budget_app/domain/entities/bank_debt.dart';
import 'package:family_budget_app/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

final bankDebtRepositoryProvider = Provider((ref) {
  final auth = ref.watch(authProvider);
  return BankDebtRepository(
    activePlan: auth.activePlan,
    userId: auth.userId,
    familyId: auth.familyId,
  );
});

class BankDebtRepository {
  final String activePlan;
  final String? userId;
  final String? familyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BankDebtRepository({required this.activePlan, this.userId, this.familyId});

  CollectionReference? get _collection {
    if (activePlan == 'family' && familyId != null) {
      return _firestore
          .collection('bank_debts_family')
          .doc(familyId)
          .collection('items');
    } else if (userId != null) {
      return _firestore
          .collection('bank_debts_personal')
          .doc(userId)
          .collection('items');
    } else {
      return null;
    }
  }

  BankDebtEntity mapFirestoreDataToEntity(Map<String, dynamic> data) {
    final dueDateValue = data['dueDate'];
    DateTime? parsedDueDate;

    if (dueDateValue is String) {
      parsedDueDate = DateTime.tryParse(dueDateValue);
    } else if (dueDateValue is Timestamp) {
      parsedDueDate = dueDateValue.toDate();
    }

    return BankDebtEntity(
      id: data['id'] as int?,
      creditorName: data['creditorName'] as String? ?? 'Banka',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      installmentCount: data['installmentCount'] as int? ?? 1,
      dueDate: parsedDueDate,
    );
  }

  Future<List<BankDebtEntity>> getAllDebts() async {
    final col = _collection;
    if (col == null) return [];
    try {
      final snapshot = await col.get();
      final List<BankDebtEntity> debts = snapshot.docs
          .map<BankDebtEntity>(
            (doc) => mapFirestoreDataToEntity(doc.data() as Map<String, dynamic>),
          )
          .toList();

      debts.sort((a, b) {
        final leftDate = a.dueDate ?? DateTime.now();
        final rightDate = b.dueDate ?? DateTime.now();
        return leftDate.compareTo(rightDate);
      });
      return debts;
    } catch (e) {
      debugPrint('Firestore getAllDebts error: $e');
      return [];
    }
  }

  Future<int> insert(BankDebtEntity debt) async {
    final col = _collection;
    if (col == null) return 0;
    try {
      final newId = DateTime.now().millisecondsSinceEpoch;
      final newDebt = debt.copyWith(id: newId);

      await col.doc(newId.toString()).set({
        'id': newId,
        'creditorName': newDebt.creditorName,
        'totalAmount': newDebt.totalAmount,
        'installmentCount': newDebt.installmentCount,
        'dueDate': newDebt.dueDate?.toIso8601String(),
      });

      return newId;
    } catch (e) {
      debugPrint('Firestore insert debt error: $e');
      return 0;
    }
  }

  Future<int> updateRemainingAmount(int id, double newAmount) async {
    final col = _collection;
    if (col == null) return 0;
    try {
      await col.doc(id.toString()).update({'totalAmount': newAmount});
      return id;
    } catch (e) {
      debugPrint('Firestore update debt error: $e');
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
      debugPrint('Firestore delete debt error: $e');
      return 0;
    }
  }
}
