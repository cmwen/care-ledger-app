import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:care_ledger_app/features/ledger/presentation/ledger_provider.dart';
import 'package:care_ledger_app/features/ledger/presentation/widgets/week_summary_card.dart';
import 'package:care_ledger_app/features/ledger/presentation/widgets/entry_card.dart';
import 'package:care_ledger_app/features/ledger/presentation/widgets/quick_add_sheet.dart';
import 'package:care_ledger_app/features/ledger/presentation/widgets/edit_entry_sheet.dart';
import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';
import 'package:care_ledger_app/features/settings/presentation/settings_provider.dart';
import 'package:care_ledger_app/features/auto_capture/presentation/widgets/suggestion_banner.dart';

/// Ledger Home screen — the primary tab.
///
/// Shows current week summary, pending review count,
/// recent entries, and quick-add action.
class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LedgerProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!provider.hasLedger) {
          return _buildNoLedger(context);
        }

        final weekEntries = provider.thisWeekEntries;
        final allEntries = provider.entries;

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: provider.refreshEntries,
            child: CustomScrollView(
              slivers: [
                // Suggestion banner (shown when pending suggestions exist)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: SuggestionBanner(),
                  ),
                ),

                // Week summary card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: WeekSummaryCard(
                      weekEntries: weekEntries,
                      pendingReviewCount: provider.pendingReviewCount,
                      ledgerTitle: provider.activeLedger!.title,
                    ),
                  ),
                ),

                // Section header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'Recent Entries',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),

                // Entry list
                if (allEntries.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.note_add_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No entries yet',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to log your first care activity.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: EntryCard(
                          entry: allEntries[index],
                          onTap: () =>
                              _showEditEntry(context, allEntries[index]),
                        ),
                      ),
                      childCount: allEntries.length,
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showQuickAdd(context),
            tooltip: 'Add entry',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildNoLedger(BuildContext context) {
    final settings = context.read<SettingsProvider>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to Care Ledger',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Create a shared ledger to start tracking caregiving efforts between two participants.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                context.read<LedgerProvider>().createLedger(
                  title: 'Family Care Ledger',
                  participantAId: settings.currentUserId,
                  participantBId: settings.partnerId ?? 'partner-placeholder',
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Ledger'),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickAdd(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const QuickAddSheet(),
    );
  }

  void _showEditEntry(BuildContext context, CareEntry entry) {
    // Only allow editing entries that are in editable states
    if (entry.status == EntryStatus.needsReview ||
        entry.status == EntryStatus.needsEdit) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => EditEntrySheet(entry: entry),
      );
    }
  }
}
