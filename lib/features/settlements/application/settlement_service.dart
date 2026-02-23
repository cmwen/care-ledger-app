import 'package:care_ledger_app/core/ids.dart';
import 'package:care_ledger_app/features/settlements/domain/settlement.dart';
import 'package:care_ledger_app/features/settlements/infrastructure/settlement_repository.dart';

/// Application service for settlement lifecycle.
///
/// Invariants:
/// - Credits must be positive.
/// - Accepted settlement can be completed once.
/// - Completion reduces outstanding balance exactly once.
class SettlementService {
  final SettlementRepository _settlementRepo;

  SettlementService({required SettlementRepository settlementRepo})
      : _settlementRepo = settlementRepo;

  /// Propose a new settlement.
  Future<Settlement> proposeSettlement({
    required String ledgerId,
    required String proposerId,
    required SettlementMethod method,
    required double credits,
    String? note,
    DateTime? dueDate,
  }) async {
    if (credits <= 0) throw ArgumentError('Credits must be positive');

    final now = DateTime.now();
    final settlement = Settlement(
      id: IdGenerator.generate(),
      ledgerId: ledgerId,
      proposerId: proposerId,
      method: method,
      credits: credits,
      note: note,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
    );

    await _settlementRepo.save(settlement);
    return settlement;
  }

  /// Respond to a settlement proposal (accept or reject).
  Future<Settlement> respondToSettlement({
    required String settlementId,
    required bool accept,
  }) async {
    final settlement = await _settlementRepo.getById(settlementId);
    if (settlement == null) {
      throw StateError('Settlement not found: $settlementId');
    }

    final targetStatus =
        accept ? SettlementStatus.accepted : SettlementStatus.rejected;

    if (!settlement.status.canTransitionTo(targetStatus)) {
      throw StateError(
        'Cannot ${accept ? "accept" : "reject"} settlement in ${settlement.status.label} status',
      );
    }

    final updated = settlement.copyWith(
      status: targetStatus,
      revision: settlement.revision + 1,
      updatedAt: DateTime.now(),
    );

    await _settlementRepo.save(updated);
    return updated;
  }

  /// Mark an accepted settlement as completed.
  Future<Settlement> completeSettlement(String settlementId) async {
    final settlement = await _settlementRepo.getById(settlementId);
    if (settlement == null) {
      throw StateError('Settlement not found: $settlementId');
    }

    if (!settlement.status
        .canTransitionTo(SettlementStatus.completed)) {
      throw StateError(
        'Cannot complete settlement in ${settlement.status.label} status',
      );
    }

    final completed = settlement.copyWith(
      status: SettlementStatus.completed,
      completedAt: DateTime.now(),
      revision: settlement.revision + 1,
      updatedAt: DateTime.now(),
    );

    await _settlementRepo.save(completed);
    return completed;
  }

  /// Cancel a settlement.
  Future<Settlement> cancelSettlement(String settlementId) async {
    final settlement = await _settlementRepo.getById(settlementId);
    if (settlement == null) {
      throw StateError('Settlement not found: $settlementId');
    }

    if (!settlement.status
        .canTransitionTo(SettlementStatus.cancelled)) {
      throw StateError(
        'Cannot cancel settlement in ${settlement.status.label} status',
      );
    }

    final cancelled = settlement.copyWith(
      status: SettlementStatus.cancelled,
      revision: settlement.revision + 1,
      updatedAt: DateTime.now(),
    );

    await _settlementRepo.save(cancelled);
    return cancelled;
  }

  /// Get all settlements for a ledger.
  Future<List<Settlement>> getSettlements(String ledgerId) =>
      _settlementRepo.getByLedgerId(ledgerId);

  /// Get open settlements for a ledger.
  Future<List<Settlement>> getOpenSettlements(String ledgerId) =>
      _settlementRepo.getOpenByLedgerId(ledgerId);
}
