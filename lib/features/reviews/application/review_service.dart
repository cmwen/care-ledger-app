import 'package:care_ledger_app/core/ids.dart';
import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';
import 'package:care_ledger_app/features/ledger/infrastructure/care_entry_repository.dart';
import 'package:care_ledger_app/features/reviews/domain/entry_review.dart';
import 'package:care_ledger_app/features/reviews/infrastructure/review_repository.dart';
import 'package:care_ledger_app/sync/domain/sync_event.dart';
import 'package:care_ledger_app/sync/application/sync_hasher.dart';
import 'package:care_ledger_app/sync/infrastructure/sync_event_repository.dart';

/// Application service for entry review workflow.
///
/// Enforces domain invariants:
/// - Reviewer cannot be the entry author.
/// - needs_edit requires a reason.
/// - Transitions follow the status machine.
///
/// Appends a [SyncEvent] for every review when a
/// [SyncEventRepository] is provided.
class ReviewService {
  final CareEntryRepository _entryRepo;
  final ReviewRepository _reviewRepo;
  final SyncEventRepository? _syncRepo;

  ReviewService({
    required CareEntryRepository entryRepo,
    required ReviewRepository reviewRepo,
    SyncEventRepository? syncRepo,
  }) : _entryRepo = entryRepo,
       _reviewRepo = reviewRepo,
       _syncRepo = syncRepo;

  /// Get the review queue for a ledger (entries needing action).
  Future<List<CareEntry>> getReviewQueue(String ledgerId) =>
      _entryRepo.getReviewQueue(ledgerId);

  /// Submit a review decision for an entry.
  ///
  /// Applies the status transition and records the review.
  Future<EntryReview> reviewEntry({
    required String entryId,
    required String reviewerId,
    required ReviewDecision decision,
    String? reason,
  }) async {
    final entry = await _entryRepo.getById(entryId);
    if (entry == null) throw StateError('Entry not found: $entryId');

    // Reviewer cannot be the author
    if (reviewerId == entry.authorId) {
      throw ArgumentError('Reviewer cannot be the entry author');
    }

    // Determine target status
    final targetStatus = _mapDecisionToStatus(decision, entry.status);

    // Validate transition
    if (!entry.status.canTransitionTo(targetStatus)) {
      throw StateError(
        'Cannot transition from ${entry.status.label} to ${targetStatus.label}',
      );
    }

    // needs_edit requires a reason
    if (decision == ReviewDecision.needsEdit &&
        (reason == null || reason.trim().isEmpty)) {
      throw ArgumentError('A reason is required when requesting edits');
    }

    // Record the review
    final review = EntryReview(
      id: IdGenerator.generate(),
      entryId: entryId,
      reviewerId: reviewerId,
      decision: decision,
      reason: reason,
      entryRevisionReviewed: entry.revision,
      createdAt: DateTime.now(),
    );
    await _reviewRepo.save(review);

    // Update entry status
    final updatedEntry = entry.copyWith(
      status: targetStatus,
      creditsConfirmed: decision == ReviewDecision.approved
          ? entry.creditsProposed
          : null,
      updatedAt: DateTime.now(),
    );
    await _entryRepo.save(updatedEntry);

    // Append sync event for the review action.
    await _appendSyncEvent(
      ledgerId: entry.ledgerId,
      actorId: reviewerId,
      entityType: SyncEntityType.entryReview,
      entityId: review.id,
      opType: SyncEventType.create,
      payload: {
        'entryId': entryId,
        'decision': decision.label,
        if (reason != null) 'reason': reason,
        'entryRevisionReviewed': entry.revision,
      },
    );

    return review;
  }

  /// Author approves their own entry to send for counterparty review.
  Future<CareEntry> submitForReview(String entryId) async {
    final entry = await _entryRepo.getById(entryId);
    if (entry == null) throw StateError('Entry not found: $entryId');
    if (entry.status != EntryStatus.needsReview) {
      throw StateError('Entry must be in needs_review status');
    }

    final updated = entry.copyWith(
      status: EntryStatus.pendingCounterpartyReview,
      updatedAt: DateTime.now(),
    );
    await _entryRepo.save(updated);
    return updated;
  }

  /// Batch approve multiple entries.
  Future<List<EntryReview>> batchApprove({
    required List<String> entryIds,
    required String reviewerId,
  }) async {
    final reviews = <EntryReview>[];
    for (final id in entryIds) {
      final review = await reviewEntry(
        entryId: id,
        reviewerId: reviewerId,
        decision: ReviewDecision.approved,
      );
      reviews.add(review);
    }
    return reviews;
  }

  /// Batch reject multiple entries.
  Future<List<EntryReview>> batchReject({
    required List<String> entryIds,
    required String reviewerId,
    required String reason,
  }) async {
    final reviews = <EntryReview>[];
    for (final id in entryIds) {
      final review = await reviewEntry(
        entryId: id,
        reviewerId: reviewerId,
        decision: ReviewDecision.rejected,
        reason: reason,
      );
      reviews.add(review);
    }
    return reviews;
  }

  /// Get the review history for a specific entry.
  Future<List<EntryReview>> getEntryHistory(String entryId) =>
      _reviewRepo.getByEntryId(entryId);

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

  EntryStatus _mapDecisionToStatus(
    ReviewDecision decision,
    EntryStatus currentStatus,
  ) {
    switch (decision) {
      case ReviewDecision.approved:
        return EntryStatus.confirmed;
      case ReviewDecision.needsEdit:
        return EntryStatus.needsEdit;
      case ReviewDecision.rejected:
        return EntryStatus.rejected;
    }
  }
}
