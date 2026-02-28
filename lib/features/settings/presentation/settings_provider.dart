import 'package:flutter/material.dart';

import 'package:care_ledger_app/core/identity_service.dart';
import 'package:care_ledger_app/features/settings/domain/participant.dart';

/// State provider for app settings.
///
/// Manages participant names, locale, and theme preferences.
/// Identity is bound to the device via [IdentityService].
class SettingsProvider extends ChangeNotifier {
  final IdentityService _identity;

  // Participant names mapped by ID
  final Map<String, Participant> _participants = {};

  // Locale
  Locale _locale = const Locale('en');

  // Theme mode
  ThemeMode _themeMode = ThemeMode.system;

  SettingsProvider({required IdentityService identity}) : _identity = identity {
    _syncFromIdentity();
  }

  /// Populate the participants map from [IdentityService] state.
  void _syncFromIdentity() {
    // Always register the current device user.
    if (_identity.userName != null) {
      _participants[_identity.deviceId] = Participant(
        id: _identity.deviceId,
        name: _identity.userName!,
      );
    }

    // Register the paired partner if available.
    if (_identity.isPaired &&
        _identity.partnerId != null &&
        _identity.partnerName != null) {
      _participants[_identity.partnerId!] = Participant(
        id: _identity.partnerId!,
        name: _identity.partnerName!,
      );
    }
  }

  // ── Getters ──

  Map<String, Participant> get participants => Map.unmodifiable(_participants);

  List<Participant> get participantList => _participants.values.toList();

  String get currentUserId => _identity.deviceId;

  Participant? get currentUser => _participants[_identity.deviceId];

  Locale get locale => _locale;

  ThemeMode get themeMode => _themeMode;

  bool get isOnboarded => _identity.isOnboarded;

  bool get isPaired => _identity.isPaired;

  String get inviteCode => _identity.inviteCode;

  String? get partnerId => _identity.partnerId;

  /// Get participant name by ID, fallback to ID if not found.
  String participantName(String id) {
    return _participants[id]?.name ?? id;
  }

  /// Get participant by ID.
  Participant? getParticipant(String id) => _participants[id];

  /// Returns "You" if the ID matches currentUser, otherwise the participant's name.
  String perspectiveName(String participantId) {
    if (participantId == currentUserId) return 'You';
    return participantName(participantId);
  }

  /// Returns the partner's Participant object.
  Participant? get partner {
    if (_participants.isEmpty) return null;
    try {
      return _participants.values.firstWhere((p) => p.id != currentUserId);
    } catch (_) {
      return _participants.values.first;
    }
  }

  /// The partner's display name, with fallback.
  String get partnerName => partner?.name ?? 'Partner';

  // ── Actions ──

  /// Complete onboarding by saving the user's display name.
  Future<void> completeOnboarding(String name) async {
    await _identity.completeOnboarding(name);
    _participants[_identity.deviceId] = Participant(
      id: _identity.deviceId,
      name: name,
    );
    notifyListeners();
  }

  /// Record a successful pairing with a partner.
  Future<void> completePairing(String partnerName, String partnerId) async {
    await _identity.completePairing(
      partnerId: partnerId,
      partnerName: partnerName,
    );
    _participants[partnerId] = Participant(id: partnerId, name: partnerName);
    notifyListeners();
  }

  /// Update a participant's name.
  void updateParticipantName(String id, String name) {
    if (_participants.containsKey(id)) {
      _participants[id] = _participants[id]!.copyWith(name: name);

      // Persist to IdentityService if it's the current user or partner.
      if (id == _identity.deviceId) {
        _identity.updateUserName(name);
      } else if (id == _identity.partnerId) {
        _identity.updatePartnerName(name);
      }
      notifyListeners();
    }
  }

  /// Add a new participant.
  void addParticipant(Participant participant) {
    _participants[participant.id] = participant;
    notifyListeners();
  }

  /// Remove a participant (cannot remove current user).
  void removeParticipant(String id) {
    if (id != currentUserId && _participants.containsKey(id)) {
      _participants.remove(id);
      notifyListeners();
    }
  }

  /// Set the app locale.
  void setLocale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  /// Set the theme mode.
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
