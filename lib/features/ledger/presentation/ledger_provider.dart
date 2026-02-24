import 'package:flutter/foundation.dart';
import 'package:care_ledger_app/features/ledger/domain/ledger.dart';
import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';
import 'package:care_ledger_app/features/ledger/application/ledger_service.dart';

/// State provider for the ledger feature.
///
/// Manages the active ledger and its entries.
class LedgerProvider extends ChangeNotifier {
  final LedgerService _service;

  Ledger? _activeLedger;
  List<CareEntry> _entries = [];
  bool _isLoading = false;
  String? _error;

  LedgerProvider({required LedgerService service}) : _service = service;

  // ── Getters ──

  Ledger? get activeLedger => _activeLedger;
  List<CareEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLedger => _activeLedger != null;

  /// Entries for the current week.
  List<CareEntry> get thisWeekEntries {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final end = start.add(const Duration(days: 7));
    return _entries
        .where((e) => !e.occurredAt.isBefore(start) && e.occurredAt.isBefore(end))
        .toList();
  }

  /// Count of entries needing review action.
  int get pendingReviewCount =>
      _entries.where((e) => e.isActionable).length;

  /// Confirmed entries.
  List<CareEntry> get confirmedEntries =>
      _entries.where((e) => e.isConfirmed).toList();

  // ── Actions ──

  /// Load the active ledger and its entries.
  Future<void> loadActiveLedger() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _activeLedger = await _service.getActiveLedger();
      if (_activeLedger != null) {
        _entries = await _service.getEntries(_activeLedger!.id);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Create a new ledger and set it as active.
  Future<void> createLedger({
    required String title,
    required String participantAId,
    required String participantBId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _activeLedger = await _service.createLedger(
        title: title,
        participantAId: participantAId,
        participantBId: participantBId,
      );
      _entries = [];
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new care entry.
  Future<void> addEntry({
    required EntryCategory category,
    String? description,
    required double creditsProposed,
    required DateTime occurredAt,
    required String authorId,
    int? durationMinutes,
    SourceType sourceType = SourceType.manual,
    String? sourceHint,
  }) async {
    if (_activeLedger == null) return;

    try {
      final entry = await _service.proposeEntry(
        ledgerId: _activeLedger!.id,
        authorId: authorId,
        category: category,
        description: description ?? category.label,
        creditsProposed: creditsProposed,
        occurredAt: occurredAt,
        durationMinutes: durationMinutes,
        sourceType: sourceType,
        sourceHint: sourceHint,
      );
      _entries.insert(0, entry);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update an existing care entry.
  Future<void> updateEntry({
    required String entryId,
    EntryCategory? category,
    String? description,
    double? creditsProposed,
    DateTime? occurredAt,
    int? durationMinutes,
  }) async {
    try {
      final updated = await _service.editEntry(
        entryId: entryId,
        category: category,
        description: description,
        creditsProposed: creditsProposed,
        occurredAt: occurredAt,
        durationMinutes: durationMinutes,
      );
      final index = _entries.indexWhere((e) => e.id == entryId);
      if (index >= 0) {
        _entries[index] = updated;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete a care entry.
  Future<void> deleteEntry(String entryId) async {
    try {
      await _service.deleteEntry(entryId);
      _entries.removeWhere((e) => e.id == entryId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Refresh entries from the repository.
  Future<void> refreshEntries() async {
    if (_activeLedger == null) return;

    try {
      _entries = await _service.getEntries(_activeLedger!.id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
