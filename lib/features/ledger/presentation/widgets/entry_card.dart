import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';
import 'package:care_ledger_app/features/settings/presentation/settings_provider.dart';

/// Card displaying a single care entry in the ledger list.
class EntryCard extends StatelessWidget {
  final CareEntry entry;
  final VoidCallback? onTap;

  const EntryCard({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _categoryColor(entry.category).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _categoryIcon(entry.category),
                  color: _categoryColor(entry.category),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Entry details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.description,
                      style: theme.textTheme.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Author avatar
                        CircleAvatar(
                          radius: 8,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          child: Text(
                            settings
                                .participantName(entry.authorId)
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(fontSize: 8),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            settings.participantName(entry.authorId),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('·', style: TextStyle(color: Colors.grey[400])),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat.MMMd().format(entry.occurredAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        if (entry.durationMinutes != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.timer_outlined,
                            size: 12,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${entry.durationMinutes}m',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                        if (entry.sourceType != SourceType.manual) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: theme.colorScheme.tertiary,
                          ),
                        ],
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
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _StatusChip(status: entry.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

class _StatusChip extends StatelessWidget {
  final EntryStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 12, color: _statusColor(status)),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              color: _statusColor(status),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(EntryStatus status) {
    switch (status) {
      case EntryStatus.needsReview:
        return Icons.pending;
      case EntryStatus.pendingCounterpartyReview:
        return Icons.hourglass_bottom;
      case EntryStatus.confirmed:
        return Icons.check_circle;
      case EntryStatus.needsEdit:
        return Icons.edit;
      case EntryStatus.rejected:
        return Icons.cancel;
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
}
