import 'package:care_ledger_app/sync/domain/sync_event.dart';

/// Repository interface for SyncEvent persistence.
abstract class SyncEventRepository {
  /// Get all events for a ledger, in canonical order.
  Future<List<SyncEvent>> getByLedgerId(String ledgerId);

  /// Get events since a specific lamport clock value.
  Future<List<SyncEvent>> getSince(String ledgerId, int sincelamport);

  /// Append a sync event.
  Future<void> append(SyncEvent event);
}

/// In-memory implementation for M1 development.
class InMemorySyncEventRepository implements SyncEventRepository {
  final List<SyncEvent> _store = [];

  @override
  Future<List<SyncEvent>> getByLedgerId(String ledgerId) async =>
      _store.where((e) => e.ledgerId == ledgerId).toList()..sort((a, b) {
        final cmp = a.lamport.compareTo(b.lamport);
        if (cmp != 0) return cmp;
        return a.actorId.compareTo(b.actorId);
      });

  @override
  Future<List<SyncEvent>> getSince(String ledgerId, int sinceLamport) async =>
      _store
          .where((e) => e.ledgerId == ledgerId && e.lamport > sinceLamport)
          .toList()
        ..sort((a, b) {
          final cmp = a.lamport.compareTo(b.lamport);
          if (cmp != 0) return cmp;
          return a.actorId.compareTo(b.actorId);
        });

  @override
  Future<void> append(SyncEvent event) async => _store.add(event);
}
