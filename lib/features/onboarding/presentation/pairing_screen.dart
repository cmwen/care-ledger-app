import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:care_ledger_app/features/settings/presentation/settings_provider.dart';

/// Two-tab pairing screen shown after onboarding.
///
/// - **Create Ledger** tab: shows the invite code for sharing.
/// - **Join Ledger** tab: lets the user enter a partner's invite code.
///
/// Both tabs include a "Skip for now" option that loads demo data.
class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _codeController = TextEditingController();
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pair with Partner'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Create Ledger'),
            Tab(text: 'Join Ledger'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Create Ledger ──
          _buildCreateTab(context, theme, settings),

          // ── Tab 2: Join Ledger ──
          _buildJoinTab(context, theme, settings),
        ],
      ),
    );
  }

  Widget _buildCreateTab(
    BuildContext context,
    ThemeData theme,
    SettingsProvider settings,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_add_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),

            Text(
              'Share this code with your partner',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Invite code display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SelectableText(
                settings.inviteCode,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Copy button
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: settings.inviteCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invite code copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy Code'),
            ),
            const SizedBox(height: 32),

            // Waiting state
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Waiting for partner...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // Skip for now
            TextButton(
              onPressed: () => _skipPairing(context, settings),
              child: const Text('Skip for now — use demo data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinTab(
    BuildContext context,
    ThemeData theme,
    SettingsProvider settings,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.link_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),

            Text(
              'Enter your partner\'s invite code',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Code entry field
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Invite code',
                hintText: 'e.g. ABC123',
                prefixIcon: Icon(Icons.vpn_key_outlined),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Join button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed:
                    _codeController.text.trim().length >= 4 && !_isJoining
                    ? () => _joinLedger(context, settings)
                    : null,
                child: _isJoining
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Join'),
              ),
            ),
            const SizedBox(height: 32),

            Text(
              'For this preview, entering any code will\n'
              'pair you with a demo partner.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Skip for now
            TextButton(
              onPressed: () => _skipPairing(context, settings),
              child: const Text('Skip for now — use demo data'),
            ),
          ],
        ),
      ),
    );
  }

  /// Simulate joining a ledger with a demo partner.
  Future<void> _joinLedger(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    setState(() => _isJoining = true);

    final navigator = Navigator.of(context);

    // MVP: simulate pairing with a preset partner.
    await settings.completePairing('Partner', 'demo-partner-joined');

    if (mounted) {
      // Pop back to root; main.dart rebuilds to NavigationShell.
      navigator.popUntil((route) => route.isFirst);
    }
  }

  /// Skip pairing and enter the app with demo data.
  Future<void> _skipPairing(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final navigator = Navigator.of(context);

    await settings.completePairing('Partner', 'demo-partner');

    if (mounted) {
      navigator.popUntil((route) => route.isFirst);
    }
  }
}
