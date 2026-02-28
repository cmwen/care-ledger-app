import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:care_ledger_app/app/theme.dart';
import 'package:care_ledger_app/app/navigation_shell.dart';
import 'package:care_ledger_app/core/identity_service.dart';
import 'package:care_ledger_app/core/guest_mode.dart';
import 'package:care_ledger_app/data/seed_data.dart';
import 'package:care_ledger_app/l10n/app_localizations.dart';
import 'package:care_ledger_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:care_ledger_app/features/onboarding/presentation/pairing_screen.dart';

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

// Auto-capture
import 'package:care_ledger_app/features/auto_capture/application/auto_capture_service.dart';
import 'package:care_ledger_app/features/auto_capture/infrastructure/geofence_service.dart';
import 'package:care_ledger_app/features/auto_capture/presentation/auto_capture_provider.dart';

// Sync
import 'package:care_ledger_app/sync/infrastructure/sync_event_repository.dart';
import 'package:care_ledger_app/sync/infrastructure/export_sync_service.dart';
import 'package:care_ledger_app/sync/infrastructure/lan_sync_service.dart';
import 'package:care_ledger_app/sync/presentation/sync_provider.dart';

// Providers
import 'package:care_ledger_app/features/ledger/presentation/ledger_provider.dart';
import 'package:care_ledger_app/features/reviews/presentation/review_provider.dart';
import 'package:care_ledger_app/features/balance/presentation/balance_provider.dart';
import 'package:care_ledger_app/features/settings/presentation/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise device identity
  final identityService = await IdentityService.create();

  // Initialize in-memory repositories (M1 foundation)
  final ledgerRepo = InMemoryLedgerRepository();
  final entryRepo = InMemoryCareEntryRepository();
  final reviewRepo = InMemoryReviewRepository();
  final settlementRepo = InMemorySettlementRepository();
  final syncEventRepo = InMemorySyncEventRepository();

  // Seed development data using identity-based IDs when paired,
  // otherwise use fallback IDs (they'll be replaced once pairing completes).
  await SeedData.seed(
    ledgerRepo: ledgerRepo,
    entryRepo: entryRepo,
    settlementRepo: settlementRepo,
    participantAId: identityService.isOnboarded
        ? identityService.deviceId
        : SeedData.fallbackParticipantAId,
    participantBId: identityService.isPaired
        ? identityService.partnerId
        : SeedData.fallbackParticipantBId,
  );

  // Enable guest mode if paired with a demo partner (skip flow).
  if (identityService.isPaired &&
      (identityService.partnerId == 'demo-partner' ||
          identityService.partnerId == 'demo-partner-joined')) {
    GuestMode.enable();
  }

  // Initialize services
  final ledgerService = LedgerService(
    ledgerRepo: ledgerRepo,
    entryRepo: entryRepo,
    syncRepo: syncEventRepo,
  );
  final reviewService = ReviewService(
    entryRepo: entryRepo,
    reviewRepo: reviewRepo,
    syncRepo: syncEventRepo,
  );
  final balanceService = BalanceService(
    entryRepo: entryRepo,
    settlementRepo: settlementRepo,
  );
  final settlementService = SettlementService(
    settlementRepo: settlementRepo,
    syncRepo: syncEventRepo,
  );
  final geofenceService = GeofenceService();
  final autoCaptureService = AutoCaptureService(
    entryRepo: entryRepo,
    geofenceService: geofenceService,
  );

  // Initialize sync services
  final exportSyncService = ExportSyncService(eventRepo: syncEventRepo);
  final lanSyncService = LanSyncService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(identity: identityService),
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
        ChangeNotifierProvider(
          create: (_) => SyncProvider(
            exportService: exportSyncService,
            lanService: lanSyncService,
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
      home: _buildHome(settings),
    );
  }

  Widget _buildHome(SettingsProvider settings) {
    if (!settings.isOnboarded) {
      return const OnboardingScreen();
    }
    if (!settings.isPaired) {
      return const PairingScreen();
    }
    return const NavigationShell();
  }
}
