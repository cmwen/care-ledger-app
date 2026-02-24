import 'package:flutter_test/flutter_test.dart';
import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';
import 'package:care_ledger_app/features/ledger/domain/ledger.dart';
import 'package:care_ledger_app/features/ledger/application/ledger_service.dart';
import 'package:care_ledger_app/features/ledger/infrastructure/ledger_repository.dart';
import 'package:care_ledger_app/features/ledger/infrastructure/care_entry_repository.dart';

void main() {
  late LedgerService service;
  late InMemoryLedgerRepository ledgerRepo;
  late InMemoryCareEntryRepository entryRepo;
  late Ledger ledger;

  setUp(() async {
    ledgerRepo = InMemoryLedgerRepository();
    entryRepo = InMemoryCareEntryRepository();
    service = LedgerService(ledgerRepo: ledgerRepo, entryRepo: entryRepo);

    ledger = await service.createLedger(
      title: 'Test Ledger',
      participantAId: 'user-a',
      participantBId: 'user-b',
    );
  });

  group('LedgerService.proposeEntry', () {
    test('creates entry with provided description', () async {
      final entry = await service.proposeEntry(
        ledgerId: ledger.id,
        authorId: 'user-a',
        category: EntryCategory.cooking,
        description: 'Made dinner',
        creditsProposed: 2.0,
        occurredAt: DateTime.now(),
      );
      expect(entry.description, equals('Made dinner'));
      expect(entry.status, equals(EntryStatus.needsReview));
    });

    test('creates entry with category label as description', () async {
      final entry = await service.proposeEntry(
        ledgerId: ledger.id,
        authorId: 'user-a',
        category: EntryCategory.driving,
        description: EntryCategory.driving.label,
        creditsProposed: 1.0,
        occurredAt: DateTime.now(),
      );
      expect(entry.description, equals('Driving'));
    });
  });

  group('LedgerService.editEntry', () {
    test('edits entry in needs_review status', () async {
      final entry = await service.proposeEntry(
        ledgerId: ledger.id,
        authorId: 'user-a',
        category: EntryCategory.cooking,
        description: 'Original',
        creditsProposed: 1.0,
        occurredAt: DateTime.now(),
      );

      final updated = await service.editEntry(
        entryId: entry.id,
        description: 'Updated description',
        creditsProposed: 2.0,
      );

      expect(updated.description, equals('Updated description'));
      expect(updated.creditsProposed, equals(2.0));
      expect(updated.revision, equals(2));
    });

    test('rejects edit of confirmed entry', () async {
      final entry = await service.proposeEntry(
        ledgerId: ledger.id,
        authorId: 'user-a',
        category: EntryCategory.cooking,
        description: 'Test',
        creditsProposed: 1.0,
        occurredAt: DateTime.now(),
      );

      // Manually confirm for test
      final confirmed = entry.copyWith(status: EntryStatus.confirmed);
      await entryRepo.save(confirmed);

      expect(
        () => service.editEntry(entryId: entry.id, description: 'Changed'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('LedgerService.deleteEntry', () {
    test('deletes entry in needs_review status', () async {
      final entry = await service.proposeEntry(
        ledgerId: ledger.id,
        authorId: 'user-a',
        category: EntryCategory.cooking,
        description: 'To delete',
        creditsProposed: 1.0,
        occurredAt: DateTime.now(),
      );

      await service.deleteEntry(entry.id);
      final result = await entryRepo.getById(entry.id);
      expect(result, isNull);
    });

    test('rejects deletion of confirmed entry', () async {
      final entry = await service.proposeEntry(
        ledgerId: ledger.id,
        authorId: 'user-a',
        category: EntryCategory.cooking,
        description: 'Confirmed',
        creditsProposed: 1.0,
        occurredAt: DateTime.now(),
      );

      final confirmed = entry.copyWith(status: EntryStatus.confirmed);
      await entryRepo.save(confirmed);

      expect(() => service.deleteEntry(entry.id), throwsA(isA<StateError>()));
    });

    test('throws for non-existent entry', () {
      expect(
        () => service.deleteEntry('non-existent'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
