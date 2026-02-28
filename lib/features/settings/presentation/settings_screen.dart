import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:care_ledger_app/features/ledger/presentation/ledger_provider.dart';
import 'package:care_ledger_app/features/settings/presentation/settings_provider.dart';
import 'package:care_ledger_app/features/settings/domain/participant.dart';
import 'package:care_ledger_app/core/ids.dart';
import 'package:care_ledger_app/sync/presentation/sync_provider.dart';
import 'package:care_ledger_app/sync/presentation/sync_screen.dart';

/// Settings screen with participants, language, theme, and ledger info.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer2<LedgerProvider, SettingsProvider>(
      builder: (context, ledgerProvider, settings, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Participants section ──
            _SectionHeader(title: 'Participants', icon: Icons.people),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...settings.participantList.map((p) {
                      final isCurrentUser = p.id == settings.currentUserId;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCurrentUser
                              ? theme.colorScheme.primaryContainer
                              : theme.colorScheme.secondaryContainer,
                          child: Text(p.initial),
                        ),
                        title: Text(p.name),
                        subtitle: isCurrentUser
                            ? Text(
                                'You',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () =>
                                  _editParticipantName(context, p, settings),
                            ),
                            if (!isCurrentUser &&
                                settings.participantList.length > 2)
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    settings.removeParticipant(p.id),
                              ),
                          ],
                        ),
                        contentPadding: EdgeInsets.zero,
                        onTap: () => _editParticipantName(context, p, settings),
                      );
                    }),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _addParticipant(context, settings),
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Add Participant'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Appearance section ──
            _SectionHeader(title: 'Appearance', icon: Icons.palette),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Language selection
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: const Text('Language'),
                      subtitle: Text(_localeName(settings.locale)),
                      trailing: const Icon(Icons.chevron_right),
                      contentPadding: EdgeInsets.zero,
                      onTap: () => _showLanguagePicker(context, settings),
                    ),
                    const Divider(),
                    // Theme selection
                    ListTile(
                      leading: const Icon(Icons.brightness_6),
                      title: const Text('Theme'),
                      subtitle: Text(_themeModeName(settings.themeMode)),
                      trailing: const Icon(Icons.chevron_right),
                      contentPadding: EdgeInsets.zero,
                      onTap: () => _showThemePicker(context, settings),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Sync health section ──
            _SectionHeader(title: 'Sync Status', icon: Icons.sync),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Builder(
                  builder: (context) {
                    // SyncProvider is optional — check if it's available.
                    SyncProvider? syncProvider;
                    try {
                      syncProvider = context.watch<SyncProvider>();
                    } catch (_) {
                      // SyncProvider not wired yet.
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: syncProvider != null
                                    ? Colors.green
                                    : Colors.amber,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                syncProvider != null
                                    ? 'Export/Import sync enabled'
                                    : 'Local mode (sync not yet enabled)',
                              ),
                            ),
                          ],
                        ),
                        if (syncProvider != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${syncProvider.localEventCount} sync events recorded',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          syncProvider != null
                              ? 'Tap below to share or receive data with your partner.'
                              : 'All data is stored locally on this device.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SyncScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.sync, size: 18),
                            label: const Text('Sync Data'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Ledger info ──
            if (ledgerProvider.hasLedger) ...[
              _SectionHeader(title: 'Ledger', icon: Icons.book),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        label: 'Title',
                        value: ledgerProvider.activeLedger!.title,
                      ),
                      _InfoRow(
                        label: 'Status',
                        value: ledgerProvider.activeLedger!.status.label,
                      ),
                      _InfoRow(
                        label: 'Total entries',
                        value: '${ledgerProvider.entries.length}',
                      ),
                      _InfoRow(
                        label: 'Confirmed',
                        value: '${ledgerProvider.confirmedEntries.length}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // App info
            Center(
              child: Column(
                children: [
                  Text(
                    'Care Ledger',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'v1.0.0 · MVP',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _editParticipantName(
    BuildContext context,
    Participant participant,
    SettingsProvider settings,
  ) {
    final controller = TextEditingController(text: participant.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                settings.updateParticipantName(participant.id, name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addParticipant(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Participant'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Enter participant name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                settings.addParticipant(
                  Participant(id: IdGenerator.generate(), name: name),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Language'),
        children: [
          _LanguageOption(
            locale: const Locale('en'),
            label: 'English',
            isSelected: settings.locale.languageCode == 'en',
            onTap: () {
              settings.setLocale(const Locale('en'));
              Navigator.pop(ctx);
            },
          ),
          _LanguageOption(
            locale: const Locale('zh'),
            label: '中文 (Chinese)',
            isSelected: settings.locale.languageCode == 'zh',
            onTap: () {
              settings.setLocale(const Locale('zh'));
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Theme'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              settings.setThemeMode(ThemeMode.system);
              Navigator.pop(ctx);
            },
            child: ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('System'),
              trailing: settings.themeMode == ThemeMode.system
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              settings.setThemeMode(ThemeMode.light);
              Navigator.pop(ctx);
            },
            child: ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Light'),
              trailing: settings.themeMode == ThemeMode.light
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              settings.setThemeMode(ThemeMode.dark);
              Navigator.pop(ctx);
            },
            child: ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark'),
              trailing: settings.themeMode == ThemeMode.dark
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  String _localeName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'zh':
        return '中文 (Chinese)';
      default:
        return locale.languageCode;
    }
  }

  String _themeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final Locale locale;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.locale,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: onTap,
      child: ListTile(
        leading: Text(
          locale.languageCode == 'zh' ? '🇨🇳' : '🇬🇧',
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(label),
        trailing: isSelected
            ? const Icon(Icons.check, color: Colors.green)
            : null,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
