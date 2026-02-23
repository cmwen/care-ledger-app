import 'package:flutter_test/flutter_test.dart';
import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';
import 'package:care_ledger_app/features/ledger/domain/ledger.dart';
import 'package:care_ledger_app/features/balance/domain/balance.dart';
import 'package:care_ledger_app/features/settlements/domain/settlement.dart';

void main() {
  group('EntryStatus transitions', () {
    test('needsReview can transition to pendingCounterpartyReview', () {
      expect(
        EntryStatus.needsReview
            .canTransitionTo(EntryStatus.pendingCounterpartyReview),
        isTrue,
      );
    });

    test('needsReview can transition to rejected', () {
      expect(
        EntryStatus.needsReview.canTransitionTo(EntryStatus.rejected),
        isTrue,
      );
    });

    test('needsReview cannot transition directly to confirmed', () {
      expect(
        EntryStatus.needsReview.canTransitionTo(EntryStatus.confirmed),
        isFalse,
      );
    });

    test('pendingCounterpartyReview can transition to confirmed', () {
      expect(
        EntryStatus.pendingCounterpartyReview
            .canTransitionTo(EntryStatus.confirmed),
        isTrue,
      );
    });

    test('pendingCounterpartyReview can transition to needsEdit', () {
      expect(
        EntryStatus.pendingCounterpartyReview
            .canTransitionTo(EntryStatus.needsEdit),
        isTrue,
      );
    });

    test('needsEdit can transition to pendingCounterpartyReview', () {
      expect(
        EntryStatus.needsEdit
            .canTransitionTo(EntryStatus.pendingCounterpartyReview),
        isTrue,
      );
    });

    test('confirmed can transition to needsEdit (reopen)', () {
      expect(
        EntryStatus.confirmed.canTransitionTo(EntryStatus.needsEdit),
        isTrue,
      );
    });

    test('rejected is terminal', () {
      expect(EntryStatus.rejected.allowedTransitions, isEmpty);
    });
  });

  group('Ledger', () {
    final ledger = Ledger(
      id: 'test-1',
      title: 'Test Ledger',
      participantAId: 'user-a',
      participantBId: 'user-b',
      createdAt: DateTime.now(),
    );

    test('otherParticipant returns correct participant', () {
      expect(ledger.otherParticipant('user-a'), equals('user-b'));
      expect(ledger.otherParticipant('user-b'), equals('user-a'));
    });

    test('otherParticipant throws for unknown participant', () {
      expect(
        () => ledger.otherParticipant('user-c'),
        throwsArgumentError,
      );
    });

    test('isParticipant returns true for valid participants', () {
      expect(ledger.isParticipant('user-a'), isTrue);
      expect(ledger.isParticipant('user-b'), isTrue);
      expect(ledger.isParticipant('user-c'), isFalse);
    });

    test('new ledger is active by default', () {
      expect(ledger.isActive, isTrue);
      expect(ledger.isArchived, isFalse);
    });

    test('copyWith preserves unchanged fields', () {
      final archived = ledger.copyWith(status: LedgerStatus.archived);
      expect(archived.id, equals(ledger.id));
      expect(archived.title, equals(ledger.title));
      expect(archived.isArchived, isTrue);
    });
  });

  group('CareEntry', () {
    test('creditsProposed must be non-negative', () {
      expect(
        () => CareEntry(
          id: 'e-1',
          ledgerId: 'l-1',
          authorId: 'u-1',
          occurredAt: DateTime.now(),
          category: EntryCategory.driving,
          description: 'Test',
          creditsProposed: -1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('isConfirmed returns true only for confirmed status', () {
      final entry = CareEntry(
        id: 'e-1',
        ledgerId: 'l-1',
        authorId: 'u-1',
        occurredAt: DateTime.now(),
        category: EntryCategory.cooking,
        description: 'Test',
        creditsProposed: 1.0,
        status: EntryStatus.confirmed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(entry.isConfirmed, isTrue);
      expect(entry.isPending, isFalse);
    });
  });

  group('LedgerBalance', () {
    test('netBalance is positive when A has more credits', () {
      final balance = LedgerBalance(
        ledgerId: 'l-1',
        participantA: const ParticipantBalance(
          participantId: 'a',
          confirmedCredits: 10.0,
        ),
        participantB: const ParticipantBalance(
          participantId: 'b',
          confirmedCredits: 5.0,
        ),
      );
      expect(balance.netBalance, equals(5.0));
      expect(balance.creditorId, equals('a'));
      expect(balance.debtorId, equals('b'));
    });

    test('netBalance accounts for settlements', () {
      final balance = LedgerBalance(
        ledgerId: 'l-1',
        participantA: const ParticipantBalance(
          participantId: 'a',
          confirmedCredits: 10.0,
        ),
        participantB: const ParticipantBalance(
          participantId: 'b',
          confirmedCredits: 5.0,
        ),
        totalSettled: 3.0,
      );
      expect(balance.netBalance, equals(2.0));
    });

    test('balanced when credits are equal', () {
      final balance = LedgerBalance(
        ledgerId: 'l-1',
        participantA: const ParticipantBalance(
          participantId: 'a',
          confirmedCredits: 5.0,
        ),
        participantB: const ParticipantBalance(
          participantId: 'b',
          confirmedCredits: 5.0,
        ),
      );
      expect(balance.creditorId, isNull);
      expect(balance.debtorId, isNull);
    });
  });

  group('Settlement', () {
    test('credits must be positive', () {
      expect(
        () => Settlement(
          id: 's-1',
          ledgerId: 'l-1',
          proposerId: 'u-1',
          method: SettlementMethod.cash,
          credits: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('proposed can transition to accepted or rejected', () {
      expect(
        SettlementStatus.proposed
            .canTransitionTo(SettlementStatus.accepted),
        isTrue,
      );
      expect(
        SettlementStatus.proposed
            .canTransitionTo(SettlementStatus.rejected),
        isTrue,
      );
    });

    test('completed is terminal', () {
      expect(SettlementStatus.completed.allowedTransitions, isEmpty);
    });
  });
}
