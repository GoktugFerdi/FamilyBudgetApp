import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final alertProvider = StateNotifierProvider<AlertNotifier, Set<int>>((ref) {
  return AlertNotifier();
});

class AlertNotifier extends StateNotifier<Set<int>> {
  AlertNotifier() : super({}) {
    _loadDismissedAlerts();
  }

  Future<void> _loadDismissedAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    final Set<int> dismissedToday = {};
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';

    for (var key in keys) {
      if (key.startsWith('dismissed_alert_')) {
        final dateStr = prefs.getString(key);
        if (dateStr == todayStr) {
          final debtId = int.tryParse(key.replaceFirst('dismissed_alert_', ''));
          if (debtId != null) {
            dismissedToday.add(debtId);
          }
        } else {
          // Eski tarihli olanları temizle
          await prefs.remove(key);
        }
      }
    }
    state = dismissedToday;
  }

  Future<void> dismissAlert(int debtId) async {
    // State'i hemen güncelle
    state = {...state, debtId};
    
    // SharedPreferences'a bugünün tarihiyle kaydet
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';
    
    await prefs.setString('dismissed_alert_$debtId', todayStr);
  }
}
