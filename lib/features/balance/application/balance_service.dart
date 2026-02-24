import 'package:care_ledger_app/features/balance/domain/balance.dart';
import 'package:care_ledger_app/features/ledger/domain/ledger.dart';
import 'package:care_ledger_app/features/ledger/infrastructure/care_entry_repository.dart';
import 'package:care_ledger_app/features/settlements/infrastructure/settlement_repository.dart';

/// Application service for balance computation.
///
/// Balance is always recomputed from entries, never stored directly.
/// Only confirmed entries affect confirmed balance.
class BalanceService {
  final CareEntryRepository _entryRepo;
  final SettlementRepository _settlementRepo;

  BalanceService({
    required CareEntryRepository entryRepo,
    required SettlementRepository settlementRepo,
  }) : _entryRepo = entryRepo,
       _settlementRepo = settlementRepo;

  /// Compute the full balance for a ledger.
  Future<LedgerBalance> calculateBalance(Ledger ledger) async {
    final entries = await _entryRepo.getByLedgerId(ledger.id);
    final settlements = await _settlementRepo.getCompletedByLedgerId(ledger.id);

    // Compute per-participant balances
    double aConfirmed = 0, aPending = 0;
    double bConfirmed = 0, bPending = 0;
    int aConfirmedCount = 0, aPendingCount = 0;
    int bConfirmedCount = 0, bPendingCount = 0;

    for (final entry in entries) {
      if (entry.authorId == ledger.participantAId) {
        if (entry.isConfirmed) {
          aConfirmed += entry.creditsConfirmed ?? entry.creditsProposed;
          aConfirmedCount++;
        } else if (entry.isPending) {
          aPending += entry.creditsProposed;
          aPendingCount++;
        }
      } else if (entry.authorId == ledger.participantBId) {
        if (entry.isConfirmed) {
          bConfirmed += entry.creditsConfirmed ?? entry.creditsProposed;
          bConfirmedCount++;
        } else if (entry.isPending) {
          bPending += entry.creditsProposed;
          bPendingCount++;
        }
      }
    }

    // Sum completed settlements
    double totalSettled = 0;
    for (final settlement in settlements) {
      totalSettled += settlement.credits;
    }

    return LedgerBalance(
      ledgerId: ledger.id,
      participantA: ParticipantBalance(
        participantId: ledger.participantAId,
        confirmedCredits: aConfirmed,
        pendingCredits: aPending,
        confirmedEntryCount: aConfirmedCount,
        pendingEntryCount: aPendingCount,
      ),
      participantB: ParticipantBalance(
        participantId: ledger.participantBId,
        confirmedCredits: bConfirmed,
        pendingCredits: bPending,
        confirmedEntryCount: bConfirmedCount,
        pendingEntryCount: bPendingCount,
      ),
      totalSettled: totalSettled,
    );
  }
}
