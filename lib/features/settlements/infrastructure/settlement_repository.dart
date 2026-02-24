import 'package:care_ledger_app/features/settlements/domain/settlement.dart';

/// Repository interface for Settlement persistence.
abstract class SettlementRepository {
  /// Get a settlement by ID.
  Future<Settlement?> getById(String id);

  /// Get all settlements for a ledger.
  Future<List<Settlement>> getByLedgerId(String ledgerId);

  /// Get open (proposed or accepted) settlements for a ledger.
  Future<List<Settlement>> getOpenByLedgerId(String ledgerId);

  /// Get completed settlements for a ledger.
  Future<List<Settlement>> getCompletedByLedgerId(String ledgerId);

  /// Persist a settlement (create or update).
  Future<void> save(Settlement settlement);
}

/// In-memory implementation for M1 development.
class InMemorySettlementRepository implements SettlementRepository {
  final Map<String, Settlement> _store = {};

  @override
  Future<Settlement?> getById(String id) async => _store[id];

  @override
  Future<List<Settlement>> getByLedgerId(String ledgerId) async =>
      _store.values.where((s) => s.ledgerId == ledgerId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<List<Settlement>> getOpenByLedgerId(String ledgerId) async =>
      _store.values.where((s) => s.ledgerId == ledgerId && s.isOpen).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<List<Settlement>> getCompletedByLedgerId(String ledgerId) async =>
      _store.values
          .where(
            (s) =>
                s.ledgerId == ledgerId &&
                s.status == SettlementStatus.completed,
          )
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<void> save(Settlement settlement) async =>
      _store[settlement.id] = settlement;
}
