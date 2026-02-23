/// Category of care activity.
enum EntryCategory {
  driving('Driving'),
  laundry('Laundry'),
  childcare('Childcare'),
  cooking('Cooking'),
  shopping('Shopping'),
  planning('Planning'),
  emotionalSupport('Emotional Support'),
  housework('Housework'),
  medical('Medical'),
  other('Other');

  final String label;
  const EntryCategory(this.label);
}

/// How the entry was created.
enum SourceType {
  manual('Manual'),
  suggested('Auto-suggested'),
  template('From template'),
  calendar('Calendar-linked');

  final String label;
  const SourceType(this.label);
}

/// Status of a care entry in the review workflow.
///
/// Transition rules (from tech design):
/// - needs_review -> pending_counterparty_review (author approves)
/// - needs_review -> rejected
/// - pending_counterparty_review -> confirmed | needs_edit | rejected
/// - needs_edit -> pending_counterparty_review (author resubmits)
/// - confirmed -> needs_edit (within bounded window, with reason)
enum EntryStatus {
  needsReview('Needs Review'),
  pendingCounterpartyReview('Pending Review'),
  confirmed('Confirmed'),
  needsEdit('Needs Edit'),
  rejected('Rejected');

  final String label;
  const EntryStatus(this.label);

  /// Returns the set of statuses this status can transition to.
  Set<EntryStatus> get allowedTransitions {
    switch (this) {
      case EntryStatus.needsReview:
        return {EntryStatus.pendingCounterpartyReview, EntryStatus.rejected};
      case EntryStatus.pendingCounterpartyReview:
        return {
          EntryStatus.confirmed,
          EntryStatus.needsEdit,
          EntryStatus.rejected,
        };
      case EntryStatus.needsEdit:
        return {EntryStatus.pendingCounterpartyReview};
      case EntryStatus.confirmed:
        return {EntryStatus.needsEdit}; // reopenable within window
      case EntryStatus.rejected:
        return {};
    }
  }

  /// Whether this status can transition to the target status.
  bool canTransitionTo(EntryStatus target) =>
      allowedTransitions.contains(target);
}

/// A single care effort record in the ledger.
///
/// Invariants:
/// - creditsProposed >= 0
/// - Reviewer cannot be the entry author for confirm/reject decisions
/// - Only confirmed entries affect confirmed balance
class CareEntry {
  final String id;
  final String ledgerId;
  final String authorId;
  final DateTime occurredAt;
  final EntryCategory category;
  final String description;
  final int? durationMinutes;
  final double creditsProposed;
  final double? creditsConfirmed;
  final SourceType sourceType;
  final String? sourceHint;
  final EntryStatus status;
  final int revision;
  final int? baseRevision;
  final DateTime createdAt;
  final DateTime updatedAt;

  CareEntry({
    required this.id,
    required this.ledgerId,
    required this.authorId,
    required this.occurredAt,
    required this.category,
    required this.description,
    this.durationMinutes,
    required this.creditsProposed,
    this.creditsConfirmed,
    this.sourceType = SourceType.manual,
    this.sourceHint,
    this.status = EntryStatus.needsReview,
    this.revision = 1,
    this.baseRevision,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(creditsProposed >= 0, 'creditsProposed must be non-negative');

  bool get isConfirmed => status == EntryStatus.confirmed;

  bool get isPending =>
      status != EntryStatus.confirmed && status != EntryStatus.rejected;

  bool get isActionable =>
      status == EntryStatus.needsReview ||
      status == EntryStatus.pendingCounterpartyReview ||
      status == EntryStatus.needsEdit;

  CareEntry copyWith({
    String? id,
    String? ledgerId,
    String? authorId,
    DateTime? occurredAt,
    EntryCategory? category,
    String? description,
    int? durationMinutes,
    double? creditsProposed,
    double? creditsConfirmed,
    SourceType? sourceType,
    String? sourceHint,
    EntryStatus? status,
    int? revision,
    int? baseRevision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CareEntry(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      authorId: authorId ?? this.authorId,
      occurredAt: occurredAt ?? this.occurredAt,
      category: category ?? this.category,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      creditsProposed: creditsProposed ?? this.creditsProposed,
      creditsConfirmed: creditsConfirmed ?? this.creditsConfirmed,
      sourceType: sourceType ?? this.sourceType,
      sourceHint: sourceHint ?? this.sourceHint,
      status: status ?? this.status,
      revision: revision ?? this.revision,
      baseRevision: baseRevision ?? this.baseRevision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'CareEntry($id, ${category.label}, $status, credits=$creditsProposed)';
}
