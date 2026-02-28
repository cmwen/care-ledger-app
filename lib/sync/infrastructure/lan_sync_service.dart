import 'package:care_ledger_app/sync/infrastructure/export_sync_service.dart';

/// Connection state for LAN-based sync discovery.
enum LanSyncState { idle, searching, connected, syncing, error }

/// Layer 2 sync stub: automatic sync over local WiFi.
///
/// This is a placeholder for future mDNS / NSD-based peer discovery.
/// Currently returns stub values to allow the UI to render correctly.
class LanSyncService {
  LanSyncState _state = LanSyncState.idle;
  String? _connectedPeerName;

  /// Current connection state.
  LanSyncState get state => _state;

  /// Name of the connected peer, if any.
  String? get connectedPeerName => _connectedPeerName;

  /// Whether LAN sync is available on this platform.
  ///
  /// Always `false` for the MVP stub.
  bool get isAvailable => false;

  /// Start searching for peers on the local network.
  ///
  /// Stub: would use `network_info_plus` + NSD for mDNS discovery.
  Future<void> startDiscovery() async {
    _state = LanSyncState.searching;
    // In real implementation:
    //   1. Register an NSD service for this device.
    //   2. Browse for matching services on the local network.
    //   3. On discovery, transition to LanSyncState.connected.
  }

  /// Stop searching for peers.
  Future<void> stopDiscovery() async {
    _state = LanSyncState.idle;
    _connectedPeerName = null;
  }

  /// Attempt to sync with the discovered peer.
  ///
  /// Stub: returns null. A real implementation would exchange bundles
  /// over a local TCP/HTTP connection.
  Future<SyncImportResult?> syncWithPeer() async => null;
}
