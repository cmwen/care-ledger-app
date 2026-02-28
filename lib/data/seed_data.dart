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
  /// Fallback IDs used when no identity service is available.
  static const fallbackParticipantAId = 'participant-a';
  static const fallbackParticipantBId = 'participant-b';

  static Future<String> seed({
    required LedgerRepository ledgerRepo,
    required CareEntryRepository entryRepo,
    required SettlementRepository settlementRepo,
    String? participantAId,
    String? participantBId,
  }) async {
    final pAId = participantAId ?? fallbackParticipantAId;
    final pBId = participantBId ?? fallbackParticipantBId;

    // Create a ledger
    final now = DateTime.now();
    final ledgerId = IdGenerator.generate();
    final ledger = Ledger(
      id: ledgerId,
      title: 'Family Care Ledger',
      participantAId: pAId,
      participantBId: pBId,
      createdAt: now.subtract(const Duration(days: 30)),
    );
    await ledgerRepo.save(ledger);

    // Seed care entries across the past four weeks for pattern detection.
    //
    // Recurring patterns seeded:
    //  - Driving (pA): weekdays (Mon-Fri) mornings
    //  - Cooking (pA): Tue, Thu, Sat evenings
    //  - Shopping (pB): Saturdays
    //  - Childcare (pB): Mon, Wed, Fri afternoons
    //  - Laundry (pA): Sundays
    final entries = <CareEntry>[];

    // Helper to create a date at a specific weekday N weeks ago.
    DateTime weekdayDate(int weeksAgo, int weekday, int hour, int minute) {
      final today = DateTime(now.year, now.month, now.day);
      final startOfThisWeek = today.subtract(Duration(days: today.weekday - 1));
      final startOfTargetWeek = startOfThisWeek.subtract(
        Duration(days: weeksAgo * 7),
      );
      return startOfTargetWeek.add(
        Duration(days: weekday - 1, hours: hour, minutes: minute),
      );
    }

    // ── Week -3 (3 weeks ago) — all confirmed ──
    for (final weekday in [1, 2, 3, 4, 5]) {
      entries.add(
        CareEntry(
          id: IdGenerator.generate(),
          ledgerId: ledgerId,
          authorId: pAId,
          occurredAt: weekdayDate(3, weekday, 8, 15),
          category: EntryCategory.driving,
          description: 'Drove kids to school and back',
          durationMinutes: 45,
          creditsProposed: 2.0,
          creditsConfirmed: 2.0,
          status: EntryStatus.confirmed,
          createdAt: weekdayDate(3, weekday, 8, 15),
          updatedAt: weekdayDate(3, weekday, 10, 0),
        ),
      );
    }
    for (final weekday in [2, 4, 6]) {
      entries.add(
        CareEntry(
          id: IdGenerator.generate(),
          ledgerId: ledgerId,
          authorId: pAId,
          occurredAt: weekdayDate(3, weekday, 18, 0),
          category: EntryCategory.cooking,
          description: 'Prepared dinner for everyone',
          durationMinutes: 60,
          creditsProposed: 2.5,
          creditsConfirmed: 2.5,
          status: EntryStatus.confirmed,
          createdAt: weekdayDate(3, weekday, 18, 0),
          updatedAt: weekdayDate(3, weekday, 20, 0),
        ),
      );
    }
    entries.add(
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: pBId,
        occurredAt: weekdayDate(3, 6, 10, 0),
        category: EntryCategory.shopping,
        description: 'Weekly grocery shopping',
        durationMinutes: 90,
        creditsProposed: 3.0,
        creditsConfirmed: 3.0,
        status: EntryStatus.confirmed,
        createdAt: weekdayDate(3, 6, 10, 0),
        updatedAt: weekdayDate(3, 6, 12, 0),
      ),
    );
    for (final weekday in [1, 3, 5]) {
      entries.add(
        CareEntry(
          id: IdGenerator.generate(),
          ledgerId: ledgerId,
          authorId: pBId,
          occurredAt: weekdayDate(3, weekday, 15, 30),
          category: EntryCategory.childcare,
          description: 'Picked up kids from sports practice',
          durationMinutes: 30,
          creditsProposed: 1.5,
          creditsConfirmed: 1.5,
          status: EntryStatus.confirmed,
          createdAt: weekdayDate(3, weekday, 15, 30),
          updatedAt: weekdayDate(3, weekday, 17, 0),
        ),
      );
    }
    entries.add(
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: pAId,
        occurredAt: weekdayDate(3, 7, 9, 0),
        category: EntryCategory.laundry,
        description: 'Did two loads of laundry',
        durationMinutes: 30,
        creditsProposed: 1.5,
        creditsConfirmed: 1.5,
        status: EntryStatus.confirmed,
        createdAt: weekdayDate(3, 7, 9, 0),
        updatedAt: weekdayDate(3, 7, 11, 0),
      ),
    );

    // ── Week -2 (2 weeks ago) — all confirmed ──
    for (final weekday in [1, 2, 3, 4, 5]) {
      entries.add(
        CareEntry(
          id: IdGenerator.generate(),
          ledgerId: ledgerId,
          authorId: pAId,
          occurredAt: weekdayDate(2, weekday, 8, 10),
          category: EntryCategory.driving,
          description: 'School pickup and drop-off',
          durationMinutes: 40,
          creditsProposed: 2.0,
          creditsConfirmed: 2.0,
          status: EntryStatus.confirmed,
          createdAt: weekdayDate(2, weekday, 8, 10),
          updatedAt: weekdayDate(2, weekday, 10, 0),
        ),
      );
    }
    for (final weekday in [2, 4, 6]) {
      entries.add(
        CareEntry(
          id: IdGenerator.generate(),
          ledgerId: ledgerId,
          authorId: pAId,
          occurredAt: weekdayDate(2, weekday, 18, 30),
          category: EntryCategory.cooking,
          description: 'Prepared dinner for everyone',
          durationMinutes: 60,
          creditsProposed: 2.5,
          creditsConfirmed: 2.5,
          status: EntryStatus.confirmed,
          createdAt: weekdayDate(2, weekday, 18, 30),
          updatedAt: weekdayDate(2, weekday, 20, 0),
        ),
      );
    }
    entries.add(
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: pBId,
        occurredAt: weekdayDate(2, 6, 10, 30),
        category: EntryCategory.shopping,
        description: 'Weekly grocery shopping',
        durationMinutes: 90,
        creditsProposed: 3.0,
        creditsConfirmed: 3.0,
        status: EntryStatus.confirmed,
        createdAt: weekdayDate(2, 6, 10, 30),
        updatedAt: weekdayDate(2, 6, 12, 0),
      ),
    );
    for (final weekday in [1, 3, 5]) {
      entries.add(
        CareEntry(
          id: IdGenerator.generate(),
          ledgerId: ledgerId,
          authorId: pBId,
          occurredAt: weekdayDate(2, weekday, 15, 45),
          category: EntryCategory.childcare,
          description: 'Picked up kids from sports practice',
          durationMinutes: 30,
          creditsProposed: 1.5,
          creditsConfirmed: 1.5,
          status: EntryStatus.confirmed,
          createdAt: weekdayDate(2, weekday, 15, 45),
          updatedAt: weekdayDate(2, weekday, 17, 0),
        ),
      );
    }
    entries.add(
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: pAId,
        occurredAt: weekdayDate(2, 7, 9, 30),
        category: EntryCategory.laundry,
        description: 'Did two loads of laundry',
        durationMinutes: 30,
        creditsProposed: 1.5,
        creditsConfirmed: 1.5,
        status: EntryStatus.confirmed,
        createdAt: weekdayDate(2, 7, 9, 30),
        updatedAt: weekdayDate(2, 7, 11, 0),
      ),
    );
    // Extra entries for variety
    entries.add(
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: pAId,
        occurredAt: weekdayDate(2, 3, 14, 0),
        category: EntryCategory.emotionalSupport,
        description: 'Helped with homework and bedtime routine',
        durationMinutes: 120,
        creditsProposed: 3.0,
        creditsConfirmed: 3.0,
        status: EntryStatus.confirmed,
        createdAt: weekdayDate(2, 3, 14, 0),
        updatedAt: weekdayDate(2, 3, 16, 0),
      ),
    );
    entries.add(
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: pBId,
        occurredAt: weekdayDate(2, 4, 10, 0),
        category: EntryCategory.medical,
        description: 'Took child to dentist appointment',
        durationMinutes: 90,
        creditsProposed: 2.5,
        creditsConfirmed: 2.5,
        status: EntryStatus.confirmed,
        createdAt: weekdayDate(2, 4, 10, 0),
        updatedAt: weekdayDate(2, 4, 12, 0),
      ),
    );

    // ── Week -1 (last week) — confirmed ──
    for (final weekday in [1, 2, 3, 4, 5]) {
      entries.add(
        CareEntry(
          id: IdGenerator.generate(),
          ledgerId: ledgerId,
          authorId: pAId,
          occurredAt: weekdayDate(1, weekday, 8, 20),
          category: EntryCategory.driving,
          description: 'Drove kids to school and back',
          durationMinutes: 45,
          creditsProposed: 2.0,
          creditsConfirmed: 2.0,
          status: EntryStatus.confirmed,
          createdAt: weekdayDate(1, weekday, 8, 20),
          updatedAt: weekdayDate(1, weekday, 10, 0),
        ),
      );
    }
    for (final weekday in [2, 4, 6]) {
      entries.add(
        CareEntry(
          id: IdGenerator.generate(),
          ledgerId: ledgerId,
          authorId: pAId,
          occurredAt: weekdayDate(1, weekday, 18, 15),
          category: EntryCategory.cooking,
          description: 'Prepared dinner for everyone',
          durationMinutes: 60,
          creditsProposed: 2.5,
          creditsConfirmed: 2.5,
          status: EntryStatus.confirmed,
          createdAt: weekdayDate(1, weekday, 18, 15),
          updatedAt: weekdayDate(1, weekday, 20, 0),
        ),
      );
    }
    entries.add(
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: pBId,
        occurredAt: weekdayDate(1, 6, 10, 15),
        category: EntryCategory.shopping,
        description: 'Weekly grocery shopping',
        durationMinutes: 90,
        creditsProposed: 3.0,
        creditsConfirmed: 3.0,
        status: EntryStatus.confirmed,
        createdAt: weekdayDate(1, 6, 10, 15),
        updatedAt: weekdayDate(1, 6, 12, 0),
      ),
    );
    for (final weekday in [1, 3, 5]) {
      entries.add(
        CareEntry(
          id: IdGenerator.generate(),
          ledgerId: ledgerId,
          authorId: pBId,
          occurredAt: weekdayDate(1, weekday, 15, 30),
          category: EntryCategory.childcare,
          description: 'Picked up kids from sports practice',
          durationMinutes: 30,
          creditsProposed: 1.5,
          creditsConfirmed: 1.5,
          status: EntryStatus.confirmed,
          createdAt: weekdayDate(1, weekday, 15, 30),
          updatedAt: weekdayDate(1, weekday, 17, 0),
        ),
      );
    }
    entries.add(
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: pAId,
        occurredAt: weekdayDate(1, 7, 9, 15),
        category: EntryCategory.laundry,
        description: 'Did two loads of laundry',
        durationMinutes: 30,
        creditsProposed: 1.5,
        creditsConfirmed: 1.5,
        status: EntryStatus.confirmed,
        createdAt: weekdayDate(1, 7, 9, 15),
        updatedAt: weekdayDate(1, 7, 11, 0),
      ),
    );

    // ── This week — mix of statuses ──
    entries.add(
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: pAId,
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
    );
    entries.add(
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: pAId,
        occurredAt: now.subtract(const Duration(days: 2)),
        category: EntryCategory.cooking,
        description: 'Prepared dinner for everyone',
        durationMinutes: 60,
        creditsProposed: 2.5,
        status: EntryStatus.pendingCounterpartyReview,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    );
    entries.add(
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: pBId,
        occurredAt: now.subtract(const Duration(days: 2)),
        category: EntryCategory.childcare,
        description: 'Picked up kids from sports practice',
        durationMinutes: 30,
        creditsProposed: 1.5,
        status: EntryStatus.pendingCounterpartyReview,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    );
    entries.add(
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: pAId,
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
    );
    // Needs edit
    entries.add(
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: pBId,
        occurredAt: now.subtract(const Duration(days: 5)),
        category: EntryCategory.planning,
        description: 'Organized weekend activity schedule',
        creditsProposed: 1.0,
        status: EntryStatus.needsEdit,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 4)),
      ),
    );
    // Rejected
    entries.add(
      CareEntry(
        id: IdGenerator.generate(),
        ledgerId: ledgerId,
        authorId: pAId,
        occurredAt: now.subtract(const Duration(days: 12)),
        category: EntryCategory.housework,
        description: 'General tidying up',
        creditsProposed: 0.5,
        status: EntryStatus.rejected,
        createdAt: now.subtract(const Duration(days: 12)),
        updatedAt: now.subtract(const Duration(days: 11)),
      ),
    );

    for (final entry in entries) {
      await entryRepo.save(entry);
    }

    // Seed a completed settlement
    final settlement = Settlement(
      id: IdGenerator.generate(),
      ledgerId: ledgerId,
      proposerId: pBId,
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
