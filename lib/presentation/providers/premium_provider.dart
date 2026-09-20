import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:family_budget_app/presentation/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final premiumProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isPremium;
});

final premiumActionsProvider = Provider((ref) {
  return PremiumActions(ref);
});

class PremiumActions {
  final Ref ref;
  PremiumActions(this.ref);

  Future<void> purchasePremium() async {
    final authState = ref.read(authProvider);
    if (authState.userId == null) return;

    final firestore = FirebaseFirestore.instance;

    // Aileye bağlıysa tüm aileyi premium yap
    if (authState.familyId != null) {
      await firestore.collection('families').doc(authState.familyId).set({
        'isPremium': true,
      }, SetOptions(merge: true));
    }

    // Kendi hesabını da premium yap
    await firestore.collection('users').doc(authState.userId).update({
      'isPremium': true,
    });
  }
}
