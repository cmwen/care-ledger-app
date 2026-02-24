import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:care_ledger_app/app/theme.dart';
import 'package:care_ledger_app/app/navigation_shell.dart';
import 'package:care_ledger_app/data/seed_data.dart';
import 'package:care_ledger_app/l10n/app_localizations.dart';

// Repositories
import 'package:care_ledger_app/features/ledger/infrastructure/ledger_repository.dart';
import 'package:care_ledger_app/features/ledger/infrastructure/care_entry_repository.dart';
import 'package:care_ledger_app/features/reviews/infrastructure/review_repository.dart';
import 'package:care_ledger_app/features/settlements/infrastructure/settlement_repository.dart';

// Services
import 'package:care_ledger_app/features/ledger/application/ledger_service.dart';
import 'package:care_ledger_app/features/reviews/application/review_service.dart';
import 'package:care_ledger_app/features/balance/application/balance_service.dart';
import 'package:care_ledger_app/features/settlements/application/settlement_service.dart';

// Providers
import 'package:care_ledger_app/features/ledger/presentation/ledger_provider.dart';
import 'package:care_ledger_app/features/reviews/presentation/review_provider.dart';
import 'package:care_ledger_app/features/balance/presentation/balance_provider.dart';
import 'package:care_ledger_app/features/settings/presentation/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize in-memory repositories (M1 foundation)
  final ledgerRepo = InMemoryLedgerRepository();
  final entryRepo = InMemoryCareEntryRepository();
  final reviewRepo = InMemoryReviewRepository();
  final settlementRepo = InMemorySettlementRepository();

  // Seed development data
  await SeedData.seed(
    ledgerRepo: ledgerRepo,
    entryRepo: entryRepo,
    settlementRepo: settlementRepo,
  );

  // Initialize services
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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
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
      ],
      child: const CareLedgerApp(),
    ),
  );
}

/// Root widget for the Care Ledger application.
class CareLedgerApp extends StatelessWidget {
  const CareLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Care Ledger',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const NavigationShell(),
    );
  }
}
