import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:care_ledger_app/features/auto_capture/presentation/auto_capture_provider.dart';
import 'package:care_ledger_app/features/auto_capture/presentation/draft_timeline_screen.dart';

/// A compact, dismissible banner shown on the Ledger screen
/// when there are pending auto-capture suggestions.
///
/// Tapping the banner navigates to [DraftTimelineScreen].
class SuggestionBanner extends StatefulWidget {
  const SuggestionBanner({super.key});

  @override
  State<SuggestionBanner> createState() => _SuggestionBannerState();
}

class _SuggestionBannerState extends State<SuggestionBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return Consumer<AutoCaptureProvider>(
      builder: (context, provider, _) {
        final count = provider.pendingSuggestionCount;
        if (count == 0) return const SizedBox.shrink();

        final theme = Theme.of(context);

        return Dismissible(
          key: const ValueKey('suggestion-banner'),
          direction: DismissDirection.horizontal,
          onDismissed: (_) => setState(() => _dismissed = true),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 0,
              color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DraftTimelineScreen(),
                  ),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: theme.colorScheme.tertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$count activity suggestion${count == 1 ? '' : 's'} ready for review',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onTertiaryContainer,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
