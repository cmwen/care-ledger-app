import 'package:care_ledger_app/core/ids.dart';
import 'package:care_ledger_app/features/auto_capture/domain/capture_signal.dart';
import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';

/// A saved location that can trigger auto-capture signals.
///
/// Users create saved locations via an "I'm here now" flow.
/// When the real geofencing implementation detects entry/exit
/// from these locations, it generates [CaptureSignal]s.
class SavedLocation {
  final String id;

  /// Human-readable label (e.g., "School", "Doctor's Office").
  final String label;

  /// GPS coordinates — nullable for the stub implementation.
  final double? latitude;
  final double? longitude;

  /// Geofence radius in meters.
  final int radiusMeters;

  /// Default category for entries created at this location.
  final EntryCategory defaultCategory;

  /// Default credits for entries created at this location.
  final double defaultCredits;

  final DateTime createdAt;

  const SavedLocation({
    required this.id,
    required this.label,
    this.latitude,
    this.longitude,
    this.radiusMeters = 200,
    required this.defaultCategory,
    this.defaultCredits = 1.0,
    required this.createdAt,
  });

  SavedLocation copyWith({
    String? id,
    String? label,
    double? latitude,
    double? longitude,
    int? radiusMeters,
    EntryCategory? defaultCategory,
    double? defaultCredits,
    DateTime? createdAt,
  }) {
    return SavedLocation(
      id: id ?? this.id,
      label: label ?? this.label,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      defaultCategory: defaultCategory ?? this.defaultCategory,
      defaultCredits: defaultCredits ?? this.defaultCredits,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'SavedLocation($id, $label, ${defaultCategory.label})';
}

/// Geofence service stub.
///
/// This is the pluggable interface for location-based auto-capture.
/// The stub returns empty results; a real implementation would use
/// platform-specific geofencing APIs.
class GeofenceService {
  final List<SavedLocation> _locations = [];

  /// Stub: returns empty signals.
  ///
  /// A real implementation would check current location against
  /// saved geofences and return transition events.
  Future<List<CaptureSignal>> checkGeofenceTransitions() async => [];

  /// Save the user's current location for future geofence matching.
  ///
  /// In the real implementation, latitude/longitude would come from
  /// the device's GPS. For the stub, we store the metadata without
  /// actual coordinates.
  Future<SavedLocation> saveCurrentLocation({
    required String label,
    required EntryCategory category,
    double credits = 1.0,
    double? latitude,
    double? longitude,
    int radiusMeters = 200,
  }) async {
    final location = SavedLocation(
      id: IdGenerator.generate(),
      label: label,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      defaultCategory: category,
      defaultCredits: credits,
      createdAt: DateTime.now(),
    );
    _locations.add(location);
    return location;
  }

  /// Remove a saved location.
  void removeLocation(String id) {
    _locations.removeWhere((loc) => loc.id == id);
  }

  /// All saved locations (read-only view).
  List<SavedLocation> get savedLocations => List.unmodifiable(_locations);
}
