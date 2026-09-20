import 'package:family_budget_app/core/localization/app_translations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('tr') {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language_code') ?? 'tr';
    state = lang;
  }

  Future<void> setLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', langCode);
    state = langCode;
  }
}

// Global olarak çevirilere erişmek için yardımcı bir extension
extension StringLocalization on String {
  String tr(WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final map = AppTranslations.translations[lang] ?? AppTranslations.translations['tr']!;
    return map[this] ?? this;
  }
}
