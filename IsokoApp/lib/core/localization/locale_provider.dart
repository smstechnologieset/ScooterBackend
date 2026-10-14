import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/account/data/providers.dart';

/// Notifier managing the app's active Locale (defaults to English 'en').
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._ref) : super(const Locale('en')) {
    _initFromPreferences();
  }

  final Ref _ref;

  void _initFromPreferences() {
    final prefs = _ref.read(currentPreferencesProvider);
    if (prefs != null && prefs.languageCode.isNotEmpty) {
      final code = prefs.languageCode.toLowerCase();
      if (code == 'fr' || code == 'french') {
        state = const Locale('fr');
      } else {
        state = const Locale('en');
      }
    }
  }

  void setLocale(Locale locale) {
    if (state == locale) return;
    state = locale;

    // Update the in-memory preferences if user is logged in
    final currentPrefs = _ref.read(currentPreferencesProvider);
    if (currentPrefs != null) {
      _ref.read(currentPreferencesProvider.notifier).state =
          currentPrefs.copyWith(languageCode: locale.languageCode);
    }
  }

  void setLanguageCode(String languageCode) {
    final normalized = languageCode.trim().toLowerCase();
    if (normalized == 'fr' || normalized == 'french' || normalized == 'français') {
      setLocale(const Locale('fr'));
    } else {
      setLocale(const Locale('en'));
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref);
});
