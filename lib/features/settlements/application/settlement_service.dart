import 'package:care_ledger_app/core/ids.dart';
import 'package:care_ledger_app/features/settlements/domain/settlement.dart';
import 'package:care_ledger_app/features/settlements/infrastructure/settlement_repository.dart';
import 'package:care_ledger_app/sync/domain/sync_event.dart';
import 'package:care_ledger_app/sync/application/sync_hasher.dart';
import 'package:care_ledger_app/sync/infrastructure/sync_event_repository.dart';

/// Application service for settlement lifecycle.
///
/// Invariants:
/// - Credits must be positive.
/// - Accepted settlement can be completed once.
/// - Completion reduces outstanding balance exactly once.
///
/// Appends a [SyncEvent] for every mutation when a
/// [SyncEventRepository] is provided.
class SettlementService {
  final SettlementRepository _settlementRepo;
  final SyncEventRepository? _syncRepo;

  SettlementService({
    required SettlementRepository settlementRepo,
    SyncEventRepository? syncRepo,
  }) : _settlementRepo = settlementRepo,
       _syncRepo = syncRepo;

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

    // Append sync event for the new proposal.
    await _appendSyncEvent(
      ledgerId: ledgerId,
      actorId: proposerId,
      entityType: SyncEntityType.settlement,
      entityId: settlement.id,
      opType: SyncEventType.create,
      payload: {
        'method': method.label,
        'credits': credits,
        if (note != null) 'note': note,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
      },
    );

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

    final targetStatus = accept
        ? SettlementStatus.accepted
        : SettlementStatus.rejected;

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

    // Append sync event for the response.
    await _appendSyncEvent(
      ledgerId: settlement.ledgerId,
      actorId: settlement.proposerId, // Track the settlement's context
      entityType: SyncEntityType.settlement,
      entityId: settlementId,
      opType: SyncEventType.update,
      payload: {
        'action': accept ? 'accepted' : 'rejected',
        'revision': updated.revision,
      },
    );

    return updated;
  }

  /// Mark an accepted settlement as completed.
  Future<Settlement> completeSettlement(String settlementId) async {
    final settlement = await _settlementRepo.getById(settlementId);
    if (settlement == null) {
      throw StateError('Settlement not found: $settlementId');
    }

    if (!settlement.status.canTransitionTo(SettlementStatus.completed)) {
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

    if (!settlement.status.canTransitionTo(SettlementStatus.cancelled)) {
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

  // ── Sync helpers ──

  /// Append a sync event if a [SyncEventRepository] is wired.
  Future<void> _appendSyncEvent({
    required String ledgerId,
    required String actorId,
    required SyncEntityType entityType,
    required String entityId,
    required SyncEventType opType,
    required Map<String, dynamic> payload,
  }) async {
    if (_syncRepo == null) return;

    final prevLamport = await _syncRepo.getMaxLamport(ledgerId);
    final lamport = prevLamport + 1;

    final existing = await _syncRepo.getByLedgerId(ledgerId);
    final prevHash = existing.isNotEmpty ? existing.last.hash : null;

    final event = SyncEvent(
      eventId: IdGenerator.generate(),
      ledgerId: ledgerId,
      actorId: actorId,
      entityType: entityType,
      entityId: entityId,
      opType: opType,
      payload: payload,
      lamport: lamport,
      prevHash: prevHash,
      createdAt: DateTime.now(),
    );

    final hash = SyncHasher.computeHash(event);
    final hashedEvent = SyncEvent(
      eventId: event.eventId,
      ledgerId: event.ledgerId,
      actorId: event.actorId,
      deviceId: event.deviceId,
      entityType: event.entityType,
      entityId: event.entityId,
      opType: event.opType,
      payload: event.payload,
      lamport: event.lamport,
      prevHash: event.prevHash,
      hash: hash,
      createdAt: event.createdAt,
    );

    await _syncRepo.append(hashedEvent);
  }
}
