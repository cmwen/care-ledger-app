import 'package:flutter_test/flutter_test.dart';

import 'package:care_ledger_app/sync/domain/sync_event.dart';
import 'package:care_ledger_app/sync/application/sync_serializer.dart';
import 'package:care_ledger_app/sync/application/sync_hasher.dart';
import 'package:care_ledger_app/sync/application/sync_merger.dart';
import 'package:care_ledger_app/sync/infrastructure/sync_event_repository.dart';
import 'package:care_ledger_app/sync/infrastructure/export_sync_service.dart';

void main() {
  // ── Helpers ──

  SyncEvent makeEvent({
    String? eventId,
    String ledgerId = 'ledger-1',
    String actorId = 'actor-a',
    SyncEntityType entityType = SyncEntityType.careEntry,
    String entityId = 'entity-1',
    SyncEventType opType = SyncEventType.create,
    Map<String, dynamic> payload = const {'key': 'value'},
    int lamport = 1,
    String? prevHash,
    String? hash,
    DateTime? createdAt,
  }) {
    return SyncEvent(
      eventId: eventId ?? 'evt-$lamport-$actorId',
      ledgerId: ledgerId,
      actorId: actorId,
      entityType: entityType,
      entityId: entityId,
      opType: opType,
      payload: payload,
      lamport: lamport,
      prevHash: prevHash,
      hash: hash,
      createdAt: createdAt ?? DateTime(2024, 1, 1, 0, 0, lamport),
    );
  }

  // ── SyncSerializer tests ──

  group('SyncSerializer', () {
    test('round-trips a list of events', () {
      final events = [
        makeEvent(eventId: 'e1', lamport: 1),
        makeEvent(eventId: 'e2', lamport: 2, actorId: 'actor-b'),
      ];

      final json = SyncSerializer.serialize(events);
      final restored = SyncSerializer.deserialize(json);

      expect(restored.length, 2);
      expect(restored[0].eventId, 'e1');
      expect(restored[1].eventId, 'e2');
      expect(restored[1].actorId, 'actor-b');
    });

    test('round-trips a SyncBundle', () {
      final events = [
        makeEvent(eventId: 'e1', lamport: 1),
        makeEvent(eventId: 'e2', lamport: 2),
      ];
      final bundle = SyncBundle(
        senderId: 'sender-1',
        senderName: 'Alice',
        ledgerId: 'ledger-1',
        eventCount: 2,
        lastLamport: 2,
        createdAt: DateTime(2024, 6, 15),
        events: events,
      );

      final json = SyncSerializer.serializeBundle(bundle);
      final restored = SyncSerializer.deserializeBundle(json);

      expect(restored.senderId, 'sender-1');
      expect(restored.senderName, 'Alice');
      expect(restored.ledgerId, 'ledger-1');
      expect(restored.eventCount, 2);
      expect(restored.lastLamport, 2);
      expect(restored.events.length, 2);
      expect(restored.events[0].eventId, 'e1');
    });

    test('preserves all SyncEvent fields through serialization', () {
      final event = SyncEvent(
        eventId: 'test-evt',
        ledgerId: 'led-1',
        actorId: 'actor-x',
        deviceId: 'device-99',
        entityType: SyncEntityType.settlement,
        entityId: 'settle-1',
        opType: SyncEventType.update,
        payload: {'credits': 5.0, 'note': 'test'},
        lamport: 42,
        prevHash: 'abc123',
        hash: 'def456',
        createdAt: DateTime(2024, 3, 14, 9, 30),
      );

      final json = SyncSerializer.serialize([event]);
      final restored = SyncSerializer.deserialize(json).first;

      expect(restored.eventId, 'test-evt');
      expect(restored.ledgerId, 'led-1');
      expect(restored.actorId, 'actor-x');
      expect(restored.deviceId, 'device-99');
      expect(restored.entityType, SyncEntityType.settlement);
      expect(restored.entityId, 'settle-1');
      expect(restored.opType, SyncEventType.update);
      expect(restored.payload['credits'], 5.0);
      expect(restored.payload['note'], 'test');
      expect(restored.lamport, 42);
      expect(restored.prevHash, 'abc123');
      expect(restored.hash, 'def456');
    });

    test('handles empty event list', () {
      final json = SyncSerializer.serialize([]);
      final restored = SyncSerializer.deserialize(json);
      expect(restored, isEmpty);
    });

    test('handles empty bundle', () {
      final bundle = SyncBundle(
        senderId: 'x',
        senderName: 'X',
        ledgerId: 'l',
        eventCount: 0,
        lastLamport: 0,
        createdAt: DateTime.now(),
        events: [],
      );
      final json = SyncSerializer.serializeBundle(bundle);
      final restored = SyncSerializer.deserializeBundle(json);
      expect(restored.events, isEmpty);
      expect(restored.eventCount, 0);
    });
  });

  // ── SyncHasher tests ──

  group('SyncHasher', () {
    test('computeHash is deterministic', () {
      final event = makeEvent(eventId: 'e1', lamport: 1);
      final hash1 = SyncHasher.computeHash(event);
      final hash2 = SyncHasher.computeHash(event);
      expect(hash1, hash2);
    });

    test('different events produce different hashes', () {
      final e1 = makeEvent(eventId: 'e1', lamport: 1);
      final e2 = makeEvent(eventId: 'e2', lamport: 2);
      expect(SyncHasher.computeHash(e1), isNot(SyncHasher.computeHash(e2)));
    });

    test('hash changes when prevHash changes', () {
      final e1 = makeEvent(eventId: 'e1', prevHash: null);
      final e2 = makeEvent(eventId: 'e1', prevHash: 'somehash');
      expect(SyncHasher.computeHash(e1), isNot(SyncHasher.computeHash(e2)));
    });

    test('verifyChain passes for valid chain', () {
      final e1 = makeEvent(eventId: 'e1', lamport: 1);
      final h1 = SyncHasher.computeHash(e1);
      final hashed1 = SyncEvent(
        eventId: e1.eventId,
        ledgerId: e1.ledgerId,
        actorId: e1.actorId,
        entityType: e1.entityType,
        entityId: e1.entityId,
        opType: e1.opType,
        payload: e1.payload,
        lamport: e1.lamport,
        prevHash: null,
        hash: h1,
        createdAt: e1.createdAt,
      );

      final e2 = makeEvent(eventId: 'e2', lamport: 2, prevHash: h1);
      final h2 = SyncHasher.computeHash(e2);
      final hashed2 = SyncEvent(
        eventId: e2.eventId,
        ledgerId: e2.ledgerId,
        actorId: e2.actorId,
        entityType: e2.entityType,
        entityId: e2.entityId,
        opType: e2.opType,
        payload: e2.payload,
        lamport: e2.lamport,
        prevHash: e2.prevHash,
        hash: h2,
        createdAt: e2.createdAt,
      );

      expect(SyncHasher.verifyChain([hashed1, hashed2]), isTrue);
    });

    test('verifyChain fails for tampered hash', () {
      final e1 = makeEvent(eventId: 'e1', lamport: 1);
      final hashed1 = SyncEvent(
        eventId: e1.eventId,
        ledgerId: e1.ledgerId,
        actorId: e1.actorId,
        entityType: e1.entityType,
        entityId: e1.entityId,
        opType: e1.opType,
        payload: e1.payload,
        lamport: e1.lamport,
        prevHash: null,
        hash: 'tampered-hash',
        createdAt: e1.createdAt,
      );

      expect(SyncHasher.verifyChain([hashed1]), isFalse);
    });

    test('verifyChain passes for empty list', () {
      expect(SyncHasher.verifyChain([]), isTrue);
    });
  });

  // ── SyncMerger tests ──

  group('SyncMerger', () {
    test('merge deduplicates by eventId', () {
      final shared = makeEvent(eventId: 'shared', lamport: 1);
      final remoteOnly = makeEvent(eventId: 'remote-1', lamport: 2);

      final newEvents = SyncMerger.merge(
        localEvents: [shared],
        remoteEvents: [shared, remoteOnly],
      );

      expect(newEvents.length, 1);
      expect(newEvents[0].eventId, 'remote-1');
    });

    test('merge returns empty when no new events', () {
      final events = [
        makeEvent(eventId: 'e1', lamport: 1),
        makeEvent(eventId: 'e2', lamport: 2),
      ];

      final newEvents = SyncMerger.merge(
        localEvents: events,
        remoteEvents: events,
      );

      expect(newEvents, isEmpty);
    });

    test('merge sorts new events in canonical order', () {
      final e1 = makeEvent(eventId: 'e-b-3', actorId: 'b', lamport: 3);
      final e2 = makeEvent(eventId: 'e-a-3', actorId: 'a', lamport: 3);
      final e3 = makeEvent(eventId: 'e-a-1', actorId: 'a', lamport: 1);

      final newEvents = SyncMerger.merge(
        localEvents: [],
        remoteEvents: [e1, e2, e3],
      );

      // Expected order: lamport 1 first, then lamport 3 actor 'a', then 'b'
      expect(newEvents[0].eventId, 'e-a-1');
      expect(newEvents[1].eventId, 'e-a-3');
      expect(newEvents[2].eventId, 'e-b-3');
    });

    test('detectConflicts identifies concurrent edits to same entity', () {
      final local = makeEvent(
        eventId: 'local-1',
        actorId: 'alice',
        entityId: 'entry-1',
        lamport: 5,
      );
      final remote = makeEvent(
        eventId: 'remote-1',
        actorId: 'bob',
        entityId: 'entry-1',
        lamport: 5,
      );

      final conflicts = SyncMerger.detectConflicts(
        localEvents: [local],
        remoteEvents: [remote],
      );

      expect(conflicts.length, 1);
      expect(conflicts[0].entityId, 'entry-1');
    });

    test('detectConflicts ignores same-actor events', () {
      final local = makeEvent(
        eventId: 'local-1',
        actorId: 'alice',
        entityId: 'entry-1',
        lamport: 5,
      );
      final remote = makeEvent(
        eventId: 'remote-1',
        actorId: 'alice',
        entityId: 'entry-1',
        lamport: 5,
      );

      final conflicts = SyncMerger.detectConflicts(
        localEvents: [local],
        remoteEvents: [remote],
      );

      expect(conflicts, isEmpty);
    });

    test('detectConflicts ignores distant lamport clocks', () {
      final local = makeEvent(
        eventId: 'local-1',
        actorId: 'alice',
        entityId: 'entry-1',
        lamport: 5,
      );
      final remote = makeEvent(
        eventId: 'remote-1',
        actorId: 'bob',
        entityId: 'entry-1',
        lamport: 10,
      );

      final conflicts = SyncMerger.detectConflicts(
        localEvents: [local],
        remoteEvents: [remote],
      );

      expect(conflicts, isEmpty);
    });

    test('conflict resolution uses deterministic actor ordering', () {
      final local = makeEvent(
        eventId: 'l1',
        actorId: 'alice',
        entityId: 'e1',
        lamport: 5,
      );
      final remote = makeEvent(
        eventId: 'r1',
        actorId: 'bob',
        entityId: 'e1',
        lamport: 5,
      );

      final conflicts = SyncMerger.detectConflicts(
        localEvents: [local],
        remoteEvents: [remote],
      );

      // 'alice' < 'bob' lexically → local_wins
      expect(conflicts[0].resolution, 'local_wins');
    });

    test('conflict resolution flags different op types for review', () {
      final local = makeEvent(
        eventId: 'l1',
        actorId: 'alice',
        entityId: 'e1',
        opType: SyncEventType.update,
        lamport: 5,
      );
      final remote = makeEvent(
        eventId: 'r1',
        actorId: 'bob',
        entityId: 'e1',
        opType: SyncEventType.delete,
        lamport: 5,
      );

      final conflicts = SyncMerger.detectConflicts(
        localEvents: [local],
        remoteEvents: [remote],
      );

      expect(conflicts[0].resolution, 'needs_review');
    });
  });

  // ── SyncEventRepository tests ──

  group('InMemorySyncEventRepository', () {
    late InMemorySyncEventRepository repo;

    setUp(() {
      repo = InMemorySyncEventRepository();
    });

    test('append and retrieve events', () async {
      final event = makeEvent(eventId: 'e1', lamport: 1);
      await repo.append(event);

      final events = await repo.getByLedgerId('ledger-1');
      expect(events.length, 1);
      expect(events[0].eventId, 'e1');
    });

    test('getByLedgerId returns events in canonical order', () async {
      await repo.append(makeEvent(eventId: 'e2', lamport: 2, actorId: 'b'));
      await repo.append(makeEvent(eventId: 'e1', lamport: 1, actorId: 'a'));
      await repo.append(makeEvent(eventId: 'e3', lamport: 2, actorId: 'a'));

      final events = await repo.getByLedgerId('ledger-1');
      expect(events[0].eventId, 'e1');
      expect(events[1].eventId, 'e3'); // lamport 2, actor 'a'
      expect(events[2].eventId, 'e2'); // lamport 2, actor 'b'
    });

    test('getSince filters by lamport', () async {
      await repo.append(makeEvent(eventId: 'e1', lamport: 1));
      await repo.append(makeEvent(eventId: 'e2', lamport: 2));
      await repo.append(makeEvent(eventId: 'e3', lamport: 3));

      final events = await repo.getSince('ledger-1', 1);
      expect(events.length, 2);
      expect(events[0].eventId, 'e2');
      expect(events[1].eventId, 'e3');
    });

    test('getEventCount returns correct count', () async {
      expect(await repo.getEventCount('ledger-1'), 0);

      await repo.append(makeEvent(eventId: 'e1', lamport: 1));
      await repo.append(makeEvent(eventId: 'e2', lamport: 2));

      expect(await repo.getEventCount('ledger-1'), 2);
      expect(await repo.getEventCount('other-ledger'), 0);
    });

    test('getMaxLamport returns highest lamport', () async {
      expect(await repo.getMaxLamport('ledger-1'), 0);

      await repo.append(makeEvent(eventId: 'e1', lamport: 5));
      await repo.append(makeEvent(eventId: 'e2', lamport: 3));
      await repo.append(makeEvent(eventId: 'e3', lamport: 10));

      expect(await repo.getMaxLamport('ledger-1'), 10);
    });

    test('filters by ledgerId', () async {
      await repo.append(
        makeEvent(eventId: 'e1', ledgerId: 'led-a', lamport: 1),
      );
      await repo.append(
        makeEvent(eventId: 'e2', ledgerId: 'led-b', lamport: 1),
      );

      final a = await repo.getByLedgerId('led-a');
      final b = await repo.getByLedgerId('led-b');

      expect(a.length, 1);
      expect(a[0].eventId, 'e1');
      expect(b.length, 1);
      expect(b[0].eventId, 'e2');
    });
  });

  // ── ExportSyncService tests ──

  group('ExportSyncService', () {
    late InMemorySyncEventRepository repo;
    late ExportSyncService service;

    setUp(() {
      repo = InMemorySyncEventRepository();
      service = ExportSyncService(eventRepo: repo);
    });

    test('exportBundle produces valid JSON bundle', () async {
      await repo.append(makeEvent(eventId: 'e1', lamport: 1));
      await repo.append(makeEvent(eventId: 'e2', lamport: 2));

      final json = await service.exportBundle(
        ledgerId: 'ledger-1',
        senderId: 'device-1',
        senderName: 'Alice',
      );

      final bundle = SyncSerializer.deserializeBundle(json);
      expect(bundle.senderId, 'device-1');
      expect(bundle.senderName, 'Alice');
      expect(bundle.events.length, 2);
      expect(bundle.lastLamport, 2);
    });

    test('exportBundle with sinceLamport filters old events', () async {
      await repo.append(makeEvent(eventId: 'e1', lamport: 1));
      await repo.append(makeEvent(eventId: 'e2', lamport: 2));
      await repo.append(makeEvent(eventId: 'e3', lamport: 3));

      final json = await service.exportBundle(
        ledgerId: 'ledger-1',
        senderId: 'device-1',
        senderName: 'Alice',
        sinceLamport: 1,
      );

      final bundle = SyncSerializer.deserializeBundle(json);
      expect(bundle.events.length, 2);
      expect(bundle.lastLamport, 3);
    });

    test('importBundle adds new events to repo', () async {
      // Local already has event 1.
      await repo.append(makeEvent(eventId: 'e1', lamport: 1));

      // Partner's bundle has events 1, 2, 3.
      final events = [
        makeEvent(eventId: 'e1', lamport: 1),
        makeEvent(eventId: 'e2', lamport: 2),
        makeEvent(eventId: 'e3', lamport: 3),
      ];
      final bundle = SyncBundle(
        senderId: 'partner-1',
        senderName: 'Bob',
        ledgerId: 'ledger-1',
        eventCount: 3,
        lastLamport: 3,
        createdAt: DateTime.now(),
        events: events,
      );
      final bundleJson = SyncSerializer.serializeBundle(bundle);

      final result = await service.importBundle(bundleJson);

      expect(result.newEventsCount, 2);
      expect(result.senderName, 'Bob');

      // Repo should now have 3 events.
      final all = await repo.getByLedgerId('ledger-1');
      expect(all.length, 3);
    });

    test('importBundle detects conflicts', () async {
      // Local has an event from actor 'alice'.
      await repo.append(
        makeEvent(
          eventId: 'local-1',
          actorId: 'alice',
          entityId: 'entry-1',
          lamport: 5,
        ),
      );

      // Remote has a concurrent event from actor 'bob'.
      final events = [
        makeEvent(
          eventId: 'remote-1',
          actorId: 'bob',
          entityId: 'entry-1',
          lamport: 5,
        ),
      ];
      final bundle = SyncBundle(
        senderId: 'bob-device',
        senderName: 'Bob',
        ledgerId: 'ledger-1',
        eventCount: 1,
        lastLamport: 5,
        createdAt: DateTime.now(),
        events: events,
      );
      final bundleJson = SyncSerializer.serializeBundle(bundle);

      final result = await service.importBundle(bundleJson);

      expect(result.newEventsCount, 1);
      expect(result.hasConflicts, isTrue);
      expect(result.conflicts.length, 1);
    });

    test('getEventCount returns correct count', () async {
      expect(await service.getEventCount('ledger-1'), 0);

      await repo.append(makeEvent(eventId: 'e1', lamport: 1));
      await repo.append(makeEvent(eventId: 'e2', lamport: 2));

      expect(await service.getEventCount('ledger-1'), 2);
    });

    test('exportBundle handles empty ledger', () async {
      final json = await service.exportBundle(
        ledgerId: 'empty-ledger',
        senderId: 'device-1',
        senderName: 'Alice',
      );

      final bundle = SyncSerializer.deserializeBundle(json);
      expect(bundle.events, isEmpty);
      expect(bundle.eventCount, 0);
      expect(bundle.lastLamport, 0);
    });
  });
}
