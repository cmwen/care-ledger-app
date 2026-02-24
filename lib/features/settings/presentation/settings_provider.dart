import 'package:flutter/material.dart';
import 'package:care_ledger_app/features/settings/domain/participant.dart';

/// State provider for app settings.
///
/// Manages participant names, locale, and theme preferences.
class SettingsProvider extends ChangeNotifier {
  // Participant names mapped by ID
  final Map<String, Participant> _participants = {
    'participant-a': const Participant(id: 'participant-a', name: 'Parent A'),
    'participant-b': const Participant(id: 'participant-b', name: 'Parent B'),
  };

  // Current user ID (for MVP, always participant-a)
  String _currentUserId = 'participant-a';

  // Locale
  Locale _locale = const Locale('en');

  // Theme mode
  ThemeMode _themeMode = ThemeMode.system;

  // ── Getters ──

  Map<String, Participant> get participants => Map.unmodifiable(_participants);

  List<Participant> get participantList => _participants.values.toList();

  String get currentUserId => _currentUserId;

  Participant? get currentUser => _participants[_currentUserId];

  Locale get locale => _locale;

  ThemeMode get themeMode => _themeMode;

  /// Get participant name by ID, fallback to ID if not found.
  String participantName(String id) {
    return _participants[id]?.name ?? id;
  }

  /// Get participant by ID.
  Participant? getParticipant(String id) => _participants[id];

  // ── Actions ──

  /// Update a participant's name.
  void updateParticipantName(String id, String name) {
    if (_participants.containsKey(id)) {
      _participants[id] = _participants[id]!.copyWith(name: name);
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
    if (id != _currentUserId && _participants.containsKey(id)) {
      _participants.remove(id);
      notifyListeners();
    }
  }

  /// Set the current user.
  void setCurrentUser(String id) {
    if (_participants.containsKey(id)) {
      _currentUserId = id;
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
