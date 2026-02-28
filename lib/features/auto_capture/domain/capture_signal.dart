import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';

/// Source of an auto-captured signal.
enum SignalSource {
  timePattern('Time Pattern'),
  locationPattern('Location Pattern'),
  calendarEvent('Calendar Event'),
  activityRecognition('Activity Recognition'),
  userTemplate('User Template');

  final String label;
  const SignalSource(this.label);
}

/// Confidence level of a detected signal.
///
/// - [high]: 3+ occurrences on the same weekday
/// - [medium]: 2 occurrences on the same weekday
/// - [low]: 1 occurrence with time match
enum SignalConfidence { high, medium, low }

/// A raw signal from any detection source.
///
/// Represents a detected caregiving activity pattern that can be
/// converted into a draft [CareEntry] for the user to review.
/// Auto-captured entries are **never** auto-confirmed — they always
/// go through the review workflow.
class CaptureSignal {
  final String id;
  final SignalSource source;
  final SignalConfidence confidence;
  final String description;
  final EntryCategory suggestedCategory;
  final double suggestedCredits;
  final DateTime detectedAt;

  /// Human-readable reason WHY this signal was detected.
  final String sourceHint;

  /// Source-specific metadata (e.g., rule ID, location data).
  final Map<String, dynamic> metadata;

  const CaptureSignal({
    required this.id,
    required this.source,
    required this.confidence,
    required this.description,
    required this.suggestedCategory,
    required this.suggestedCredits,
    required this.detectedAt,
    required this.sourceHint,
    this.metadata = const {},
  });

  CaptureSignal copyWith({
    String? id,
    SignalSource? source,
    SignalConfidence? confidence,
    String? description,
    EntryCategory? suggestedCategory,
    double? suggestedCredits,
    DateTime? detectedAt,
    String? sourceHint,
    Map<String, dynamic>? metadata,
  }) {
    return CaptureSignal(
      id: id ?? this.id,
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
      description: description ?? this.description,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      suggestedCredits: suggestedCredits ?? this.suggestedCredits,
      detectedAt: detectedAt ?? this.detectedAt,
      sourceHint: sourceHint ?? this.sourceHint,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() =>
      'CaptureSignal($id, ${source.label}, $confidence, ${suggestedCategory.label})';
}
