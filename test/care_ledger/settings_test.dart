import 'package:flutter_test/flutter_test.dart';
import 'package:care_ledger_app/features/settings/domain/participant.dart';
import 'package:care_ledger_app/features/settings/presentation/settings_provider.dart';
import 'package:flutter/material.dart';

void main() {
  group('Participant', () {
    test('initial returns first uppercase letter', () {
      const p = Participant(id: 'p-1', name: 'Alice');
      expect(p.initial, equals('A'));
    });

    test('initial returns ? for empty name', () {
      const p = Participant(id: 'p-1', name: '');
      expect(p.initial, equals('?'));
    });

    test('copyWith preserves unchanged fields', () {
      const p = Participant(id: 'p-1', name: 'Alice');
      final updated = p.copyWith(name: 'Bob');
      expect(updated.id, equals('p-1'));
      expect(updated.name, equals('Bob'));
    });
  });

  group('SettingsProvider', () {
    late SettingsProvider provider;

    setUp(() {
      provider = SettingsProvider();
    });

    test('has default participants', () {
      expect(provider.participantList.length, equals(2));
      expect(provider.participantName('participant-a'), equals('Parent A'));
      expect(provider.participantName('participant-b'), equals('Parent B'));
    });

    test('currentUserId defaults to participant-a', () {
      expect(provider.currentUserId, equals('participant-a'));
    });

    test('updateParticipantName updates name', () {
      provider.updateParticipantName('participant-a', 'Mom');
      expect(provider.participantName('participant-a'), equals('Mom'));
    });

    test('addParticipant adds new participant', () {
      provider.addParticipant(
        const Participant(id: 'participant-c', name: 'Grandma'),
      );
      expect(provider.participantList.length, equals(3));
      expect(provider.participantName('participant-c'), equals('Grandma'));
    });

    test('removeParticipant cannot remove current user', () {
      provider.removeParticipant('participant-a');
      expect(provider.participantList.length, equals(2));
    });

    test('removeParticipant removes other participant', () {
      provider.addParticipant(
        const Participant(id: 'participant-c', name: 'Grandma'),
      );
      provider.removeParticipant('participant-c');
      expect(provider.participantList.length, equals(2));
    });

    test('setLocale updates locale', () {
      provider.setLocale(const Locale('zh'));
      expect(provider.locale.languageCode, equals('zh'));
    });

    test('setThemeMode updates theme', () {
      provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, equals(ThemeMode.dark));
    });

    test('setCurrentUser changes current user', () {
      provider.setCurrentUser('participant-b');
      expect(provider.currentUserId, equals('participant-b'));
    });

    test('participantName fallback to id for unknown', () {
      expect(provider.participantName('unknown'), equals('unknown'));
    });
  });
}
