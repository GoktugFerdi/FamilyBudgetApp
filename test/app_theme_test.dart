import 'package:family_budget_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppTheme creates a valid theme for each preset', () {
    final midnight = AppTheme.getTheme(AppThemeType.midnightBlue);
    final maroon = AppTheme.getTheme(AppThemeType.maroon);
    final marble = AppTheme.getTheme(AppThemeType.marbleWhite);

    expect(midnight.brightness, Brightness.dark);
    expect(maroon.brightness, Brightness.dark);
    expect(marble.brightness, Brightness.dark);
  });
}
