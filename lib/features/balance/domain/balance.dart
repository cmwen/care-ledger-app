/// Balance summary for a single participant.
class ParticipantBalance {
  final String participantId;
  final double confirmedCredits;
  final double pendingCredits;
  final int confirmedEntryCount;
  final int pendingEntryCount;

  const ParticipantBalance({
    required this.participantId,
    this.confirmedCredits = 0,
    this.pendingCredits = 0,
    this.confirmedEntryCount = 0,
    this.pendingEntryCount = 0,
  });

  double get totalCredits => confirmedCredits + pendingCredits;
}

/// Aggregate balance for a ledger across both participants.
///
/// Net balance is computed from confirmed entries only.
/// Positive net = participant A is owed; negative = participant B is owed.
class LedgerBalance {
  final String ledgerId;
  final ParticipantBalance participantA;
  final ParticipantBalance participantB;
  final double totalSettled;

  const LedgerBalance({
    required this.ledgerId,
    required this.participantA,
    required this.participantB,
    this.totalSettled = 0,
  });

  /// Net balance after settlements.
  /// Positive = A has contributed more (B owes A).
  /// Negative = B has contributed more (A owes B).
  double get netBalance =>
      participantA.confirmedCredits -
      participantB.confirmedCredits -
      totalSettled;

  /// Absolute outstanding balance.
  double get outstandingBalance => netBalance.abs();

  /// The participant who is owed credits.
  String? get creditorId {
    if (netBalance > 0) return participantA.participantId;
    if (netBalance < 0) return participantB.participantId;
    return null; // balanced
  }

  /// The participant who owes credits.
  String? get debtorId {
    if (netBalance > 0) return participantB.participantId;
    if (netBalance < 0) return participantA.participantId;
    return null; // balanced
  }
}
