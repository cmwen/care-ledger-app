import 'package:flutter/foundation.dart';

import 'package:care_ledger_app/features/auto_capture/domain/capture_signal.dart';
import 'package:care_ledger_app/features/auto_capture/domain/capture_rule.dart';
import 'package:care_ledger_app/features/auto_capture/application/auto_capture_service.dart';
import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';
import 'package:care_ledger_app/features/ledger/infrastructure/care_entry_repository.dart';

/// State for an individual suggestion in the review workflow.
enum SuggestionState { pending, accepted, dismissed }

/// State provider for the auto-capture feature.
///
/// Manages suggestion generation, acceptance, and dismissal.
/// Coordinates with the ledger to create draft entries when
/// suggestions are accepted.
class AutoCaptureProvider extends ChangeNotifier {
  final AutoCaptureService _service;
  final CareEntryRepository _entryRepo;

  List<CaptureSignal> _suggestions = [];
  List<CaptureRule> _detectedPatterns = [];
  bool _isGenerating = false;
  String? _error;

  /// Tracks per-signal state (pending / accepted / dismissed).
  final Map<String, SuggestionState> _signalStates = {};

  AutoCaptureProvider({
    required AutoCaptureService service,
    required CareEntryRepository entryRepo,
  }) : _service = service,
       _entryRepo = entryRepo;

  // ── Getters ──

  List<CaptureSignal> get suggestions => List.unmodifiable(_suggestions);
  List<CaptureRule> get detectedPatterns =>
      List.unmodifiable(_detectedPatterns);
  bool get isGenerating => _isGenerating;
  String? get error => _error;

  /// Suggestions that have not yet been accepted or dismissed.
  List<CaptureSignal> get pending => _suggestions
      .where(
        (s) =>
            _signalStates[s.id] == null ||
            _signalStates[s.id] == SuggestionState.pending,
      )
      .toList();

  /// High-confidence pending suggestions.
  List<CaptureSignal> get highConfidence =>
      pending.where((s) => s.confidence == SignalConfidence.high).toList();

  /// Count of pending suggestions.
  int get pendingSuggestionCount => pending.length;

  /// Whether there are any pending suggestions to show.
  bool get hasPendingSuggestions => pending.isNotEmpty;

  /// Get the state of a specific signal.
  SuggestionState signalState(String signalId) =>
      _signalStates[signalId] ?? SuggestionState.pending;

  // ── Actions ──

  /// Generate this week's suggestions.
  Future<void> generateSuggestions({
    required String ledgerId,
    required String authorId,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      // Calculate the start of the current week (Monday).
      final now = DateTime.now();
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));

      _suggestions = await _service.generateWeeklySuggestions(
        ledgerId: ledgerId,
        authorId: authorId,
        weekStart: weekStart,
      );

      _detectedPatterns = _service.rules;

      // Initialize all new signals as pending.
      for (final signal in _suggestions) {
        _signalStates.putIfAbsent(signal.id, () => SuggestionState.pending);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isGenerating = false;
    notifyListeners();
  }

  /// Accept a suggestion — creates a draft CareEntry.
  ///
  /// The entry is saved with [SourceType.suggested],
  /// [EntryStatus.needsReview], and a non-null [sourceHint].
  Future<void> acceptSuggestion({
    required String signalId,
    required String ledgerId,
    required String authorId,
  }) async {
    final signal = _suggestions.where((s) => s.id == signalId).firstOrNull;
    if (signal == null) return;

    final drafts = _service.signalsToDraftEntries(
      signals: [signal],
      ledgerId: ledgerId,
      authorId: authorId,
    );

    if (drafts.isNotEmpty) {
      await _entryRepo.save(drafts.first);
    }

    _signalStates[signalId] = SuggestionState.accepted;
    notifyListeners();
  }

  /// Dismiss a suggestion (user doesn't want this entry).
  void dismissSuggestion(String signalId) {
    _signalStates[signalId] = SuggestionState.dismissed;
    notifyListeners();
  }

  /// Accept all high-confidence pending suggestions.
  Future<void> acceptAllHighConfidence({
    required String ledgerId,
    required String authorId,
  }) async {
    final toAccept = highConfidence;
    if (toAccept.isEmpty) return;

    final drafts = _service.signalsToDraftEntries(
      signals: toAccept,
      ledgerId: ledgerId,
      authorId: authorId,
    );

    for (final draft in drafts) {
      await _entryRepo.save(draft);
    }

    for (final signal in toAccept) {
      _signalStates[signal.id] = SuggestionState.accepted;
    }
    notifyListeners();
  }

  /// Clear all suggestions and reset state.
  void clearSuggestions() {
    _suggestions = [];
    _signalStates.clear();
    _detectedPatterns = [];
    _error = null;
    notifyListeners();
  }
}
