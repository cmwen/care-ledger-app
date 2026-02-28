import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:care_ledger_app/core/identity_service.dart';
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
    late IdentityService identity;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'cl_device_id': 'test-device-id',
        'cl_user_name': 'Test User',
        'cl_is_onboarded': true,
        'cl_partner_id': 'test-partner-id',
        'cl_partner_name': 'Test Partner',
        'cl_is_paired': true,
        'cl_invite_code': 'ABC123',
      });
      identity = await IdentityService.create();
      provider = SettingsProvider(identity: identity);
    });

    test('has participants from identity', () {
      expect(provider.participantList.length, equals(2));
      expect(provider.participantName('test-device-id'), equals('Test User'));
      expect(
        provider.participantName('test-partner-id'),
        equals('Test Partner'),
      );
    });

    test('currentUserId matches device id', () {
      expect(provider.currentUserId, equals('test-device-id'));
    });

    test('updateParticipantName updates name', () {
      provider.updateParticipantName('test-device-id', 'Mom');
      expect(provider.participantName('test-device-id'), equals('Mom'));
    });

    test('addParticipant adds new participant', () {
      provider.addParticipant(
        const Participant(id: 'participant-c', name: 'Grandma'),
      );
      expect(provider.participantList.length, equals(3));
      expect(provider.participantName('participant-c'), equals('Grandma'));
    });

    test('removeParticipant cannot remove current user', () {
      provider.removeParticipant('test-device-id');
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

    test('isOnboarded reflects identity state', () {
      expect(provider.isOnboarded, isTrue);
    });

    test('isPaired reflects identity state', () {
      expect(provider.isPaired, isTrue);
    });

    test('participantName fallback to id for unknown', () {
      expect(provider.participantName('unknown'), equals('unknown'));
    });
  });

  group('SettingsProvider — fresh identity', () {
    late SettingsProvider provider;
    late IdentityService identity;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      identity = await IdentityService.create();
      provider = SettingsProvider(identity: identity);
    });

    test('starts not onboarded', () {
      expect(provider.isOnboarded, isFalse);
    });

    test('starts not paired', () {
      expect(provider.isPaired, isFalse);
    });

    test('completeOnboarding updates state', () async {
      await provider.completeOnboarding('Alice');
      expect(provider.isOnboarded, isTrue);
      expect(provider.currentUser?.name, equals('Alice'));
    });

    test('completePairing updates state', () async {
      await provider.completeOnboarding('Alice');
      await provider.completePairing('Bob', 'bob-device-id');
      expect(provider.isPaired, isTrue);
      expect(provider.participantName('bob-device-id'), equals('Bob'));
    });
  });
}
