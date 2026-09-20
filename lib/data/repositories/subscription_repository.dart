import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:family_budget_app/domain/entities/subscription.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:family_budget_app/presentation/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';

final subscriptionRepositoryProvider = Provider((ref) {
  final auth = ref.watch(authProvider);
  return SubscriptionRepository(
    activePlan: auth.activePlan,
    userId: auth.userId,
    familyId: auth.familyId,
  );
});

class SubscriptionRepository {
  final String activePlan;
  final String? userId;
  final String? familyId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SubscriptionRepository({
    required this.activePlan,
    this.userId,
    this.familyId,
  });

  CollectionReference? get _collection {
    if (activePlan == 'family' && familyId != null) {
      return _firestore.collection('subscriptions_family').doc(familyId).collection('items');
    } else if (userId != null) {
      return _firestore.collection('subscriptions_personal').doc(userId).collection('items');
    } else {
      return null;
    }
  }

  Future<List<Subscription>> getAllSubscriptions() async {
    final col = _collection;
    if (col == null) return [];
    try {
      final snapshot = await col.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Subscription.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Firestore getAllSubscriptions error: $e');
      return [];
    }
  }

  Future<void> addSubscription(Subscription subscription) async {
    final col = _collection;
    if (col == null) return;
    try {
      await col.add(subscription.toMap());
    } catch (e) {
      debugPrint('Firestore addSubscription error: $e');
    }
  }

  Future<void> deleteSubscription(String id) async {
    final col = _collection;
    if (col == null) return;
    try {
      await col.doc(id).delete();
    } catch (e) {
      debugPrint('Firestore deleteSubscription error: $e');
    }
  }
}