import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:care_ledger_app/core/ids.dart';

/// Manages device-bound identity for the current user.
///
/// On first launch, generates a unique device ID and invite code.
/// Stores identity, onboarding state, and partner pairing info
/// in [SharedPreferences].
class IdentityService {
  static const _keyDeviceId = 'cl_device_id';
  static const _keyUserName = 'cl_user_name';
  static const _keyIsOnboarded = 'cl_is_onboarded';
  static const _keyPartnerId = 'cl_partner_id';
  static const _keyPartnerName = 'cl_partner_name';
  static const _keyIsPaired = 'cl_is_paired';
  static const _keyInviteCode = 'cl_invite_code';

  final SharedPreferences _prefs;

  IdentityService._(this._prefs);

  /// Creates and initialises the identity service.
  ///
  /// Generates a device ID and invite code on first launch.
  static Future<IdentityService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final service = IdentityService._(prefs);
    await service._ensureDeviceId();
    return service;
  }

  // ── Initialisation ──

  Future<void> _ensureDeviceId() async {
    if (_prefs.getString(_keyDeviceId) == null) {
      await _prefs.setString(_keyDeviceId, IdGenerator.generate());
    }
    if (_prefs.getString(_keyInviteCode) == null) {
      await _prefs.setString(_keyInviteCode, _generateInviteCode());
    }
  }

  /// Generates a 6-character alphanumeric invite code.
  static String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  // ── Getters ──

  /// The unique device identity for this user.
  String get deviceId => _prefs.getString(_keyDeviceId)!;

  /// The current user's display name, or `null` before onboarding.
  String? get userName => _prefs.getString(_keyUserName);

  /// Whether the user has completed onboarding (entered their name).
  bool get isOnboarded => _prefs.getBool(_keyIsOnboarded) ?? false;

  /// The paired partner's device ID, or `null` if not paired.
  String? get partnerId => _prefs.getString(_keyPartnerId);

  /// The paired partner's display name, or `null` if not paired.
  String? get partnerName => _prefs.getString(_keyPartnerName);

  /// Whether the device is paired with a partner.
  bool get isPaired => _prefs.getBool(_keyIsPaired) ?? false;

  /// The invite code for this device.
  String get inviteCode => _prefs.getString(_keyInviteCode)!;

  // ── Actions ──

  /// Mark onboarding as complete and save the user's chosen name.
  Future<void> completeOnboarding(String name) async {
    await _prefs.setString(_keyUserName, name);
    await _prefs.setBool(_keyIsOnboarded, true);
  }

  /// Record the partner pairing.
  Future<void> completePairing({
    required String partnerId,
    required String partnerName,
  }) async {
    await _prefs.setString(_keyPartnerId, partnerId);
    await _prefs.setString(_keyPartnerName, partnerName);
    await _prefs.setBool(_keyIsPaired, true);
  }

  /// Update the current user's display name.
  Future<void> updateUserName(String name) async {
    await _prefs.setString(_keyUserName, name);
  }

  /// Update the partner's display name.
  Future<void> updatePartnerName(String name) async {
    await _prefs.setString(_keyPartnerName, name);
  }

  /// Reset all identity data (useful for testing / sign-out).
  Future<void> reset() async {
    await _prefs.remove(_keyDeviceId);
    await _prefs.remove(_keyUserName);
    await _prefs.remove(_keyIsOnboarded);
    await _prefs.remove(_keyPartnerId);
    await _prefs.remove(_keyPartnerName);
    await _prefs.remove(_keyIsPaired);
    await _prefs.remove(_keyInviteCode);
    await _ensureDeviceId();
  }
}
