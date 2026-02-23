import 'dart:math';

/// Generates unique IDs for domain entities.
///
/// Uses timestamp + cryptographic random hex for reasonable uniqueness
/// without requiring an external UUID package.
class IdGenerator {
  static final _random = Random.secure();

  /// Generates a unique ID string (e.g., "lq4k2f8-a3b1c9d0").
  static String generate() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final random = List.generate(
      8,
      (_) => _random.nextInt(16).toRadixString(16),
    ).join();
    return '$timestamp-$random';
  }
}
