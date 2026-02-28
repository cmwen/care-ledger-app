import 'package:care_ledger_app/sync/domain/sync_event.dart';

/// Deterministic merge of local and remote sync event logs.
///
/// Canonical ordering:
/// 1. `lamport` ascending
/// 2. `actorId` lexical ascending (tie-break)
/// 3. `createdAt` ascending (further tie-break)
class SyncMerger {
  /// Merge remote events into the local event log.
  ///
  /// Returns only the events that were **new** (not already present locally).
  /// Both local and remote lists are expected to be in canonical order.
  static List<SyncEvent> merge({
    required List<SyncEvent> localEvents,
    required List<SyncEvent> remoteEvents,
  }) {
    final localIds = localEvents.map((e) => e.eventId).toSet();

    // Identify genuinely new events (not already in local log).
    final newEvents = remoteEvents
        .where((e) => !localIds.contains(e.eventId))
        .toList();

    // Sort new events into canonical order.
    newEvents.sort(_canonicalCompare);

    return newEvents;
  }

  /// Detect conflicts: concurrent mutations to the same entity from
  /// different actors at the same or adjacent lamport clocks.
  ///
  /// A conflict is flagged when both local and remote contain events
  /// targeting the same `entityId` from different `actorId`s and
  /// their lamport clocks differ by at most 1 (truly concurrent).
  static List<SyncConflict> detectConflicts({
    required List<SyncEvent> localEvents,
    required List<SyncEvent> remoteEvents,
  }) {
    final conflicts = <SyncConflict>[];

    // Build an index of local events by entityId.
    final localByEntity = <String, List<SyncEvent>>{};
    for (final e in localEvents) {
      localByEntity.putIfAbsent(e.entityId, () => []).add(e);
    }

    for (final remote in remoteEvents) {
      final locals = localByEntity[remote.entityId];
      if (locals == null) continue;

      for (final local in locals) {
        // Only flag if different actors mutated the same entity concurrently.
        if (local.actorId == remote.actorId) continue;
        if (local.eventId == remote.eventId) continue;

        final lamportDiff = (local.lamport - remote.lamport).abs();
        if (lamportDiff <= 1) {
          conflicts.add(
            SyncConflict(
              localEvent: local,
              remoteEvent: remote,
              entityId: remote.entityId,
              resolution: _resolveConflict(local, remote),
            ),
          );
        }
      }
    }

    return conflicts;
  }

  /// Canonical comparison for deterministic ordering.
  static int _canonicalCompare(SyncEvent a, SyncEvent b) {
    // Primary: lamport ascending
    final lamportCmp = a.lamport.compareTo(b.lamport);
    if (lamportCmp != 0) return lamportCmp;

    // Secondary: actorId lexical ascending
    final actorCmp = a.actorId.compareTo(b.actorId);
    if (actorCmp != 0) return actorCmp;

    // Tertiary: createdAt ascending
    return a.createdAt.compareTo(b.createdAt);
  }

  /// Determine a resolution strategy for a conflict.
  ///
  /// For MVP, the actor with the lexically-smaller actorId wins
  /// (deterministic last-writer-wins). Complex conflicts are flagged
  /// for review.
  static String _resolveConflict(SyncEvent local, SyncEvent remote) {
    // If both are different op types (e.g., update vs delete),
    // flag for manual review.
    if (local.opType != remote.opType) return 'needs_review';

    // Deterministic: lower actorId wins.
    if (local.actorId.compareTo(remote.actorId) < 0) {
      return 'local_wins';
    } else {
      return 'remote_wins';
    }
  }
}

/// Represents a detected conflict between local and remote events.
class SyncConflict {
  final SyncEvent localEvent;
  final SyncEvent remoteEvent;
  final String entityId;

  /// Resolution strategy: `'local_wins'`, `'remote_wins'`, or `'needs_review'`.
  final String resolution;

  const SyncConflict({
    required this.localEvent,
    required this.remoteEvent,
    required this.entityId,
    required this.resolution,
  });

  @override
  String toString() => 'SyncConflict(entity=$entityId, resolution=$resolution)';
}
