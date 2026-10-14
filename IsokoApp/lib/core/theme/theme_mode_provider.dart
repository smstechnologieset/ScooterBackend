import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State notifier for managing active theme mode (Dark by default matching Figma).
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark);

  void setThemeMode(ThemeMode mode) {
    if (state == mode) return;
    state = mode;
  }

  void setThemeModeByName(String mode) {
    final normalized = mode.trim().toLowerCase();
    if (normalized == 'light' || normalized == 'clair') {
      setThemeMode(ThemeMode.light);
    } else if (normalized == 'system' || normalized == 'système') {
      setThemeMode(ThemeMode.system);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
    } else {
      state = ThemeMode.dark;
    }
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
