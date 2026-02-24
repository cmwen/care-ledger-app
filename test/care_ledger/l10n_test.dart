import 'package:flutter_test/flutter_test.dart';
import 'package:care_ledger_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

void main() {
  group('AppLocalizations', () {
    test('English locale returns English strings', () {
      final l10n = AppLocalizations(const Locale('en'));
      expect(l10n.get('appTitle'), equals('Care Ledger'));
      expect(l10n.get('ledger'), equals('Ledger'));
      expect(l10n.get('settings'), equals('Settings'));
    });

    test('Chinese locale returns Chinese strings', () {
      final l10n = AppLocalizations(const Locale('zh'));
      expect(l10n.get('appTitle'), equals('照护账本'));
      expect(l10n.get('ledger'), equals('账本'));
      expect(l10n.get('settings'), equals('设置'));
    });

    test('unsupported locale falls back to English', () {
      final l10n = AppLocalizations(const Locale('fr'));
      expect(l10n.get('appTitle'), equals('Care Ledger'));
    });

    test('unknown key returns key itself', () {
      final l10n = AppLocalizations(const Locale('en'));
      expect(l10n.get('nonExistentKey'), equals('nonExistentKey'));
    });

    test('supportedLocales includes en and zh', () {
      expect(AppLocalizations.supportedLocales.length, equals(2));
      expect(
        AppLocalizations.supportedLocales.any((l) => l.languageCode == 'en'),
        isTrue,
      );
      expect(
        AppLocalizations.supportedLocales.any((l) => l.languageCode == 'zh'),
        isTrue,
      );
    });
  });
}
