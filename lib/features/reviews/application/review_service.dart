import 'package:care_ledger_app/core/ids.dart';
import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';
import 'package:care_ledger_app/features/ledger/infrastructure/care_entry_repository.dart';
import 'package:care_ledger_app/features/reviews/domain/entry_review.dart';
import 'package:care_ledger_app/features/reviews/infrastructure/review_repository.dart';

/// Application service for entry review workflow.
///
/// Enforces domain invariants:
/// - Reviewer cannot be the entry author.
/// - needs_edit requires a reason.
/// - Transitions follow the status machine.
class ReviewService {
  final CareEntryRepository _entryRepo;
  final ReviewRepository _reviewRepo;

  ReviewService({
    required CareEntryRepository entryRepo,
    required ReviewRepository reviewRepo,
  })  : _entryRepo = entryRepo,
        _reviewRepo = reviewRepo;

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
      creditsConfirmed:
          decision == ReviewDecision.approved ? entry.creditsProposed : null,
      updatedAt: DateTime.now(),
    );
    await _entryRepo.save(updatedEntry);

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
