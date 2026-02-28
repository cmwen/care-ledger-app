import 'package:flutter/foundation.dart';

import 'package:care_ledger_app/sync/infrastructure/export_sync_service.dart';
import 'package:care_ledger_app/sync/infrastructure/lan_sync_service.dart';

/// Status of a sync operation.
enum SyncStatus { idle, exporting, importing, syncing, error, success }

/// State provider for sync operations.
///
/// Manages export/import workflows and exposes state to the UI.
class SyncProvider extends ChangeNotifier {
  final ExportSyncService _exportService;
  final LanSyncService _lanService;

  SyncStatus _status = SyncStatus.idle;
  String? _lastExportData;
  SyncImportResult? _lastImportResult;
  String? _errorMessage;
  int _localEventCount = 0;

  SyncProvider({
    required ExportSyncService exportService,
    required LanSyncService lanService,
  }) : _exportService = exportService,
       _lanService = lanService;

  // ── Getters ──

  SyncStatus get status => _status;
  String? get lastExportData => _lastExportData;
  SyncImportResult? get lastImportResult => _lastImportResult;
  String? get errorMessage => _errorMessage;
  int get localEventCount => _localEventCount;
  bool get isLanAvailable => _lanService.isAvailable;
  LanSyncState get lanState => _lanService.state;

  // ── Actions ──

  /// Export events as a shareable JSON bundle.
  Future<void> exportEvents({
    required String ledgerId,
    required String senderId,
    required String senderName,
  }) async {
    _status = SyncStatus.exporting;
    _errorMessage = null;
    notifyListeners();

    try {
      _lastExportData = await _exportService.exportBundle(
        ledgerId: ledgerId,
        senderId: senderId,
        senderName: senderName,
      );
      _status = SyncStatus.success;
    } catch (e) {
      _errorMessage = e.toString();
      _status = SyncStatus.error;
    }

    notifyListeners();
  }

  /// Import a bundle from a partner (pasted text or QR scan).
  Future<void> importEvents(String bundleJson) async {
    _status = SyncStatus.importing;
    _errorMessage = null;
    _lastImportResult = null;
    notifyListeners();

    try {
      _lastImportResult = await _exportService.importBundle(bundleJson);
      _status = SyncStatus.success;
    } catch (e) {
      _errorMessage = e.toString();
      _status = SyncStatus.error;
    }

    notifyListeners();
  }

  /// Refresh the local event count for display.
  Future<void> refreshEventCount(String ledgerId) async {
    try {
      _localEventCount = await _exportService.getEventCount(ledgerId);
      notifyListeners();
    } catch (e) {
      // Silently ignore — the count is informational only.
      debugPrint('Failed to refresh event count: $e');
    }
  }

  /// Reset status back to idle (e.g., after dismissing a result).
  void resetStatus() {
    _status = SyncStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
