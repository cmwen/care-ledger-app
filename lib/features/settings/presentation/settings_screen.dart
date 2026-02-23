import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:care_ledger_app/features/ledger/presentation/ledger_provider.dart';

/// Settings screen — MVP-minimal.
///
/// Shows participant info, sync health placeholder,
/// and basic app settings.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<LedgerProvider>(
      builder: (context, provider, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Participants section
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Participants', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    if (provider.hasLedger) ...[
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: const Text('A'),
                        ),
                        title: const Text('Participant A'),
                        subtitle: Text(
                          provider.activeLedger!.participantAId,
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: Chip(
                          label: const Text('You'),
                          labelStyle: const TextStyle(fontSize: 11),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: theme.colorScheme.primaryContainer,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          child: const Text('B'),
                        ),
                        title: const Text('Participant B'),
                        subtitle: Text(
                          provider.activeLedger!.participantBId,
                          style: theme.textTheme.bodySmall,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ] else
                      const Text('No active ledger'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sync health section
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sync Status', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Local mode (sync not yet enabled)'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All data is stored locally on this device.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ledger info
            if (provider.hasLedger)
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ledger', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Title',
                        value: provider.activeLedger!.title,
                      ),
                      _InfoRow(
                        label: 'Status',
                        value: provider.activeLedger!.status.label,
                      ),
                      _InfoRow(
                        label: 'Total entries',
                        value: '${provider.entries.length}',
                      ),
                      _InfoRow(
                        label: 'Confirmed',
                        value: '${provider.confirmedEntries.length}',
                      ),
                    ],
                  ),
                ),
              ),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
