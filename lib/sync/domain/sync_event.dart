/// Type of mutation in a sync event.
enum SyncEventType {
  create('Create'),
  update('Update'),
  delete('Delete');

  final String label;
  const SyncEventType(this.label);
}

/// Entity type affected by a sync event.
enum SyncEntityType {
  ledger('Ledger'),
  careEntry('CareEntry'),
  entryReview('EntryReview'),
  settlement('Settlement');

  final String label;
  const SyncEntityType(this.label);
}

/// An immutable record of a mutation for sync and audit.
///
/// Supports append-only event log with deterministic merge.
/// All write operations append a SyncEvent alongside projection updates.
class SyncEvent {
  final String eventId;
  final String ledgerId;
  final String actorId;
  final String? deviceId;
  final SyncEntityType entityType;
  final String entityId;
  final SyncEventType opType;
  final Map<String, dynamic> payload;
  final int lamport;
  final String? prevHash;
  final String? hash;
  final DateTime createdAt;

  const SyncEvent({
    required this.eventId,
    required this.ledgerId,
    required this.actorId,
    this.deviceId,
    required this.entityType,
    required this.entityId,
    required this.opType,
    required this.payload,
    this.lamport = 0,
    this.prevHash,
    this.hash,
    required this.createdAt,
  });

  @override
  String toString() =>
      'SyncEvent($eventId, ${entityType.label}.${opType.label}, entity=$entityId)';
}
