import 'package:flutter/foundation.dart';
import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';
import 'package:care_ledger_app/features/reviews/domain/entry_review.dart';
import 'package:care_ledger_app/features/reviews/application/review_service.dart';

/// State provider for the review feature.
///
/// Manages the weekly review queue and review actions.
class ReviewProvider extends ChangeNotifier {
  final ReviewService _service;

  List<CareEntry> _reviewQueue = [];
  bool _isLoading = false;
  String? _error;

  ReviewProvider({required ReviewService service}) : _service = service;

  // ── Getters ──

  List<CareEntry> get reviewQueue => List.unmodifiable(_reviewQueue);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get queueCount => _reviewQueue.length;

  /// Group review queue by day.
  Map<DateTime, List<CareEntry>> get groupedByDay {
    final map = <DateTime, List<CareEntry>>{};
    for (final entry in _reviewQueue) {
      final day = DateTime(
        entry.occurredAt.year,
        entry.occurredAt.month,
        entry.occurredAt.day,
      );
      map.putIfAbsent(day, () => []).add(entry);
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  /// Group review queue by category.
  Map<EntryCategory, List<CareEntry>> get groupedByCategory {
    final map = <EntryCategory, List<CareEntry>>{};
    for (final entry in _reviewQueue) {
      map.putIfAbsent(entry.category, () => []).add(entry);
    }
    return map;
  }

  // ── Actions ──

  /// Load the review queue for a ledger.
  Future<void> loadReviewQueue(String ledgerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reviewQueue = await _service.getReviewQueue(ledgerId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Approve a single entry.
  Future<void> approveEntry({
    required String entryId,
    required String reviewerId,
  }) async {
    try {
      await _service.reviewEntry(
        entryId: entryId,
        reviewerId: reviewerId,
        decision: ReviewDecision.approved,
      );
      _reviewQueue.removeWhere((e) => e.id == entryId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Reject an entry with reason.
  Future<void> rejectEntry({
    required String entryId,
    required String reviewerId,
    required String reason,
  }) async {
    try {
      await _service.reviewEntry(
        entryId: entryId,
        reviewerId: reviewerId,
        decision: ReviewDecision.rejected,
        reason: reason,
      );
      _reviewQueue.removeWhere((e) => e.id == entryId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Request edits on an entry with reason.
  Future<void> requestEdits({
    required String entryId,
    required String reviewerId,
    required String reason,
  }) async {
    try {
      await _service.reviewEntry(
        entryId: entryId,
        reviewerId: reviewerId,
        decision: ReviewDecision.needsEdit,
        reason: reason,
      );
      _reviewQueue.removeWhere((e) => e.id == entryId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Batch approve selected entries.
  Future<void> batchApprove({
    required List<String> entryIds,
    required String reviewerId,
  }) async {
    try {
      await _service.batchApprove(entryIds: entryIds, reviewerId: reviewerId);
      _reviewQueue.removeWhere((e) => entryIds.contains(e.id));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Batch reject selected entries.
  Future<void> batchReject({
    required List<String> entryIds,
    required String reviewerId,
    required String reason,
  }) async {
    try {
      await _service.batchReject(
        entryIds: entryIds,
        reviewerId: reviewerId,
        reason: reason,
      );
      _reviewQueue.removeWhere((e) => entryIds.contains(e.id));
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
