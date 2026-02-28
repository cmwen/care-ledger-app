import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:care_ledger_app/features/auto_capture/domain/capture_signal.dart';
import 'package:care_ledger_app/features/auto_capture/presentation/auto_capture_provider.dart';
import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';
import 'package:care_ledger_app/features/ledger/presentation/ledger_provider.dart';
import 'package:care_ledger_app/features/settings/presentation/settings_provider.dart';

/// Weekly Draft Timeline screen.
///
/// Shows the pre-filled "draft week" of auto-detected suggestions
/// for the user to review, accept, or dismiss.
class DraftTimelineScreen extends StatelessWidget {
  const DraftTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Week in Review')),
      body: Consumer<AutoCaptureProvider>(
        builder: (context, provider, _) {
          if (provider.isGenerating) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.suggestions.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildTimeline(context, provider);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No patterns detected yet',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            const Text(
              'As you log entries, we\'ll learn your routine and suggest '
              'activities automatically.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Ledger'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, AutoCaptureProvider provider) {
    final settings = context.read<SettingsProvider>();
    final ledgerProvider = context.read<LedgerProvider>();

    // Group suggestions by day.
    final grouped = <DateTime, List<CaptureSignal>>{};
    for (final signal in provider.suggestions) {
      final day = DateTime(
        signal.detectedAt.year,
        signal.detectedAt.month,
        signal.detectedAt.day,
      );
      grouped.putIfAbsent(day, () => []).add(signal);
    }
    final sortedDays = grouped.keys.toList()..sort();

    // Week range header.
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final dateRange =
        '${DateFormat.MMMd().format(weekStart)} – ${DateFormat.MMMd().format(weekEnd)}';

    return Column(
      children: [
        // Header.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Column(
            children: [
              Text(
                dateRange,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${provider.pendingSuggestionCount} suggestion${provider.pendingSuggestionCount == 1 ? '' : 's'} pending',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),

        // Timeline.
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sortedDays.length,
            itemBuilder: (context, index) {
              final day = sortedDays[index];
              final signals = grouped[day]!;
              return _buildDayGroup(
                context,
                day,
                signals,
                provider,
                settings,
                ledgerProvider,
              );
            },
          ),
        ),

        // Bottom action bar.
        if (provider.highConfidence.isNotEmpty)
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await provider.acceptAllHighConfidence(
                      ledgerId: ledgerProvider.activeLedger!.id,
                      authorId: settings.currentUserId,
                    );
                    if (context.mounted) {
                      await ledgerProvider.refreshEntries();
                    }
                  },
                  icon: const Icon(Icons.check_circle),
                  label: Text(
                    'Accept All High-Confidence (${provider.highConfidence.length})',
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDayGroup(
    BuildContext context,
    DateTime day,
    List<CaptureSignal> signals,
    AutoCaptureProvider provider,
    SettingsProvider settings,
    LedgerProvider ledgerProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            DateFormat.yMMMEd().format(day),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
          ),
        ),
        ...signals.map(
          (signal) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _SuggestionCard(
              signal: signal,
              state: provider.signalState(signal.id),
              onAccept: () async {
                await provider.acceptSuggestion(
                  signalId: signal.id,
                  ledgerId: ledgerProvider.activeLedger!.id,
                  authorId: settings.currentUserId,
                );
                if (context.mounted) {
                  await ledgerProvider.refreshEntries();
                }
              },
              onDismiss: () => provider.dismissSuggestion(signal.id),
            ),
          ),
        ),
      ],
    );
  }
}

/// Card displaying a single suggestion with actions.
class _SuggestionCard extends StatelessWidget {
  final CaptureSignal signal;
  final SuggestionState state;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const _SuggestionCard({
    required this.signal,
    required this.state,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActioned = state != SuggestionState.pending;

    return AnimatedOpacity(
      opacity: isActioned ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isActioned
                ? theme.colorScheme.outlineVariant
                : _confidenceColor(signal.confidence).withValues(alpha: 0.5),
            width: isActioned ? 0.5 : 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: category icon + description + confidence.
              Row(
                children: [
                  // Category icon.
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _categoryColor(
                        signal.suggestedCategory,
                      ).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _categoryIcon(signal.suggestedCategory),
                      color: _categoryColor(signal.suggestedCategory),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Description + time.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          signal.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            decoration: state == SuggestionState.dismissed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat.jm().format(signal.detectedAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Credits.
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${signal.suggestedCredits.toStringAsFixed(1)} cr',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _ConfidenceDots(confidence: signal.confidence),
                    ],
                  ),
                ],
              ),

              // Source hint.
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        signal.sourceHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Action state indicator or action buttons.
              if (isActioned)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        state == SuggestionState.accepted
                            ? Icons.check_circle
                            : Icons.cancel,
                        size: 16,
                        color: state == SuggestionState.accepted
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        state == SuggestionState.accepted
                            ? 'Accepted'
                            : 'Dismissed',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: state == SuggestionState.accepted
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onDismiss,
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Dismiss'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: onAccept,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Accept'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _confidenceColor(SignalConfidence confidence) {
    switch (confidence) {
      case SignalConfidence.high:
        return Colors.green;
      case SignalConfidence.medium:
        return Colors.orange;
      case SignalConfidence.low:
        return Colors.grey;
    }
  }

  IconData _categoryIcon(EntryCategory category) {
    switch (category) {
      case EntryCategory.driving:
        return Icons.directions_car;
      case EntryCategory.laundry:
        return Icons.local_laundry_service;
      case EntryCategory.childcare:
        return Icons.child_care;
      case EntryCategory.cooking:
        return Icons.restaurant;
      case EntryCategory.shopping:
        return Icons.shopping_cart;
      case EntryCategory.planning:
        return Icons.event_note;
      case EntryCategory.emotionalSupport:
        return Icons.favorite;
      case EntryCategory.housework:
        return Icons.home;
      case EntryCategory.medical:
        return Icons.medical_services;
      case EntryCategory.other:
        return Icons.more_horiz;
    }
  }

  Color _categoryColor(EntryCategory category) {
    switch (category) {
      case EntryCategory.driving:
        return Colors.blue;
      case EntryCategory.laundry:
        return Colors.cyan;
      case EntryCategory.childcare:
        return Colors.orange;
      case EntryCategory.cooking:
        return Colors.red;
      case EntryCategory.shopping:
        return Colors.green;
      case EntryCategory.planning:
        return Colors.purple;
      case EntryCategory.emotionalSupport:
        return Colors.pink;
      case EntryCategory.housework:
        return Colors.brown;
      case EntryCategory.medical:
        return Colors.teal;
      case EntryCategory.other:
        return Colors.grey;
    }
  }
}

/// Dot indicator for signal confidence.
///
/// ● ● ● = high, ● ● ○ = medium, ● ○ ○ = low
class _ConfidenceDots extends StatelessWidget {
  final SignalConfidence confidence;

  const _ConfidenceDots({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final filledCount = switch (confidence) {
      SignalConfidence.high => 3,
      SignalConfidence.medium => 2,
      SignalConfidence.low => 1,
    };

    final color = switch (confidence) {
      SignalConfidence.high => Colors.green,
      SignalConfidence.medium => Colors.orange,
      SignalConfidence.low => Colors.grey,
    };

    return Tooltip(
      message: '${confidence.name} confidence',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final isFilled = i < filledCount;
          return Padding(
            padding: EdgeInsets.only(left: i > 0 ? 2 : 0),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? color : color.withValues(alpha: 0.25),
              ),
            ),
          );
        }),
      ),
    );
  }
}
