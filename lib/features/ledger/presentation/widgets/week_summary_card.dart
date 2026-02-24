import 'package:flutter/material.dart';
import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';

/// Summary card for the current week displayed at top of Ledger screen.
class WeekSummaryCard extends StatelessWidget {
  final List<CareEntry> weekEntries;
  final int pendingReviewCount;
  final String ledgerTitle;

  const WeekSummaryCard({
    super.key,
    required this.weekEntries,
    required this.pendingReviewCount,
    required this.ledgerTitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confirmedCount = weekEntries.where((e) => e.isConfirmed).length;
    final totalCredits = weekEntries
        .where((e) => e.isConfirmed)
        .fold<double>(
          0,
          (sum, e) => sum + (e.creditsConfirmed ?? e.creditsProposed),
        );

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'This Week',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatItem(
                  label: 'Entries',
                  value: '${weekEntries.length}',
                  icon: Icons.list_alt,
                ),
                const SizedBox(width: 24),
                _StatItem(
                  label: 'Confirmed',
                  value: '$confirmedCount',
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(width: 24),
                _StatItem(
                  label: 'Credits',
                  value: totalCredits.toStringAsFixed(1),
                  icon: Icons.stars_outlined,
                ),
              ],
            ),
            if (pendingReviewCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$pendingReviewCount entries need review',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
