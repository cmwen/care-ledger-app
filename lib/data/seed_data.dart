import 'package:care_ledger_app/core/ids.dart';
import 'package:care_ledger_app/features/ledger/domain/ledger.dart';
import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';
import 'package:care_ledger_app/features/ledger/infrastructure/ledger_repository.dart';
import 'package:care_ledger_app/features/ledger/infrastructure/care_entry_repository.dart';
import 'package:care_ledger_app/features/settlements/domain/settlement.dart';
import 'package:care_ledger_app/features/settlements/infrastructure/settlement_repository.dart';

/// Seeds the in-memory repositories with sample data for development.
///
/// Creates a ledger with two participants and a variety of
/// care entries in different statuses to exercise the UI.
class SeedData {
  static const participantAId = 'participant-a';
  static const participantBId = 'participant-b';

  static Future<String> seed({
    required LedgerRepository ledgerRepo,
    required CareEntryRepository entryRepo,
    required SettlementRepository settlementRepo,
  }) async {
    // Create a ledger
    final now = DateTime.now();
    final ledgerId = IdGenerator.generate();
    final ledger = Ledger(
      id: ledgerId,
      title: 'Family Care Ledger',
      participantAId: participantAId,
      participantBId: participantBId,
      createdAt: now.subtract(const Duration(days: 30)),
    );
    await ledgerRepo.save(ledger);

    // Seed care entries across the past two weeks
    final entries = [
      // This week — needs review
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: participantAId,
        occurredAt: now.subtract(const Duration(days: 1)),
        category: EntryCategory.driving,
        description: 'Drove kids to school and back',
        durationMinutes: 45,
        creditsProposed: 2.0,
        sourceType: SourceType.suggested,
        sourceHint: 'Detected repeated morning drive pattern',
        status: EntryStatus.pendingCounterpartyReview,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: participantAId,
        occurredAt: now.subtract(const Duration(days: 2)),
        category: EntryCategory.cooking,
        description: 'Prepared dinner for everyone',
        durationMinutes: 60,
        creditsProposed: 2.5,
        status: EntryStatus.pendingCounterpartyReview,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: participantBId,
        occurredAt: now.subtract(const Duration(days: 2)),
        category: EntryCategory.childcare,
        description: 'Picked up kids from sports practice',
        durationMinutes: 30,
        creditsProposed: 1.5,
        status: EntryStatus.pendingCounterpartyReview,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: participantAId,
        occurredAt: now.subtract(const Duration(days: 3)),
        category: EntryCategory.laundry,
        description: 'Did two loads of laundry',
        creditsProposed: 1.5,
        sourceType: SourceType.suggested,
        sourceHint: 'Weekly laundry pattern detected',
        status: EntryStatus.needsReview,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),

      // Last week — confirmed
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: participantAId,
        occurredAt: now.subtract(const Duration(days: 8)),
        category: EntryCategory.driving,
        description: 'School pickup and drop-off',
        durationMinutes: 40,
        creditsProposed: 2.0,
        creditsConfirmed: 2.0,
        status: EntryStatus.confirmed,
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: participantBId,
        occurredAt: now.subtract(const Duration(days: 9)),
        category: EntryCategory.shopping,
        description: 'Weekly grocery shopping',
        durationMinutes: 90,
        creditsProposed: 3.0,
        creditsConfirmed: 3.0,
        status: EntryStatus.confirmed,
        createdAt: now.subtract(const Duration(days: 9)),
        updatedAt: now.subtract(const Duration(days: 8)),
      ),
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: participantAId,
        occurredAt: now.subtract(const Duration(days: 10)),
        category: EntryCategory.emotionalSupport,
        description: 'Helped with homework and bedtime routine',
        durationMinutes: 120,
        creditsProposed: 3.0,
        creditsConfirmed: 3.0,
        status: EntryStatus.confirmed,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 9)),
      ),
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: participantBId,
        occurredAt: now.subtract(const Duration(days: 10)),
        category: EntryCategory.medical,
        description: 'Took child to dentist appointment',
        durationMinutes: 90,
        creditsProposed: 2.5,
        creditsConfirmed: 2.5,
        status: EntryStatus.confirmed,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 9)),
      ),

      // Needs edit
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: participantBId,
        occurredAt: now.subtract(const Duration(days: 5)),
        category: EntryCategory.planning,
        description: 'Organized weekend activity schedule',
        creditsProposed: 1.0,
        status: EntryStatus.needsEdit,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 4)),
      ),

      // Rejected
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: participantAId,
        occurredAt: now.subtract(const Duration(days: 12)),
        category: EntryCategory.housework,
        description: 'General tidying up',
        creditsProposed: 0.5,
        status: EntryStatus.rejected,
        createdAt: now.subtract(const Duration(days: 12)),
        updatedAt: now.subtract(const Duration(days: 11)),
      ),
    ];

    for (final entry in entries) {
      await entryRepo.save(entry);
    }

    // Seed a completed settlement
    final settlement = Settlement(
      id: IdGenerator.generate(),
      ledgerId: ledgerId,
      proposerId: participantBId,
      method: SettlementMethod.cash,
      credits: 5.0,
      note: 'Settling last month\'s balance',
      status: SettlementStatus.completed,
      completedAt: now.subtract(const Duration(days: 14)),
      createdAt: now.subtract(const Duration(days: 16)),
      updatedAt: now.subtract(const Duration(days: 14)),
    );
    await settlementRepo.save(settlement);

    return ledgerId;
  }
}
