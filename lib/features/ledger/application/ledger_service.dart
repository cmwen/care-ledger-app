import 'package:care_ledger_app/core/ids.dart';
import 'package:care_ledger_app/features/ledger/domain/ledger.dart';
import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';
import 'package:care_ledger_app/features/ledger/infrastructure/ledger_repository.dart';
import 'package:care_ledger_app/features/ledger/infrastructure/care_entry_repository.dart';
import 'package:care_ledger_app/sync/domain/sync_event.dart';
import 'package:care_ledger_app/sync/application/sync_hasher.dart';
import 'package:care_ledger_app/sync/infrastructure/sync_event_repository.dart';

/// Application service for ledger and care entry operations.
///
/// Enforces domain invariants:
/// - Ledger has exactly two distinct participants.
/// - Archived ledgers are read-only.
/// - creditsProposed >= 0.
///
/// Appends a [SyncEvent] for every write operation when a
/// [SyncEventRepository] is provided.
class LedgerService {
  final LedgerRepository _ledgerRepo;
  final CareEntryRepository _entryRepo;
  final SyncEventRepository? _syncRepo;

  LedgerService({
    required LedgerRepository ledgerRepo,
    required CareEntryRepository entryRepo,
    SyncEventRepository? syncRepo,
  }) : _ledgerRepo = ledgerRepo,
       _entryRepo = entryRepo,
       _syncRepo = syncRepo;

  // ── Ledger operations ──

  /// Create a new shared ledger between two participants.
  Future<Ledger> createLedger({
    required String title,
    required String participantAId,
    required String participantBId,
  }) async {
    if (participantAId == participantBId) {
      throw ArgumentError('Ledger requires two distinct participants');
    }

    final ledger = Ledger(
      id: IdGenerator.generate(),
      title: title,
      participantAId: participantAId,
      participantBId: participantBId,
      createdAt: DateTime.now(),
    );

    await _ledgerRepo.save(ledger);
    return ledger;
  }

  /// Archive a ledger (makes it read-only).
  Future<Ledger> archiveLedger(String ledgerId) async {
    final ledger = await _ledgerRepo.getById(ledgerId);
    if (ledger == null) throw StateError('Ledger not found: $ledgerId');
    if (ledger.isArchived) throw StateError('Ledger already archived');

    final archived = ledger.copyWith(
      status: LedgerStatus.archived,
      archivedAt: DateTime.now(),
    );
    await _ledgerRepo.save(archived);
    return archived;
  }

  /// Get the active ledger (for MVP, there's typically one).
  Future<Ledger?> getActiveLedger() async {
    final active = await _ledgerRepo.getActive();
    return active.isNotEmpty ? active.first : null;
  }

  Future<Ledger?> getLedgerById(String id) => _ledgerRepo.getById(id);

  // ── Care entry operations ──

  /// Propose a new care entry.
  Future<CareEntry> proposeEntry({
    required String ledgerId,
    required String authorId,
    required EntryCategory category,
    required String description,
    required double creditsProposed,
    required DateTime occurredAt,
    int? durationMinutes,
    SourceType sourceType = SourceType.manual,
    String? sourceHint,
  }) async {
    final ledger = await _ledgerRepo.getById(ledgerId);
    if (ledger == null) throw StateError('Ledger not found: $ledgerId');
    if (ledger.isArchived) {
      throw StateError('Cannot add entries to archived ledger');
    }
    if (!ledger.isParticipant(authorId)) {
      throw ArgumentError('$authorId is not a participant in ledger $ledgerId');
    }
    if (creditsProposed < 0) {
      throw ArgumentError('Credits must be non-negative');
    }

    final now = DateTime.now();
    final entry = CareEntry(
      id: IdGenerator.generate(),
      ledgerId: ledgerId,
      authorId: authorId,
      occurredAt: occurredAt,
      category: category,
      description: description,
      durationMinutes: durationMinutes,
      creditsProposed: creditsProposed,
      sourceType: sourceType,
      sourceHint: sourceHint,
      status: EntryStatus.needsReview,
      createdAt: now,
      updatedAt: now,
    );

    await _entryRepo.save(entry);

    // Append sync event for the new entry.
    await _appendSyncEvent(
      ledgerId: ledgerId,
      actorId: authorId,
      entityType: SyncEntityType.careEntry,
      entityId: entry.id,
      opType: SyncEventType.create,
      payload: {
        'category': category.label,
        'description': description,
        'creditsProposed': creditsProposed,
        'occurredAt': occurredAt.toIso8601String(),
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        'sourceType': sourceType.label,
        if (sourceHint != null) 'sourceHint': sourceHint,
      },
    );

    return entry;
  }

  /// Edit a care entry (only allowed in needs_edit or needs_review status).
  Future<CareEntry> editEntry({
    required String entryId,
    EntryCategory? category,
    String? description,
    double? creditsProposed,
    DateTime? occurredAt,
    int? durationMinutes,
  }) async {
    final entry = await _entryRepo.getById(entryId);
    if (entry == null) throw StateError('Entry not found: $entryId');
    if (entry.status != EntryStatus.needsEdit &&
        entry.status != EntryStatus.needsReview) {
      throw StateError(
        'Entry cannot be edited in ${entry.status.label} status',
      );
    }

    final updated = entry.copyWith(
      category: category,
      description: description,
      creditsProposed: creditsProposed,
      occurredAt: occurredAt,
      durationMinutes: durationMinutes,
      revision: entry.revision + 1,
      baseRevision: entry.revision,
      updatedAt: DateTime.now(),
      // After edit, resubmit for review
      status: entry.status == EntryStatus.needsEdit
          ? EntryStatus.pendingCounterpartyReview
          : entry.status,
    );

    await _entryRepo.save(updated);
    return updated;
  }

  /// Get all entries for a ledger.
  Future<List<CareEntry>> getEntries(String ledgerId) =>
      _entryRepo.getByLedgerId(ledgerId);

  /// Get entries in a date range.
  Future<List<CareEntry>> getEntriesInRange(
    String ledgerId,
    DateTime start,
    DateTime end,
  ) => _entryRepo.getByDateRange(ledgerId, start, end);

  /// Delete a care entry.
  Future<void> deleteEntry(String entryId) async {
    final entry = await _entryRepo.getById(entryId);
    if (entry == null) throw StateError('Entry not found: $entryId');
    if (entry.isConfirmed) {
      throw StateError('Cannot delete a confirmed entry');
    }
    await _entryRepo.delete(entryId);
  }

  /// Get the count of entries needing review action.
  Future<int> getPendingReviewCount(String ledgerId) async {
    final queue = await _entryRepo.getReviewQueue(ledgerId);
    return queue.length;
  }

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

    // Get the previous hash for chain linking.
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

    // Compute and set the hash.
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
