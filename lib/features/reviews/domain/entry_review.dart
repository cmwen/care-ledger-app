/// Reviewer's decision on a care entry.
enum ReviewDecision {
  approved('Approved'),
  needsEdit('Needs Edit'),
  rejected('Rejected');

  final String label;
  const ReviewDecision(this.label);
}

/// A review action taken on a care entry.
///
/// Each review is an immutable record of a decision made at a point in time.
/// Multiple reviews can exist for the same entry (e.g., after edits).
class EntryReview {
  final String id;
  final String entryId;
  final String reviewerId;
  final ReviewDecision decision;
  final String? reason;
  final int entryRevisionReviewed;
  final DateTime createdAt;

  const EntryReview({
    required this.id,
    required this.entryId,
    required this.reviewerId,
    required this.decision,
    this.reason,
    required this.entryRevisionReviewed,
    required this.createdAt,
  });

  @override
  String toString() =>
      'EntryReview($id, entry=$entryId, ${decision.label})';
}
