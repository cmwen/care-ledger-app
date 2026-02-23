import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';
import 'package:care_ledger_app/features/ledger/presentation/ledger_provider.dart';

/// Timeline screen — read-first history of all entries.
///
/// Shows entries with day/week toggle, participant filter,
/// and status/category markers.
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  bool _showWeekView = false;
  String? _participantFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<LedgerProvider>(
      builder: (context, provider, _) {
        if (!provider.hasLedger) {
          return const Center(child: Text('No active ledger'));
        }

        var entries = provider.entries;

        // Apply participant filter
        if (_participantFilter != null) {
          entries = entries
              .where((e) => e.authorId == _participantFilter)
              .toList();
        }

        return Column(
          children: [
            // Filter bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // View toggle
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Day')),
                      ButtonSegment(value: true, label: Text('Week')),
                    ],
                    selected: {_showWeekView},
                    onSelectionChanged: (v) =>
                        setState(() => _showWeekView = v.first),
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const Spacer(),

                  // Participant filter
                  PopupMenuButton<String?>(
                    icon: Icon(
                      Icons.filter_list,
                      color: _participantFilter != null
                          ? theme.colorScheme.primary
                          : null,
                    ),
                    onSelected: (value) =>
                        setState(() => _participantFilter = value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: null,
                        child: Text('All participants'),
                      ),
                      PopupMenuItem(
                        value: provider.activeLedger!.participantAId,
                        child: const Text('Participant A'),
                      ),
                      PopupMenuItem(
                        value: provider.activeLedger!.participantBId,
                        child: const Text('Participant B'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Timeline
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timeline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No entries to show',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : _showWeekView
                      ? _buildWeekView(context, entries)
                      : _buildDayView(context, entries),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDayView(BuildContext context, List<CareEntry> entries) {
    final grouped = <DateTime, List<CareEntry>>{};
    for (final entry in entries) {
      final day = DateTime(
        entry.occurredAt.year,
        entry.occurredAt.month,
        entry.occurredAt.day,
      );
      grouped.putIfAbsent(day, () => []).add(entry);
    }

    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final dayEntries = grouped[day]!;
        return _TimelineDayGroup(day: day, entries: dayEntries);
      },
    );
  }

  Widget _buildWeekView(BuildContext context, List<CareEntry> entries) {
    final grouped = <DateTime, List<CareEntry>>{};
    for (final entry in entries) {
      final weekStart = entry.occurredAt
          .subtract(Duration(days: entry.occurredAt.weekday - 1));
      final key = DateTime(weekStart.year, weekStart.month, weekStart.day);
      grouped.putIfAbsent(key, () => []).add(entry);
    }

    final weeks = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: weeks.length,
      itemBuilder: (context, index) {
        final weekStart = weeks[index];
        final weekEnd = weekStart.add(const Duration(days: 6));
        final weekEntries = grouped[weekStart]!;
        final totalCredits = weekEntries.fold<double>(
          0,
          (sum, e) => sum + e.creditsProposed,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${DateFormat.MMMd().format(weekStart)} - ${DateFormat.MMMd().format(weekEnd)}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    Text(
                      '${weekEntries.length} entries · ${totalCredits.toStringAsFixed(1)} cr',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: weekEntries.map((e) {
                    return Chip(
                      label: Text(e.category.label),
                      visualDensity: VisualDensity.compact,
                      labelStyle: const TextStyle(fontSize: 11),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimelineDayGroup extends StatelessWidget {
  final DateTime day;
  final List<CareEntry> entries;

  const _TimelineDayGroup({required this.day, required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = _isToday(day);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isToday ? 'Today' : DateFormat.yMMMEd().format(day),
            style: theme.textTheme.labelLarge?.copyWith(
              color: isToday ? theme.colorScheme.primary : Colors.grey[600],
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 8),
          ...entries.map((entry) => _TimelineItem(entry: entry)),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _TimelineItem extends StatelessWidget {
  final CareEntry entry;

  const _TimelineItem({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _statusColor(entry.status),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.description,
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${entry.creditsProposed.toStringAsFixed(1)} cr',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(EntryStatus status) {
    switch (status) {
      case EntryStatus.needsReview:
        return Colors.amber;
      case EntryStatus.pendingCounterpartyReview:
        return Colors.blue;
      case EntryStatus.confirmed:
        return Colors.green;
      case EntryStatus.needsEdit:
        return Colors.orange;
      case EntryStatus.rejected:
        return Colors.red;
    }
  }
}
