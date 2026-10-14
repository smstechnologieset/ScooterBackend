import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isoko_scooter/core/theme/theme_mode_provider.dart';

void main() {
  group('Theme and App Mode Tests', () {
    test('ThemeModeNotifier defaults to dark mode matching design', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('ThemeModeNotifier switches between Dark, Light, and System modes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);

      notifier.setThemeMode(ThemeMode.light);
      expect(container.read(themeModeProvider), ThemeMode.light);

      notifier.setThemeMode(ThemeMode.system);
      expect(container.read(themeModeProvider), ThemeMode.system);

      notifier.setThemeMode(ThemeMode.dark);
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });

    test('ThemeModeNotifier handles string names and toggling', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);

      notifier.setThemeModeByName('light');
      expect(container.read(themeModeProvider), ThemeMode.light);

      notifier.toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.dark);

      notifier.toggleTheme();
      expect(container.read(themeModeProvider), ThemeMode.light);

      notifier.setThemeModeByName('system');
      expect(container.read(themeModeProvider), ThemeMode.system);

      notifier.setThemeModeByName('dark');
      expect(container.read(themeModeProvider), ThemeMode.dark);
    });
  });
}
