import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:care_ledger_app/features/ledger/presentation/ledger_provider.dart';
import 'package:care_ledger_app/features/settings/presentation/settings_provider.dart';
import 'package:care_ledger_app/sync/infrastructure/export_sync_service.dart';
import 'package:care_ledger_app/sync/presentation/sync_provider.dart';

/// Screen for exporting and importing sync bundles.
///
/// Accessible from the Settings screen's "Sync Status" card.
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _importController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshCount();
  }

  void _refreshCount() {
    final ledger = context.read<LedgerProvider>().activeLedger;
    if (ledger != null) {
      context.read<SyncProvider>().refreshEventCount(ledger.id);
    }
  }

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sync Data')),
      body: Consumer3<SyncProvider, LedgerProvider, SettingsProvider>(
        builder: (context, sync, ledger, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Export section ──
              _SectionHeader(
                title: 'Share Your Updates',
                icon: Icons.upload_rounded,
              ),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event_note,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${sync.localEventCount} events to share',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              ledger.hasLedger &&
                                  sync.status != SyncStatus.exporting
                              ? () => sync.exportEvents(
                                  ledgerId: ledger.activeLedger!.id,
                                  senderId: settings.currentUserId,
                                  senderName:
                                      settings.currentUser?.name ?? 'Unknown',
                                )
                              : null,
                          icon: sync.status == SyncStatus.exporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.ios_share, size: 18),
                          label: Text(
                            sync.status == SyncStatus.exporting
                                ? 'Generating...'
                                : 'Generate Export',
                          ),
                        ),
                      ),
                      if (sync.lastExportData != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            sync.lastExportData!,
                            maxLines: 6,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: sync.lastExportData!),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Copied to clipboard'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Copy to Clipboard'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Import section ──
              _SectionHeader(
                title: "Receive Partner's Updates",
                icon: Icons.download_rounded,
              ),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _importController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText:
                              "Paste your partner's export bundle here...",
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.paste, size: 20),
                            onPressed: () async {
                              final data = await Clipboard.getData(
                                'text/plain',
                              );
                              if (data?.text != null) {
                                _importController.text = data!.text!;
                              }
                            },
                          ),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              sync.status != SyncStatus.importing &&
                                  _importController.text.trim().isNotEmpty
                              ? () async {
                                  await sync.importEvents(
                                    _importController.text.trim(),
                                  );
                                  _refreshCount();
                                }
                              : null,
                          icon: sync.status == SyncStatus.importing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.download_done, size: 18),
                          label: Text(
                            sync.status == SyncStatus.importing
                                ? 'Importing...'
                                : 'Import',
                          ),
                        ),
                      ),
                      // Import result
                      if (sync.lastImportResult != null) ...[
                        const SizedBox(height: 12),
                        _ImportResultCard(result: sync.lastImportResult!),
                      ],
                      // Error display
                      if (sync.status == SyncStatus.error &&
                          sync.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: theme.colorScheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  sync.errorMessage!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── LAN Sync stub section ──
              _SectionHeader(
                title: 'Auto-Sync (Coming Soon)',
                icon: Icons.wifi,
              ),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.wifi_off,
                            size: 20,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Automatic sync over local WiFi is coming '
                              'in a future update.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'For now, use the export/import above to share '
                        'data with your partner.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Private widgets ──

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

class _ImportResultCard extends StatelessWidget {
  final SyncImportResult result;

  const _ImportResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.hasConflicts
            ? theme.colorScheme.tertiaryContainer
            : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.hasConflicts
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle,
                color: result.hasConflicts ? Colors.orange : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Imported ${result.newEventsCount} new event'
                  '${result.newEventsCount == 1 ? '' : 's'}'
                  ' from ${result.senderName}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (result.hasConflicts) ...[
            const SizedBox(height: 8),
            Text(
              '${result.conflicts.length} conflict'
              '${result.conflicts.length == 1 ? '' : 's'}'
              ' detected:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange[800],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            ...result.conflicts.map(
              (c) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text(
                  '• Entity ${c.entityId.substring(0, 8)}... — ${c.resolution}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
