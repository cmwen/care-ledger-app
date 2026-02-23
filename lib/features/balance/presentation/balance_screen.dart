import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:care_ledger_app/features/ledger/presentation/ledger_provider.dart';
import 'package:care_ledger_app/features/balance/presentation/balance_provider.dart';
import 'package:care_ledger_app/features/settlements/domain/settlement.dart';

/// Balance & Settlements screen.
///
/// Shows confirmed contribution totals, net balance,
/// pending credits, and settlement lifecycle.
class BalanceScreen extends StatelessWidget {
  const BalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer2<LedgerProvider, BalanceProvider>(
      builder: (context, ledgerProvider, balanceProvider, _) {
        if (!ledgerProvider.hasLedger) {
          return const Center(child: Text('No active ledger'));
        }

        if (balanceProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final balance = balanceProvider.balance;
        final settlements = balanceProvider.settlements;

        return RefreshIndicator(
          onRefresh: () => balanceProvider.refreshBalance(
            ledgerProvider.activeLedger!,
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Balance overview card
              if (balance != null) ...[
                _BalanceOverviewCard(
                  participantAId: balance.participantA.participantId,
                  participantACredits: balance.participantA.confirmedCredits,
                  participantBId: balance.participantB.participantId,
                  participantBCredits: balance.participantB.confirmedCredits,
                  netBalance: balance.netBalance,
                  creditorId: balance.creditorId,
                  debtorId: balance.debtorId,
                ),
                const SizedBox(height: 16),

                // Pending credits
                if (balance.participantA.pendingCredits > 0 ||
                    balance.participantB.pendingCredits > 0)
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pending Credits',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _PendingItem(
                                label: 'Participant A',
                                credits: balance.participantA.pendingCredits,
                                count: balance.participantA.pendingEntryCount,
                              ),
                              _PendingItem(
                                label: 'Participant B',
                                credits: balance.participantB.pendingCredits,
                                count: balance.participantB.pendingEntryCount,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],

              // Settlement proposal CTA
              FilledButton.tonal(
                onPressed: () => _showSettlementDialog(context),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.handshake),
                    SizedBox(width: 8),
                    Text('Propose Settlement'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Settlement history
              if (settlements.isNotEmpty) ...[
                Text('Settlements', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ...settlements.map(
                  (s) => _SettlementCard(
                    settlement: s,
                    onAccept: s.status == SettlementStatus.proposed
                        ? () => balanceProvider.respondToSettlement(
                              settlementId: s.id,
                              accept: true,
                              ledger: ledgerProvider.activeLedger,
                            )
                        : null,
                    onReject: s.status == SettlementStatus.proposed
                        ? () => balanceProvider.respondToSettlement(
                              settlementId: s.id,
                              accept: false,
                              ledger: ledgerProvider.activeLedger,
                            )
                        : null,
                    onComplete: s.status == SettlementStatus.accepted
                        ? () => balanceProvider.completeSettlement(
                              settlementId: s.id,
                              ledger: ledgerProvider.activeLedger!,
                            )
                        : null,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showSettlementDialog(BuildContext context) {
    final creditsController = TextEditingController();
    final noteController = TextEditingController();
    var selectedMethod = SettlementMethod.cash;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Propose Settlement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: creditsController,
                decoration: const InputDecoration(
                  labelText: 'Credits',
                  border: OutlineInputBorder(),
                  suffixText: 'cr',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SettlementMethod>(
                initialValue: selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Method',
                  border: OutlineInputBorder(),
                ),
                items: SettlementMethod.values
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.label),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() => selectedMethod = v);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final credits = double.tryParse(creditsController.text);
                if (credits == null || credits <= 0) return;
                final ledgerProvider = context.read<LedgerProvider>();
                context.read<BalanceProvider>().proposeSettlement(
                      ledgerId: ledgerProvider.activeLedger!.id,
                      proposerId:
                          ledgerProvider.activeLedger!.participantAId,
                      method: selectedMethod,
                      credits: credits,
                      note: noteController.text.isNotEmpty
                          ? noteController.text
                          : null,
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Propose'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceOverviewCard extends StatelessWidget {
  final String participantAId;
  final double participantACredits;
  final String participantBId;
  final double participantBCredits;
  final double netBalance;
  final String? creditorId;
  final String? debtorId;

  const _BalanceOverviewCard({
    required this.participantAId,
    required this.participantACredits,
    required this.participantBId,
    required this.participantBCredits,
    required this.netBalance,
    required this.creditorId,
    required this.debtorId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Balance Overview',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Participant A',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      participantACredits.toStringAsFixed(1),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'confirmed credits',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Participant B',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      participantBCredits.toStringAsFixed(1),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'confirmed credits',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                creditorId == null
                    ? 'Balanced!'
                    : 'Net: ${netBalance.abs().toStringAsFixed(1)} cr',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingItem extends StatelessWidget {
  final String label;
  final double credits;
  final int count;

  const _PendingItem({
    required this.label,
    required this.credits,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        Text(
          '${credits.toStringAsFixed(1)} cr',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$count entries',
          style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }
}

class _SettlementCard extends StatelessWidget {
  final Settlement settlement;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onComplete;

  const _SettlementCard({
    required this.settlement,
    this.onAccept,
    this.onReject,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _methodIcon(settlement.method),
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${settlement.credits.toStringAsFixed(1)} cr via ${settlement.method.label}',
                  style: theme.textTheme.bodyLarge,
                ),
                const Spacer(),
                Chip(
                  label: Text(settlement.status.label),
                  labelStyle: const TextStyle(fontSize: 11),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (settlement.note != null) ...[
              const SizedBox(height: 8),
              Text(
                settlement.note!,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
            if (onAccept != null || onReject != null || onComplete != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onReject != null)
                    OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Reject'),
                    ),
                  if (onAccept != null) ...[
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onAccept,
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Accept'),
                    ),
                  ],
                  if (onComplete != null)
                    FilledButton(
                      onPressed: onComplete,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Mark Completed'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _methodIcon(SettlementMethod method) {
    switch (method) {
      case SettlementMethod.cash:
        return Icons.payments;
      case SettlementMethod.bankTransfer:
        return Icons.account_balance;
      case SettlementMethod.reciprocal:
        return Icons.swap_horiz;
      case SettlementMethod.other:
        return Icons.more_horiz;
    }
  }
}
