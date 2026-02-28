import 'dart:convert';

import 'package:care_ledger_app/sync/domain/sync_event.dart';

/// Serializes [SyncEvent] lists and [SyncBundle]s to/from JSON.
///
/// Uses only `dart:convert` — no external packages required.
class SyncSerializer {
  /// Serialize a list of [SyncEvent]s to a JSON string.
  static String serialize(List<SyncEvent> events) {
    return jsonEncode(events.map((e) => _eventToMap(e)).toList());
  }

  /// Deserialize a JSON string to a list of [SyncEvent]s.
  static List<SyncEvent> deserialize(String json) {
    final list = jsonDecode(json) as List;
    return list.map((m) => _mapToEvent(m as Map<String, dynamic>)).toList();
  }

  /// Serialize a [SyncBundle] to a compact JSON string with metadata.
  static String serializeBundle(SyncBundle bundle) {
    return jsonEncode({
      'senderId': bundle.senderId,
      'senderName': bundle.senderName,
      'ledgerId': bundle.ledgerId,
      'eventCount': bundle.eventCount,
      'lastLamport': bundle.lastLamport,
      'createdAt': bundle.createdAt.toIso8601String(),
      'events': bundle.events.map((e) => _eventToMap(e)).toList(),
    });
  }

  /// Deserialize a JSON string to a [SyncBundle].
  static SyncBundle deserializeBundle(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    final eventsList = (map['events'] as List)
        .map((m) => _mapToEvent(m as Map<String, dynamic>))
        .toList();
    return SyncBundle(
      senderId: map['senderId'] as String,
      senderName: map['senderName'] as String,
      ledgerId: map['ledgerId'] as String,
      eventCount: map['eventCount'] as int,
      lastLamport: map['lastLamport'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      events: eventsList,
    );
  }

  // ── Private helpers ──

  static Map<String, dynamic> _eventToMap(SyncEvent event) {
    return {
      'eventId': event.eventId,
      'ledgerId': event.ledgerId,
      'actorId': event.actorId,
      if (event.deviceId != null) 'deviceId': event.deviceId,
      'entityType': event.entityType.label,
      'entityId': event.entityId,
      'opType': event.opType.label,
      'payload': event.payload,
      'lamport': event.lamport,
      if (event.prevHash != null) 'prevHash': event.prevHash,
      if (event.hash != null) 'hash': event.hash,
      'createdAt': event.createdAt.toIso8601String(),
    };
  }

  static SyncEvent _mapToEvent(Map<String, dynamic> map) {
    return SyncEvent(
      eventId: map['eventId'] as String,
      ledgerId: map['ledgerId'] as String,
      actorId: map['actorId'] as String,
      deviceId: map['deviceId'] as String?,
      entityType: _parseEntityType(map['entityType'] as String),
      entityId: map['entityId'] as String,
      opType: _parseEventType(map['opType'] as String),
      payload: Map<String, dynamic>.from(map['payload'] as Map),
      lamport: map['lamport'] as int,
      prevHash: map['prevHash'] as String?,
      hash: map['hash'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  static SyncEntityType _parseEntityType(String label) {
    return SyncEntityType.values.firstWhere(
      (e) => e.label == label,
      orElse: () => throw FormatException('Unknown entity type: $label'),
    );
  }

  static SyncEventType _parseEventType(String label) {
    return SyncEventType.values.firstWhere(
      (e) => e.label == label,
      orElse: () => throw FormatException('Unknown event type: $label'),
    );
  }
}

/// A transport bundle containing sync events and metadata.
///
/// Human-readable when serialized to JSON for debugging.
class SyncBundle {
  final String senderId;
  final String senderName;
  final String ledgerId;
  final int eventCount;
  final int lastLamport;
  final DateTime createdAt;
  final List<SyncEvent> events;

  const SyncBundle({
    required this.senderId,
    required this.senderName,
    required this.ledgerId,
    required this.eventCount,
    required this.lastLamport,
    required this.createdAt,
    required this.events,
  });

  @override
  String toString() =>
      'SyncBundle(sender=$senderName, ledger=$ledgerId, '
      'events=$eventCount, lastLamport=$lastLamport)';
}
