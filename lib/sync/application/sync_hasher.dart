import 'dart:convert';

import 'package:care_ledger_app/sync/domain/sync_event.dart';

/// Provides deterministic hashing for [SyncEvent] integrity verification.
///
/// Uses a simple hash function suitable for MVP — no external crypto
/// package required. The hash chain ensures events have not been tampered
/// with or reordered.
class SyncHasher {
  /// Compute a deterministic hash for an event.
  ///
  /// The hash covers: eventId, entityId, opType, lamport, and prevHash.
  static String computeHash(SyncEvent event) {
    final data =
        '${event.eventId}'
        '|${event.entityId}'
        '|${event.opType.label}'
        '|${event.lamport}'
        '|${event.prevHash ?? ""}';
    return _simpleHash(data);
  }

  /// Verify that a list of events forms a valid hash chain.
  ///
  /// Each event's `prevHash` must match the preceding event's `hash`,
  /// and each event's stored `hash` must match the recomputed hash.
  static bool verifyChain(List<SyncEvent> events) {
    if (events.isEmpty) return true;

    for (var i = 0; i < events.length; i++) {
      final event = events[i];

      // Verify the stored hash matches the computed hash.
      if (event.hash != null) {
        final computed = computeHash(event);
        if (computed != event.hash) return false;
      }

      // Verify the chain link (prevHash must match the previous event's hash).
      if (i > 0) {
        final prev = events[i - 1];
        if (event.prevHash != prev.hash) return false;
      }
    }

    return true;
  }

  /// Simple deterministic hash using FNV-1a 64-bit algorithm.
  ///
  /// Produces a 16-character hex string. Not cryptographically secure,
  /// but deterministic and sufficient for integrity checking in the MVP.
  static String _simpleHash(String data) {
    final bytes = utf8.encode(data);

    // FNV-1a constants (64-bit, using Dart's 64-bit int)
    var hash = 0xcbf29ce484222325;
    const prime = 0x100000001b3;

    for (final byte in bytes) {
      hash ^= byte;
      hash = (hash * prime) & 0x7FFFFFFFFFFFFFFF; // Keep within safe int range
    }

    return hash.toRadixString(16).padLeft(16, '0');
  }
}
