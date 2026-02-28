import 'package:care_ledger_app/sync/application/sync_merger.dart';
import 'package:care_ledger_app/sync/application/sync_serializer.dart';
import 'package:care_ledger_app/sync/infrastructure/sync_event_repository.dart';

/// Layer 1 sync: export / import via JSON bundles (QR, clipboard, file).
///
/// Supports offline, air-gapped sync between two devices by exchanging
/// human-readable JSON strings.
class ExportSyncService {
  final SyncEventRepository _eventRepo;

  ExportSyncService({required SyncEventRepository eventRepo})
    : _eventRepo = eventRepo;

  /// Export events since a lamport clock value as a JSON bundle.
  ///
  /// Returns a human-readable JSON string suitable for QR code, clipboard,
  /// or file sharing.
  Future<String> exportBundle({
    required String ledgerId,
    required String senderId,
    required String senderName,
    int sinceLamport = 0,
  }) async {
    final events = await _eventRepo.getSince(ledgerId, sinceLamport);
    final bundle = SyncBundle(
      senderId: senderId,
      senderName: senderName,
      ledgerId: ledgerId,
      eventCount: events.length,
      lastLamport: events.isEmpty ? sinceLamport : events.last.lamport,
      createdAt: DateTime.now(),
      events: events,
    );
    return SyncSerializer.serializeBundle(bundle);
  }

  /// Import a bundle received from a partner.
  ///
  /// Merges new events into the local event log and returns an import result
  /// with the count of new events and any detected conflicts.
  Future<SyncImportResult> importBundle(String bundleJson) async {
    final bundle = SyncSerializer.deserializeBundle(bundleJson);
    final localEvents = await _eventRepo.getByLedgerId(bundle.ledgerId);

    final newEvents = SyncMerger.merge(
      localEvents: localEvents,
      remoteEvents: bundle.events,
    );

    final conflicts = SyncMerger.detectConflicts(
      localEvents: localEvents,
      remoteEvents: bundle.events,
    );

    // Persist new events.
    for (final event in newEvents) {
      await _eventRepo.append(event);
    }

    return SyncImportResult(
      newEventsCount: newEvents.length,
      conflicts: conflicts,
      senderName: bundle.senderName,
    );
  }

  /// Get the total event count for a ledger.
  Future<int> getEventCount(String ledgerId) =>
      _eventRepo.getEventCount(ledgerId);
}

/// Result of importing a sync bundle.
class SyncImportResult {
  final int newEventsCount;
  final List<SyncConflict> conflicts;
  final String senderName;

  const SyncImportResult({
    required this.newEventsCount,
    required this.conflicts,
    required this.senderName,
  });

  bool get hasConflicts => conflicts.isNotEmpty;

  @override
  String toString() =>
      'SyncImportResult(new=$newEventsCount, conflicts=${conflicts.length}, '
      'from=$senderName)';
}
