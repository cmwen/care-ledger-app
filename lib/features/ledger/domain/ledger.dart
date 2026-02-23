/// Status of a ledger.
enum LedgerStatus {
  active('Active'),
  archived('Archived');

  final String label;
  const LedgerStatus(this.label);
}

/// A shared ledger between two participants.
///
/// Invariants:
/// - Exactly two distinct participants.
/// - Archived ledgers are read-only.
class Ledger {
  final String id;
  final String title;
  final String participantAId;
  final String participantBId;
  final LedgerStatus status;
  final DateTime createdAt;
  final DateTime? archivedAt;

  const Ledger({
    required this.id,
    required this.title,
    required this.participantAId,
    required this.participantBId,
    this.status = LedgerStatus.active,
    required this.createdAt,
    this.archivedAt,
  });

  /// Returns the other participant given one participant's ID.
  String otherParticipant(String participantId) {
    if (participantId == participantAId) return participantBId;
    if (participantId == participantBId) return participantAId;
    throw ArgumentError('$participantId is not a participant in this ledger');
  }

  /// Whether the given ID belongs to a participant.
  bool isParticipant(String participantId) =>
      participantId == participantAId || participantId == participantBId;

  bool get isActive => status == LedgerStatus.active;
  bool get isArchived => status == LedgerStatus.archived;

  Ledger copyWith({
    String? id,
    String? title,
    String? participantAId,
    String? participantBId,
    LedgerStatus? status,
    DateTime? createdAt,
    DateTime? archivedAt,
  }) {
    return Ledger(
      id: id ?? this.id,
      title: title ?? this.title,
      participantAId: participantAId ?? this.participantAId,
      participantBId: participantBId ?? this.participantBId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  @override
  String toString() => 'Ledger($id, $title, $status)';
}
