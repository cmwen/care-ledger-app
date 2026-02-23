import 'package:care_ledger_app/features/ledger/domain/ledger.dart';

/// Repository interface for Ledger persistence.
abstract class LedgerRepository {
  /// Get a ledger by ID.
  Future<Ledger?> getById(String id);

  /// Get all ledgers.
  Future<List<Ledger>> getAll();

  /// Get all active ledgers.
  Future<List<Ledger>> getActive();

  /// Persist a ledger (create or update).
  Future<void> save(Ledger ledger);

  /// Delete a ledger by ID.
  Future<void> delete(String id);
}

/// In-memory implementation for M1 development.
class InMemoryLedgerRepository implements LedgerRepository {
  final Map<String, Ledger> _store = {};

  @override
  Future<Ledger?> getById(String id) async => _store[id];

  @override
  Future<List<Ledger>> getAll() async => _store.values.toList();

  @override
  Future<List<Ledger>> getActive() async =>
      _store.values.where((l) => l.isActive).toList();

  @override
  Future<void> save(Ledger ledger) async => _store[ledger.id] = ledger;

  @override
  Future<void> delete(String id) async => _store.remove(id);
}
