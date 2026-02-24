import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:care_ledger_app/features/ledger/presentation/ledger_screen.dart';
import 'package:care_ledger_app/features/ledger/presentation/ledger_provider.dart';
import 'package:care_ledger_app/features/reviews/presentation/review_screen.dart';
import 'package:care_ledger_app/features/reviews/presentation/review_provider.dart';
import 'package:care_ledger_app/features/timeline/presentation/timeline_screen.dart';
import 'package:care_ledger_app/features/balance/presentation/balance_screen.dart';
import 'package:care_ledger_app/features/balance/presentation/balance_provider.dart';
import 'package:care_ledger_app/features/settings/presentation/settings_screen.dart';

/// Main navigation shell with bottom tab bar.
///
/// Primary navigation (from design):
/// 1. Ledger
/// 2. Review
/// 3. Timeline
/// 4. Balance
/// 5. Settings
class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _currentIndex = 0;

  static const _screens = [
    LedgerScreen(),
    ReviewScreen(),
    TimelineScreen(),
    BalanceScreen(),
    SettingsScreen(),
  ];

  static const _titles = [
    'Ledger',
    'Review',
    'Timeline',
    'Balance',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final ledgerProvider = context.read<LedgerProvider>();
    await ledgerProvider.loadActiveLedger();

    if (ledgerProvider.hasLedger && mounted) {
      final reviewProvider = context.read<ReviewProvider>();
      final balanceProvider = context.read<BalanceProvider>();

      await Future.wait([
        reviewProvider.loadReviewQueue(ledgerProvider.activeLedger!.id),
        balanceProvider.refreshBalance(ledgerProvider.activeLedger!),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ledgerProvider = context.watch<LedgerProvider>();
    final reviewProvider = context.watch<ReviewProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ledgerProvider.hasLedger
              ? ledgerProvider.activeLedger!.title
              : _titles[_currentIndex],
        ),
        actions: [
          // Sync indicator placeholder
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              Icons.cloud_off,
              size: 18,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) async {
          setState(() => _currentIndex = index);

          // Refresh data when switching tabs
          if (ledgerProvider.hasLedger) {
            switch (index) {
              case 0:
                await ledgerProvider.refreshEntries();
              case 1:
                await context.read<ReviewProvider>().loadReviewQueue(
                  ledgerProvider.activeLedger!.id,
                );
              case 3:
                await context.read<BalanceProvider>().refreshBalance(
                  ledgerProvider.activeLedger!,
                );
            }
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Ledger',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: reviewProvider.queueCount > 0,
              label: Text('${reviewProvider.queueCount}'),
              child: const Icon(Icons.inbox_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: reviewProvider.queueCount > 0,
              label: Text('${reviewProvider.queueCount}'),
              child: const Icon(Icons.inbox),
            ),
            label: 'Review',
          ),
          const NavigationDestination(
            icon: Icon(Icons.timeline_outlined),
            selectedIcon: Icon(Icons.timeline),
            label: 'Timeline',
          ),
          const NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Balance',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
