import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';
import 'package:care_ledger_app/features/ledger/presentation/ledger_provider.dart';
import 'package:care_ledger_app/features/settings/presentation/settings_provider.dart';

/// Timeline screen — read-first history of all entries.
///
/// Shows entries with day/week toggle, participant filter,
/// category icons, color-coded timeline connectors, and visual richness.
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
                      ButtonSegment(
                        value: false,
                        label: Text('Day'),
                        icon: Icon(Icons.view_day, size: 18),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Week'),
                        icon: Icon(Icons.view_week, size: 18),
                      ),
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
                    itemBuilder: (context) {
                      final settings = context.read<SettingsProvider>();
                      return [
                        const PopupMenuItem(
                          value: null,
                          child: Text('All participants'),
                        ),
                        ...settings.participantList.map(
                          (p) => PopupMenuItem(
                            value: p.id,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor:
                                      p.id == settings.currentUserId
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.tertiary,
                                  child: Text(
                                    p.initial,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: p.id == settings.currentUserId
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onTertiary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  p.id == settings.currentUserId
                                      ? 'Your entries'
                                      : p.name,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
            ),

            // Stats bar
            if (entries.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: _TimelineStats(entries: entries),
              ),

            // Timeline
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timeline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _emptyStateText(context),
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
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

  String _emptyStateText(BuildContext context) {
    if (_participantFilter != null) {
      final settings = context.read<SettingsProvider>();
      if (_participantFilter == settings.currentUserId) {
        return 'No entries from you yet';
      }
      return 'No entries from ${settings.partnerName}';
    }
    return 'No entries to show';
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
      final weekStart = entry.occurredAt.subtract(
        Duration(days: entry.occurredAt.weekday - 1),
      );
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
        final confirmedCount = weekEntries.where((e) => e.isConfirmed).length;

        // Category breakdown
        final categoryCount = <EntryCategory, int>{};
        for (final e in weekEntries) {
          categoryCount[e.category] = (categoryCount[e.category] ?? 0) + 1;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.date_range, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat.MMMd().format(weekStart)} – ${DateFormat.MMMd().format(weekEnd)}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${totalCredits.toStringAsFixed(1)} cr',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniStat(
                      icon: Icons.list_alt,
                      label: '${weekEntries.length} entries',
                    ),
                    const SizedBox(width: 16),
                    _MiniStat(
                      icon: Icons.check_circle,
                      label: '$confirmedCount confirmed',
                      color: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Category breakdown visual
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: categoryCount.entries.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _categoryColor(e.key).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _categoryIcon(e.key),
                            size: 14,
                            color: _categoryColor(e.key),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${e.key.label} ×${e.value}',
                            style: TextStyle(
                              fontSize: 11,
                              color: _categoryColor(e.key),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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

/// Compact stats bar at the top of the timeline.
class _TimelineStats extends StatelessWidget {
  final List<CareEntry> entries;

  const _TimelineStats({required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCredits = entries.fold<double>(
      0,
      (sum, e) => sum + e.creditsProposed,
    );
    final confirmedCount = entries.where((e) => e.isConfirmed).length;
    final pendingCount = entries.where((e) => e.isPending).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MiniStat(icon: Icons.list_alt, label: '${entries.length} total'),
          _MiniStat(
            icon: Icons.check_circle_outline,
            label: '$confirmedCount confirmed',
            color: Colors.green,
          ),
          _MiniStat(
            icon: Icons.pending_outlined,
            label: '$pendingCount pending',
            color: Colors.orange,
          ),
          _MiniStat(
            icon: Icons.stars_outlined,
            label: '${totalCredits.toStringAsFixed(1)} cr',
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MiniStat({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.grey[600]!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w500),
        ),
      ],
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
    final totalCredits = entries.fold<double>(
      0,
      (sum, e) => sum + e.creditsProposed,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isToday
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isToday ? 'Today' : DateFormat.MMMEd().format(day),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isToday
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${entries.length} entries · ${totalCredits.toStringAsFixed(1)} cr',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Entries with timeline connector
          ...List.generate(entries.length, (index) {
            return _TimelineItem(
              entry: entries[index],
              isLast: index == entries.length - 1,
            );
          }),
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
  final bool isLast;

  const _TimelineItem({required this.entry, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final catColor = _categoryColor(entry.category);
    final isCurrentUser = entry.authorId == settings.currentUserId;
    final dotColor = isCurrentUser
        ? theme.colorScheme.primary
        : theme.colorScheme.tertiary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline connector line + dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Dot with ownership color
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    border: Border.all(
                      color: dotColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                ),
                // Connector line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Entry content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Category icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _categoryIcon(entry.category),
                      color: catColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              settings.perspectiveName(entry.authorId),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                            if (entry.durationMinutes != null) ...[
                              Text(
                                ' · ',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              Icon(
                                Icons.timer_outlined,
                                size: 11,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${entry.durationMinutes}m',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                            Text(
                              ' · ',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            Text(
                              DateFormat.jm().format(entry.occurredAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Credits + status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${entry.creditsProposed.toStringAsFixed(1)} cr',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _statusColor(entry.status),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
