import 'package:flutter/material.dart';

import 'package:care_ledger_app/core/ids.dart';
import 'package:care_ledger_app/features/auto_capture/domain/capture_signal.dart';
import 'package:care_ledger_app/features/auto_capture/domain/capture_rule.dart';
import 'package:care_ledger_app/features/auto_capture/infrastructure/geofence_service.dart';
import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';
import 'package:care_ledger_app/features/ledger/infrastructure/care_entry_repository.dart';

/// Application service for the auto-capture pipeline.
///
/// Analyses entry history to detect recurring patterns and generates
/// draft suggestions for the weekly review.
///
/// Architecture: Signal Sources → Pattern Matching → Draft Suggestions → Weekly Review
///
/// Key invariant: auto-captured entries are **never** auto-confirmed.
/// They always go through the review workflow with
/// [SourceType.suggested] and a non-null [sourceHint].
class AutoCaptureService {
  final CareEntryRepository _entryRepo;
  final GeofenceService _geofenceService;

  final List<CaptureRule> _rules = [];

  AutoCaptureService({
    required CareEntryRepository entryRepo,
    GeofenceService? geofenceService,
  }) : _entryRepo = entryRepo,
       _geofenceService = geofenceService ?? GeofenceService();

  /// User-defined and learned rules (read-only view).
  List<CaptureRule> get rules => List.unmodifiable(_rules);

  /// The pluggable geofence service.
  GeofenceService get geofenceService => _geofenceService;

  // ── Pattern Detection ──

  /// Analyse the last 30 days of confirmed entries to find
  /// recurring patterns on the same weekday at similar times.
  ///
  /// Returns a list of [CaptureRule]s derived from the patterns.
  Future<List<CaptureRule>> detectPatterns({
    required String ledgerId,
    required String authorId,
  }) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final entries = await _entryRepo.getByDateRange(
      ledgerId,
      thirtyDaysAgo,
      now,
    );

    // Only analyse entries by this author that are confirmed or
    // pending (proving the user actually did the activity).
    final authorEntries = entries
        .where(
          (e) =>
              e.authorId == authorId &&
              (e.status == EntryStatus.confirmed ||
                  e.status == EntryStatus.pendingCounterpartyReview),
        )
        .toList();

    // Group by (category, weekday) to detect recurring patterns.
    final groups = <_PatternKey, List<CareEntry>>{};
    for (final entry in authorEntries) {
      final key = _PatternKey(entry.category, entry.occurredAt.weekday);
      groups.putIfAbsent(key, () => []).add(entry);
    }

    final detectedRules = <CaptureRule>[];

    for (final entry in groups.entries) {
      final key = entry.key;
      final matchingEntries = entry.value;

      // Need at least 1 match to create a rule.
      if (matchingEntries.isEmpty) continue;

      // Calculate the average time of day.
      final avgMinutes =
          matchingEntries
              .map((e) => e.occurredAt.hour * 60 + e.occurredAt.minute)
              .reduce((a, b) => a + b) ~/
          matchingEntries.length;

      // Calculate average credits.
      final avgCredits =
          matchingEntries
              .map((e) => e.creditsProposed)
              .reduce((a, b) => a + b) /
          matchingEntries.length;

      // Build a human-readable description from the most common description.
      final descriptionCounts = <String, int>{};
      for (final e in matchingEntries) {
        descriptionCounts[e.description] =
            (descriptionCounts[e.description] ?? 0) + 1;
      }
      final topDescription =
          (descriptionCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;

      final rule = CaptureRule(
        id: IdGenerator.generate(),
        name: topDescription,
        source: SignalSource.timePattern,
        category: key.category,
        defaultCredits: _roundToHalf(avgCredits),
        activeDays: [key.weekday],
        typicalTime: TimeOfDay(hour: avgMinutes ~/ 60, minute: avgMinutes % 60),
        toleranceMinutes: 60,
        matchCount: matchingEntries.length,
        createdAt: DateTime.now(),
      );

      detectedRules.add(rule);
    }

    // Store detected rules (replace prior detections).
    _rules
      ..clear()
      ..addAll(detectedRules);

    return detectedRules;
  }

  // ── Suggestion Generation ──

