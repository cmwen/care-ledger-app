/// Status of a settlement proposal.
enum SettlementStatus {
  proposed('Proposed'),
  accepted('Accepted'),
  rejected('Rejected'),
  completed('Completed'),
  cancelled('Cancelled');

  final String label;
  const SettlementStatus(this.label);

  /// Returns allowed target statuses from this status.
  Set<SettlementStatus> get allowedTransitions {
    switch (this) {
      case SettlementStatus.proposed:
        return {
          SettlementStatus.accepted,
          SettlementStatus.rejected,
          SettlementStatus.cancelled,
        };
      case SettlementStatus.accepted:
        return {SettlementStatus.completed, SettlementStatus.cancelled};
      case SettlementStatus.rejected:
      case SettlementStatus.completed:
      case SettlementStatus.cancelled:
        return {};
    }
  }

  bool canTransitionTo(SettlementStatus target) =>
      allowedTransitions.contains(target);
}

/// Method of settlement.
enum SettlementMethod {
  cash('Cash'),
  bankTransfer('Bank Transfer'),
  reciprocal('Reciprocal Care'),
  other('Other');

  final String label;
  const SettlementMethod(this.label);
}

/// A settlement proposal between two ledger participants.
///
/// Invariants:
/// - Credits are strictly positive.
/// - Accepted settlement can be completed once.
/// - Completion reduces outstanding balance exactly once.
class Settlement {
  final String id;
  final String ledgerId;
  final String proposerId;
  final SettlementMethod method;
  final double credits;
  final SettlementStatus status;
  final String? note;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;

  Settlement({
    required this.id,
    required this.ledgerId,
    required this.proposerId,
    required this.method,
    required this.credits,
    this.status = SettlementStatus.proposed,
    this.note,
    this.dueDate,
    this.completedAt,
    this.revision = 1,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(credits > 0, 'Settlement credits must be positive');

  bool get isOpen =>
      status == SettlementStatus.proposed ||
      status == SettlementStatus.accepted;

  Settlement copyWith({
    String? id,
    String? ledgerId,
    String? proposerId,
    SettlementMethod? method,
    double? credits,
    SettlementStatus? status,
    String? note,
    DateTime? dueDate,
    DateTime? completedAt,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Settlement(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      proposerId: proposerId ?? this.proposerId,
      method: method ?? this.method,
      credits: credits ?? this.credits,
      status: status ?? this.status,
      note: note ?? this.note,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Settlement($id, $credits credits, ${status.label})';
}
