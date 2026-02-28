// Basic widget test for the Care Ledger app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:care_ledger_app/app/theme.dart';
import 'package:care_ledger_app/app/navigation_shell.dart';
import 'package:care_ledger_app/core/identity_service.dart';
import 'package:care_ledger_app/features/ledger/infrastructure/ledger_repository.dart';
import 'package:care_ledger_app/features/ledger/infrastructure/care_entry_repository.dart';
import 'package:care_ledger_app/features/reviews/infrastructure/review_repository.dart';
import 'package:care_ledger_app/features/settlements/infrastructure/settlement_repository.dart';
import 'package:care_ledger_app/features/ledger/application/ledger_service.dart';
import 'package:care_ledger_app/features/reviews/application/review_service.dart';
import 'package:care_ledger_app/features/balance/application/balance_service.dart';
import 'package:care_ledger_app/features/settlements/application/settlement_service.dart';
import 'package:care_ledger_app/features/ledger/presentation/ledger_provider.dart';
import 'package:care_ledger_app/features/reviews/presentation/review_provider.dart';
import 'package:care_ledger_app/features/balance/presentation/balance_provider.dart';
import 'package:care_ledger_app/features/settings/presentation/settings_provider.dart';
import 'package:care_ledger_app/features/auto_capture/application/auto_capture_service.dart';
import 'package:care_ledger_app/features/auto_capture/presentation/auto_capture_provider.dart';

void main() {
  testWidgets('App loads and shows navigation bar', (
    WidgetTester tester,
  ) async {
    // Mock SharedPreferences with an onboarded + paired user
    SharedPreferences.setMockInitialValues({
      'cl_device_id': 'test-device-id',
      'cl_user_name': 'Test User',
      'cl_is_onboarded': true,
      'cl_partner_id': 'test-partner-id',
      'cl_partner_name': 'Test Partner',
      'cl_is_paired': true,
      'cl_invite_code': 'ABC123',
    });
    final identity = await IdentityService.create();

    // Set up dependencies
    final ledgerRepo = InMemoryLedgerRepository();
    final entryRepo = InMemoryCareEntryRepository();
    final reviewRepo = InMemoryReviewRepository();
    final settlementRepo = InMemorySettlementRepository();

    final ledgerService = LedgerService(
      ledgerRepo: ledgerRepo,
      entryRepo: entryRepo,
    );
    final reviewService = ReviewService(
      entryRepo: entryRepo,
      reviewRepo: reviewRepo,
    );
    final balanceService = BalanceService(
      entryRepo: entryRepo,
      settlementRepo: settlementRepo,
    );
    final settlementService = SettlementService(settlementRepo: settlementRepo);
    final autoCaptureService = AutoCaptureService(entryRepo: entryRepo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => SettingsProvider(identity: identity),
          ),
          ChangeNotifierProvider(
            create: (_) => LedgerProvider(service: ledgerService),
          ),
          ChangeNotifierProvider(
            create: (_) => ReviewProvider(service: reviewService),
          ),
          ChangeNotifierProvider(
            create: (_) => BalanceProvider(
              balanceService: balanceService,
              settlementService: settlementService,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => AutoCaptureProvider(
              service: autoCaptureService,
              entryRepo: entryRepo,
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NavigationShell(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify bottom navigation bar is present with all tabs
    expect(find.text('Ledger'), findsWidgets);
    expect(find.text('Review'), findsWidgets);
    expect(find.text('Timeline'), findsWidgets);
    expect(find.text('Balance'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);

    // Verify welcome screen shows when no ledger exists
    expect(find.text('Welcome to Care Ledger'), findsOneWidget);
    expect(find.text('Create Ledger'), findsOneWidget);
  });
}
