import 'package:care_ledger_app/features/reviews/domain/entry_review.dart';

/// Repository interface for EntryReview persistence.
abstract class ReviewRepository {
  /// Get all reviews for an entry, ordered chronologically.
  Future<List<EntryReview>> getByEntryId(String entryId);

  /// Get all reviews by a specific reviewer.
  Future<List<EntryReview>> getByReviewerId(String reviewerId);

  /// Persist a review record.
  Future<void> save(EntryReview review);
}

/// In-memory implementation for M1 development.
class InMemoryReviewRepository implements ReviewRepository {
  final Map<String, EntryReview> _store = {};

  @override
  Future<List<EntryReview>> getByEntryId(String entryId) async =>
      _store.values.where((r) => r.entryId == entryId).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  @override
  Future<List<EntryReview>> getByReviewerId(String reviewerId) async =>
      _store.values.where((r) => r.reviewerId == reviewerId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<void> save(EntryReview review) async => _store[review.id] = review;
}
