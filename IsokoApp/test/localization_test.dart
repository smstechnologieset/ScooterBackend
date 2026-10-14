import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isoko_scooter/core/localization/app_localizations.dart';
import 'package:isoko_scooter/core/localization/locale_provider.dart';

void main() {
  group('Localization Tests', () {
    test('AppLocalizations provides correct English strings by default', () {
      final l10n = AppLocalizations(const Locale('en'));
      expect(l10n.strings.signInNow, 'Sign in Now');
      expect(l10n.strings.signUpNow, 'Sign Up Now');
      expect(l10n.strings.settingsTitle, 'Settings');
      expect(l10n.strings.selectLanguage, 'Select Language');
      expect(l10n.strings.english, 'English');
      expect(l10n.strings.french, 'Français');
      expect(l10n.strings.scanNow, 'Scan Now');
      expect(l10n.strings.endRide, 'End Ride');
    });

    test('AppLocalizations provides correct French strings', () {
      final l10n = AppLocalizations(const Locale('fr'));
      expect(l10n.strings.signInNow, 'Connexion');
      expect(l10n.strings.signUpNow, 'Créer un compte');
      expect(l10n.strings.settingsTitle, 'Paramètres');
      expect(l10n.strings.selectLanguage, 'Choisir la langue');
      expect(l10n.strings.english, 'English');
      expect(l10n.strings.french, 'Français');
      expect(l10n.strings.scanNow, 'Scanner');
      expect(l10n.strings.endRide, 'Terminer le trajet');
    });

    test('LocaleNotifier switches between English and French reactively', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(localeProvider), const Locale('en'));

      container.read(localeProvider.notifier).setLanguageCode('fr');
      expect(container.read(localeProvider), const Locale('fr'));

      container.read(localeProvider.notifier).setLanguageCode('en');
      expect(container.read(localeProvider), const Locale('en'));
    });
  });
}
