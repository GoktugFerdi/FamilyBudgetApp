import 'package:flutter/material.dart';

enum AppThemeType { midnightBlue, maroon, marbleWhite, royalPearl, baroqueMoss, oceanBlue, emeraldGreen }

class AppTheme {
  // Gece Mavisi (Midnight Blue)
  static const Color _midnightPrimary = Color(0xFF192A56);
  static const Color _midnightBackground = Color(0xFF0D1B2A);
  static const Color _midnightSurface = Color(0xFF1B263B);

  // Bordo (Maroon)
  static const Color _maroonPrimary = Color(0xFF800000);
  static const Color _maroonBackground = Color(0xFF2B0000);
  static const Color _maroonSurface = Color(0xFF4A0000);

  // Mermer Beyazı (Marble White)
  static const Color _marblePrimary = Color(0xFFD6D6D6);
  static const Color _marbleBackground = Color(0xFF121212);
  static const Color _marbleSurface = Color(0xFF2C2C2C);

  // Kraliyet İncisi (Royal Pearl) - Açık Tema
  static const Color _royalPrimary = Color(0xFFB8860B); // Altın kahverengi
  static const Color _royalBackground = Color(0xFFFDFBF7); // İnci beyazı
  static const Color _royalSurface = Color(0xFFF4EFE6);

  // Barok Yosun (Baroque Moss) - Soft Koyu Tema
  static const Color _baroquePrimary = Color(0xFF8B008B); // Barok moru
  static const Color _baroqueBackground = Color(
    0xFF1E2723,
  ); // Hafif koyu soft zemin
  static const Color _baroqueSurface = Color(0xFF2C3933); // Yosun yeşili yüzey

  // Okyanus Mavisi (Ocean Blue)
  static const Color _oceanPrimary = Color(0xFF0077B6);
  static const Color _oceanBackground = Color(0xFFE8F1F2);
  static const Color _oceanSurface = Color(0xFFFFFFFF);

  // Zümrüt Yeşili (Emerald Green)
  static const Color _emeraldPrimary = Color(0xFF2ECC71);
  static const Color _emeraldBackground = Color(0xFFF0FDF4);
  static const Color _emeraldSurface = Color(0xFFFFFFFF);

  // Ortak Renkler (Gelir, Gider, Borç, Yatırım)
  static const Color incomeColor = Color(0xFF2ECC71); // Yeşil
  static const Color expenseColor = Color(0xFFE74C3C); // Kırmızı
  static const Color debtColor = Color(0xFFF1C40F); // Sarı
  static const Color investmentColor = Color(0xFF3498DB); // Mavi

  // Tema renk erişimi için kısa alanlar
  static const Color midnightBlue = _midnightPrimary;
  static const Color maroon = _maroonPrimary;
  static const Color marbleWhite = _marblePrimary;
  static const Color royalPearl = _royalPrimary;
  static const Color baroqueMoss = _baroquePrimary;
  static const Color oceanBlue = _oceanPrimary;
  static const Color emeraldGreen = _emeraldPrimary;

  static ThemeData getTheme(AppThemeType type) {
    switch (type) {
      case AppThemeType.midnightBlue:
        return _buildTheme(
          _midnightPrimary,
          _midnightBackground,
          _midnightSurface,
          Brightness.dark,
        );
      case AppThemeType.maroon:
        return _buildTheme(
          _maroonPrimary,
          _maroonBackground,
          _maroonSurface,
          Brightness.dark,
        );
      case AppThemeType.marbleWhite:
        return _buildTheme(
          _marblePrimary,
          _marbleBackground,
          _marbleSurface,
          Brightness.dark,
        );
      case AppThemeType.royalPearl:
        return _buildTheme(
          _royalPrimary,
          _royalBackground,
          _royalSurface,
          Brightness.light,
        );
      case AppThemeType.baroqueMoss:
        return _buildTheme(
          _baroquePrimary,
          _baroqueBackground,
          _baroqueSurface,
          Brightness.dark,
        );
      case AppThemeType.oceanBlue:
        return _buildTheme(
          _oceanPrimary,
          _oceanBackground,
          _oceanSurface,
          Brightness.light,
        );
      case AppThemeType.emeraldGreen:
        return _buildTheme(
          _emeraldPrimary,
          _emeraldBackground,
          _emeraldSurface,
          Brightness.light,
        );
    }
  }

  static ThemeData _buildTheme(
    Color primary,
    Color background,
    Color surface,
    Brightness brightness,
  ) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        surface: surface,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: brightness == Brightness.dark ? Colors.white : Colors.black87,
        ),
        titleTextStyle: TextStyle(
          color: brightness == Brightness.dark ? Colors.white : Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
