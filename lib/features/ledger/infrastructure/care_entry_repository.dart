import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';

/// Repository interface for CareEntry persistence.
abstract class CareEntryRepository {
  /// Get a care entry by ID.
  Future<CareEntry?> getById(String id);

  /// Get all entries for a ledger.
  Future<List<CareEntry>> getByLedgerId(String ledgerId);

  /// Get entries for a ledger filtered by status.
  Future<List<CareEntry>> getByStatus(String ledgerId, EntryStatus status);

  /// Get entries for a ledger within a date range (inclusive).
  Future<List<CareEntry>> getByDateRange(
    String ledgerId,
    DateTime start,
    DateTime end,
  );

  /// Get the weekly review queue: entries needing action.
  Future<List<CareEntry>> getReviewQueue(String ledgerId);

  /// Persist a care entry (create or update).
  Future<void> save(CareEntry entry);

  /// Delete a care entry by ID.
  Future<void> delete(String id);
}

/// In-memory implementation for M1 development.
class InMemoryCareEntryRepository implements CareEntryRepository {
  final Map<String, CareEntry> _store = {};

  @override
  Future<CareEntry?> getById(String id) async => _store[id];

  @override
  Future<List<CareEntry>> getByLedgerId(String ledgerId) async =>
      _store.values
          .where((e) => e.ledgerId == ledgerId)
          .toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  @override
  Future<List<CareEntry>> getByStatus(
    String ledgerId,
    EntryStatus status,
  ) async =>
      _store.values
          .where((e) => e.ledgerId == ledgerId && e.status == status)
          .toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  @override
  Future<List<CareEntry>> getByDateRange(
    String ledgerId,
    DateTime start,
    DateTime end,
  ) async =>
      _store.values
          .where(
            (e) =>
                e.ledgerId == ledgerId &&
                !e.occurredAt.isBefore(start) &&
                !e.occurredAt.isAfter(end),
          )
          .toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  @override
  Future<List<CareEntry>> getReviewQueue(String ledgerId) async =>
      _store.values
          .where((e) => e.ledgerId == ledgerId && e.isActionable)
          .toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  @override
  Future<void> save(CareEntry entry) async => _store[entry.id] = entry;

  @override
  Future<void> delete(String id) async => _store.remove(id);
}
