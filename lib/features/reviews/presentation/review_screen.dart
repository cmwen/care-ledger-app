import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';
import 'package:care_ledger_app/features/ledger/presentation/ledger_provider.dart';
import 'package:care_ledger_app/features/reviews/presentation/review_provider.dart';
import 'package:care_ledger_app/features/reviews/presentation/widgets/review_entry_card.dart';
import 'package:care_ledger_app/features/settings/presentation/settings_provider.dart';
import 'package:care_ledger_app/features/auto_capture/presentation/auto_capture_provider.dart';
import 'package:care_ledger_app/features/auto_capture/presentation/draft_timeline_screen.dart';

/// Weekly Review Queue screen.
///
/// Shows entries needing action, grouped by day/category.
/// Supports bulk approve/reject and inline decision actions.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final Set<String> _selectedIds = {};
  bool _isMultiSelect = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final queue = provider.reviewQueue;

        if (queue.isEmpty) {
          return _buildEmptyOrSuggestionsOnly(context);
        }

        final grouped = provider.groupedByDay;
        final autoCaptureProvider = context.watch<AutoCaptureProvider>();

        return Scaffold(
          body: Column(
            children: [
              // Suggestions section at the top
              if (autoCaptureProvider.hasPendingSuggestions)
                _buildSuggestionsHeader(context, autoCaptureProvider),

              // Bulk action bar (when multi-selecting)
              if (_isMultiSelect) _buildBulkActionBar(context, provider),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final day = grouped.keys.elementAt(index);
                    final entries = grouped[day]!;
                    return _buildDayGroup(context, day, entries, provider);
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: queue.length > 1
              ? FloatingActionButton.extended(
                  onPressed: () {
                    setState(() {
                      _isMultiSelect = !_isMultiSelect;
                      if (!_isMultiSelect) _selectedIds.clear();
                    });
                  },
                  icon: Icon(_isMultiSelect ? Icons.close : Icons.checklist),
                  label: Text(_isMultiSelect ? 'Cancel' : 'Bulk Actions'),
                )
              : null,
        );
      },
    );
  }

  Widget _buildEmptyOrSuggestionsOnly(BuildContext context) {
    final autoCaptureProvider = context.watch<AutoCaptureProvider>();

    if (autoCaptureProvider.hasPendingSuggestions) {
      return Scaffold(
        body: Column(
          children: [
            _buildSuggestionsHeader(context, autoCaptureProvider),
            Expanded(child: _buildEmptyState(context)),
          ],
        ),
      );
    }

    return _buildEmptyState(context);
  }

  Widget _buildSuggestionsHeader(
    BuildContext context,
    AutoCaptureProvider autoCaptureProvider,
  ) {
    final theme = Theme.of(context);
    final count = autoCaptureProvider.pendingSuggestionCount;

    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DraftTimelineScreen()),
        ),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: theme.colorScheme.tertiary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activity Suggestions',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count pattern-based suggestion${count == 1 ? '' : 's'} ready for review',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onTertiaryContainer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'All caught up!',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Text(
              settings.isPaired
                  ? '${settings.partnerName} hasn\'t submitted any entries for your review.'
                  : 'No pending reviews. New entries will appear here when they need your attention.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkActionBar(BuildContext context, ReviewProvider provider) {
    final theme = Theme.of(context);
    final settings = context.read<SettingsProvider>();
    final ledgerProvider = context.read<LedgerProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Text('${_selectedIds.length} selected'),
          const Spacer(),
          TextButton.icon(
            onPressed: _selectedIds.isEmpty
                ? null
                : () async {
                    await provider.batchApprove(
                      entryIds: _selectedIds.toList(),
                      reviewerId: settings.currentUserId,
                    );
                    setState(() {
                      _selectedIds.clear();
                      _isMultiSelect = false;
                    });
                    if (mounted) {
                      await ledgerProvider.refreshEntries();
                    }
                  },
            icon: const Icon(Icons.check_circle, color: Colors.green),
            label: const Text('Approve'),
          ),
          TextButton.icon(
            onPressed: _selectedIds.isEmpty
                ? null
                : () => _showBulkRejectDialog(context, provider),
            icon: const Icon(Icons.cancel, color: Colors.red),
            label: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Widget _buildDayGroup(
    BuildContext context,
    DateTime day,
    List<CareEntry> entries,
    ReviewProvider provider,
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
        ...entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ReviewEntryCard(
              entry: entry,
              isSelected: _selectedIds.contains(entry.id),
              isMultiSelect: _isMultiSelect,
              onSelect: _isMultiSelect
                  ? () {
                      setState(() {
                        if (_selectedIds.contains(entry.id)) {
                          _selectedIds.remove(entry.id);
                        } else {
                          _selectedIds.add(entry.id);
                        }
                      });
                    }
                  : null,
              onApprove: () => _approveEntry(context, entry, provider),
              onReject: () => _showRejectDialog(context, entry, provider),
              onRequestEdit: () =>
                  _showEditRequestDialog(context, entry, provider),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _approveEntry(
    BuildContext context,
    CareEntry entry,
    ReviewProvider provider,
  ) async {
    final settings = context.read<SettingsProvider>();
    final ledgerProvider = context.read<LedgerProvider>();
    await provider.approveEntry(
      entryId: entry.id,
      reviewerId: settings.currentUserId,
    );
    if (mounted) {
      await ledgerProvider.refreshEntries();
    }
  }

  void _showRejectDialog(
    BuildContext context,
    CareEntry entry,
    ReviewProvider provider,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Entry'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason',
            hintText: 'Why are you rejecting this entry?',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final settings = context.read<SettingsProvider>();
              final ledgerProvider = context.read<LedgerProvider>();
              await provider.rejectEntry(
                entryId: entry.id,
                reviewerId: settings.currentUserId,
                reason: controller.text.trim(),
              );
              if (mounted) {
                await ledgerProvider.refreshEntries();
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showEditRequestDialog(
    BuildContext context,
    CareEntry entry,
    ReviewProvider provider,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Edits'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'What needs changing?',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final settings = context.read<SettingsProvider>();
              final ledgerProvider = context.read<LedgerProvider>();
              await provider.requestEdits(
                entryId: entry.id,
                reviewerId: settings.currentUserId,
                reason: controller.text.trim(),
              );
              if (mounted) {
                await ledgerProvider.refreshEntries();
              }
            },
            child: const Text('Request Edit'),
          ),
        ],
      ),
    );
  }

  void _showBulkRejectDialog(BuildContext context, ReviewProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject ${_selectedIds.length} entries'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason for all',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final settings = context.read<SettingsProvider>();
              final ledgerProvider = context.read<LedgerProvider>();
              await provider.batchReject(
                entryIds: _selectedIds.toList(),
                reviewerId: settings.currentUserId,
                reason: controller.text.trim(),
              );
              setState(() {
                _selectedIds.clear();
                _isMultiSelect = false;
              });
              if (mounted) {
                await ledgerProvider.refreshEntries();
              }
            },
            child: const Text('Reject All'),
          ),
        ],
      ),
    );
  }
}
