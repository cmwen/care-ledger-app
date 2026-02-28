import 'package:care_ledger_app/sync/domain/sync_event.dart';

/// Repository interface for SyncEvent persistence.
abstract class SyncEventRepository {
  /// Get all events for a ledger, in canonical order.
  Future<List<SyncEvent>> getByLedgerId(String ledgerId);

  /// Get events since a specific lamport clock value.
  Future<List<SyncEvent>> getSince(String ledgerId, int sinceLamport);

  /// Return the total number of events for a ledger.
  Future<int> getEventCount(String ledgerId);

  /// Return the highest lamport clock value for a ledger (0 if empty).
  Future<int> getMaxLamport(String ledgerId);

  /// Append a sync event.
  Future<void> append(SyncEvent event);
}

/// In-memory implementation for M1 development.
class InMemorySyncEventRepository implements SyncEventRepository {
  final List<SyncEvent> _store = [];

  /// Canonical sort: lamport asc → actorId asc → createdAt asc.
  static int _canonicalSort(SyncEvent a, SyncEvent b) {
    final lamportCmp = a.lamport.compareTo(b.lamport);
    if (lamportCmp != 0) return lamportCmp;
    final actorCmp = a.actorId.compareTo(b.actorId);
    if (actorCmp != 0) return actorCmp;
    return a.createdAt.compareTo(b.createdAt);
  }

  @override
  Future<List<SyncEvent>> getByLedgerId(String ledgerId) async =>
      _store.where((e) => e.ledgerId == ledgerId).toList()
        ..sort(_canonicalSort);

  @override
  Future<List<SyncEvent>> getSince(String ledgerId, int sinceLamport) async =>
      _store
          .where((e) => e.ledgerId == ledgerId && e.lamport > sinceLamport)
          .toList()
        ..sort(_canonicalSort);

  @override
  Future<int> getEventCount(String ledgerId) async =>
      _store.where((e) => e.ledgerId == ledgerId).length;

  @override
  Future<int> getMaxLamport(String ledgerId) async {
    final events = _store.where((e) => e.ledgerId == ledgerId);
    if (events.isEmpty) return 0;
    return events.map((e) => e.lamport).reduce((a, b) => a > b ? a : b);
  }

  @override
  Future<void> append(SyncEvent event) async => _store.add(event);
}
