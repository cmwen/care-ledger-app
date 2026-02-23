import 'package:flutter/foundation.dart';
import 'package:care_ledger_app/features/balance/domain/balance.dart';
import 'package:care_ledger_app/features/balance/application/balance_service.dart';
import 'package:care_ledger_app/features/ledger/domain/ledger.dart';
import 'package:care_ledger_app/features/settlements/domain/settlement.dart';
import 'package:care_ledger_app/features/settlements/application/settlement_service.dart';

/// State provider for balance and settlements.
///
/// Manages balance computation and settlement lifecycle.
class BalanceProvider extends ChangeNotifier {
  final BalanceService _balanceService;
  final SettlementService _settlementService;

  LedgerBalance? _balance;
  List<Settlement> _settlements = [];
  bool _isLoading = false;
  String? _error;

  BalanceProvider({
    required BalanceService balanceService,
    required SettlementService settlementService,
  })  : _balanceService = balanceService,
        _settlementService = settlementService;

  // ── Getters ──

  LedgerBalance? get balance => _balance;
  List<Settlement> get settlements => List.unmodifiable(_settlements);
  List<Settlement> get openSettlements =>
      _settlements.where((s) => s.isOpen).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Actions ──

  /// Refresh the balance for the given ledger.
  Future<void> refreshBalance(Ledger ledger) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _balance = await _balanceService.calculateBalance(ledger);
      _settlements = await _settlementService.getSettlements(ledger.id);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Propose a new settlement.
  Future<void> proposeSettlement({
    required String ledgerId,
    required String proposerId,
    required SettlementMethod method,
    required double credits,
    String? note,
    DateTime? dueDate,
  }) async {
    try {
      final settlement = await _settlementService.proposeSettlement(
        ledgerId: ledgerId,
        proposerId: proposerId,
        method: method,
        credits: credits,
        note: note,
        dueDate: dueDate,
      );
      _settlements.insert(0, settlement);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Respond to a settlement (accept/reject).
  Future<void> respondToSettlement({
    required String settlementId,
    required bool accept,
    Ledger? ledger,
  }) async {
    try {
      final updated = await _settlementService.respondToSettlement(
        settlementId: settlementId,
        accept: accept,
      );
      final index = _settlements.indexWhere((s) => s.id == settlementId);
      if (index >= 0) _settlements[index] = updated;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Mark a settlement as completed and refresh balance.
  Future<void> completeSettlement({
    required String settlementId,
    required Ledger ledger,
  }) async {
    try {
      final completed =
          await _settlementService.completeSettlement(settlementId);
      final index = _settlements.indexWhere((s) => s.id == settlementId);
      if (index >= 0) _settlements[index] = completed;

      // Recompute balance after settlement
      _balance = await _balanceService.calculateBalance(ledger);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
