import 'package:flutter/material.dart';

import 'package:care_ledger_app/features/auto_capture/domain/capture_signal.dart';
import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';

/// A user-defined or learned pattern rule.
///
/// Rules encode recurring activity patterns (e.g., "Driving every
/// weekday morning at 8:00 AM"). The auto-capture service uses
/// these to generate draft suggestions for the weekly review.
class CaptureRule {
  final String id;
  final String name;
  final SignalSource source;
  final EntryCategory category;
  final double defaultCredits;

  /// Active days of the week. 1 = Monday, 7 = Sunday (ISO 8601).
  final List<int> activeDays;

  /// The typical time of day this activity occurs.
  final TimeOfDay? typicalTime;

  /// Tolerance window (in minutes) around [typicalTime].
  final int? toleranceMinutes;

  /// Whether this rule is currently active.
  final bool isEnabled;

  /// How many times this rule has matched historical entries.
  final int matchCount;

  final DateTime createdAt;

  const CaptureRule({
    required this.id,
    required this.name,
    required this.source,
    required this.category,
    required this.defaultCredits,
    required this.activeDays,
    this.typicalTime,
    this.toleranceMinutes,
    this.isEnabled = true,
    this.matchCount = 0,
    required this.createdAt,
  });

  /// Confidence level derived from how many matches the rule has.
  SignalConfidence get confidence {
    if (matchCount >= 3) return SignalConfidence.high;
    if (matchCount >= 2) return SignalConfidence.medium;
    return SignalConfidence.low;
  }

  CaptureRule copyWith({
    String? id,
    String? name,
    SignalSource? source,
    EntryCategory? category,
    double? defaultCredits,
    List<int>? activeDays,
    TimeOfDay? typicalTime,
    int? toleranceMinutes,
    bool? isEnabled,
    int? matchCount,
    DateTime? createdAt,
  }) {
    return CaptureRule(
      id: id ?? this.id,
      name: name ?? this.name,
      source: source ?? this.source,
      category: category ?? this.category,
      defaultCredits: defaultCredits ?? this.defaultCredits,
      activeDays: activeDays ?? this.activeDays,
      typicalTime: typicalTime ?? this.typicalTime,
      toleranceMinutes: toleranceMinutes ?? this.toleranceMinutes,
      isEnabled: isEnabled ?? this.isEnabled,
      matchCount: matchCount ?? this.matchCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'CaptureRule($id, $name, ${category.label}, days=$activeDays, matches=$matchCount)';
}