  /// Generate suggestions for a given week based on detected patterns.
  ///
  /// 1. Loads confirmed/pending entries from the past 4 weeks.
  /// 2. Detects recurring patterns.
  /// 3. Checks which patterns are missing from the target week.
  /// 4. Generates signals for the missing patterns.
  /// 5. Merges in geofence signals.
  ///
  /// Returns signals sorted by confidence (high first).
  Future<List<CaptureSignal>> generateWeeklySuggestions({
    required String ledgerId,
    required String authorId,
    required DateTime weekStart,
  }) async {
    // Detect patterns from history.
    await detectPatterns(ledgerId: ledgerId, authorId: authorId);

    // Load entries that already exist in the target week.
    final weekEnd = weekStart.add(const Duration(days: 7));
    final existingEntries = await _entryRepo.getByDateRange(
      ledgerId,
      weekStart,
      weekEnd,
    );
    final existingByAuthor = existingEntries
        .where((e) => e.authorId == authorId)
        .toList();

    final signals = <CaptureSignal>[];

    for (final rule in _rules) {
      if (!rule.isEnabled) continue;

      for (final weekday in rule.activeDays) {
        // Calculate the target date for this weekday in the given week.
        final daysFromStart = (weekday - weekStart.weekday + 7) % 7;
        final targetDate = weekStart.add(Duration(days: daysFromStart));

        // Skip future dates beyond today.
        final now = DateTime.now();
        if (targetDate.isAfter(now)) continue;

        // Check if a matching entry already exists for this day+category.
        final alreadyExists = existingByAuthor.any(
          (e) =>
              e.category == rule.category &&
              e.occurredAt.weekday == weekday &&
              _isSameDay(e.occurredAt, targetDate),
        );
        if (alreadyExists) continue;

        // Construct the suggested time.
        final suggestedTime = rule.typicalTime != null
            ? DateTime(
                targetDate.year,
                targetDate.month,
                targetDate.day,
                rule.typicalTime!.hour,
                rule.typicalTime!.minute,
              )
            : DateTime(targetDate.year, targetDate.month, targetDate.day, 9, 0);

        final signal = CaptureSignal(
          id: IdGenerator.generate(),
          source: rule.source,
          confidence: rule.confidence,
          description: rule.name,
          suggestedCategory: rule.category,
          suggestedCredits: rule.defaultCredits,
          detectedAt: suggestedTime,
          sourceHint: _buildSourceHint(rule),
          metadata: {'ruleId': rule.id, 'matchCount': rule.matchCount},
        );

        signals.add(signal);
      }
    }

    // Merge geofence signals (empty from stub, but architecture is pluggable).
    final geofenceSignals = await _geofenceService.checkGeofenceTransitions();
    signals.addAll(geofenceSignals);

    // Sort: high confidence first, then by time.
    signals.sort((a, b) {
      final confCompare = a.confidence.index.compareTo(b.confidence.index);
      if (confCompare != 0) return confCompare;
      return a.detectedAt.compareTo(b.detectedAt);
    });

    return signals;
  }

  // ── Draft Entry Conversion ──

  /// Convert signals to draft [CareEntry] objects.
  ///
  /// All generated entries have:
  /// - [SourceType.suggested]
  /// - A non-null [sourceHint]
  /// - [EntryStatus.needsReview]
  List<CareEntry> signalsToDraftEntries({
    required List<CaptureSignal> signals,
    required String ledgerId,
    required String authorId,
  }) {
    final now = DateTime.now();
    return signals
        .map(
          (signal) => CareEntry(
            id: IdGenerator.generate(),
            ledgerId: ledgerId,
            authorId: authorId,
            occurredAt: signal.detectedAt,
            category: signal.suggestedCategory,
            description: signal.description,
            creditsProposed: signal.suggestedCredits,
            sourceType: SourceType.suggested,
            sourceHint: signal.sourceHint,
            status: EntryStatus.needsReview,
            createdAt: now,
            updatedAt: now,
          ),
        )
        .toList();
  }

  // ── Helpers ──

  String _buildSourceHint(CaptureRule rule) {
    final dayNames = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    final days = rule.activeDays.map((d) => dayNames[d] ?? '?').join(', ');
    final timeStr = rule.typicalTime != null
        ? ' around ${rule.typicalTime!.hour.toString().padLeft(2, '0')}:${rule.typicalTime!.minute.toString().padLeft(2, '0')}'
        : '';

    switch (rule.confidence) {
      case SignalConfidence.high:
        return 'You usually do "${rule.name}" on $days$timeStr (${rule.matchCount}× in last 30 days)';
      case SignalConfidence.medium:
        return 'Pattern detected: "${rule.name}" on $days$timeStr (${rule.matchCount}× recently)';
      case SignalConfidence.low:
        return 'Possible pattern: "${rule.name}" on $days$timeStr';
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Round a credit value to the nearest 0.5.
  double _roundToHalf(double value) => (value * 2).round() / 2;
}

/// Internal key for grouping entries by (category, weekday).
class _PatternKey {
  final EntryCategory category;
  final int weekday;

  const _PatternKey(this.category, this.weekday);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PatternKey &&
          category == other.category &&
          weekday == other.weekday;

  @override
  int get hashCode => Object.hash(category, weekday);
}
