/// Tracks whether the app is running in guest / demo mode.
///
/// When active, the app shows seed data with a synthetic partner
/// so that a single user can explore the UI before pairing.
class GuestMode {
  static bool _isActive = false;

  /// Whether guest mode is currently enabled.
  static bool get isActive => _isActive;

  /// Enable guest / demo mode.
  static void enable() => _isActive = true;

  /// Disable guest / demo mode.
  static void disable() => _isActive = false;
}
