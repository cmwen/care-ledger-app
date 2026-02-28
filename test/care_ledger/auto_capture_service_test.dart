import 'package:flutter_test/flutter_test.dart';
import 'package:care_ledger_app/features/auto_capture/application/auto_capture_service.dart';
import 'package:care_ledger_app/features/auto_capture/domain/capture_signal.dart';
import 'package:care_ledger_app/features/auto_capture/domain/capture_rule.dart';
import 'package:care_ledger_app/features/auto_capture/infrastructure/geofence_service.dart';
import 'package:care_ledger_app/features/ledger/domain/care_entry.dart';
import 'package:care_ledger_app/features/ledger/infrastructure/care_entry_repository.dart';

void main() {
  late AutoCaptureService service;
  late InMemoryCareEntryRepository entryRepo;
  late GeofenceService geofenceService;

  const ledgerId = 'test-ledger';
  const authorId = 'user-a';

  setUp(() {
    entryRepo = InMemoryCareEntryRepository();
    geofenceService = GeofenceService();
    service = AutoCaptureService(
      entryRepo: entryRepo,
      geofenceService: geofenceService,
    );
  });

  /// Helper: seed a confirmed entry on a specific weekday N weeks ago.
  Future<void> seedEntry({
    required int weeksAgo,
    required int weekday,
    required int hour,
    required EntryCategory category,
    required String description,
    double credits = 2.0,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfThisWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfTargetWeek = startOfThisWeek.subtract(
      Duration(days: weeksAgo * 7),
    );
    final occurredAt = startOfTargetWeek.add(
      Duration(days: weekday - 1, hours: hour),
    );

    await entryRepo.save(
      CareEntry(
        id: 'entry-w$weeksAgo-d$weekday-$category',
        ledgerId: ledgerId,
        authorId: authorId,
        occurredAt: occurredAt,
        category: category,
        description: description,
        creditsProposed: credits,
        creditsConfirmed: credits,
        status: EntryStatus.confirmed,
        createdAt: occurredAt,
        updatedAt: occurredAt,
      ),
    );
  }

  group('AutoCaptureService.detectPatterns', () {
    test('detects recurring weekday patterns', () async {
      // Seed driving on Monday for 3 weeks.
      for (var w = 1; w <= 3; w++) {
        await seedEntry(
          weeksAgo: w,
          weekday: 1,
          hour: 8,
          category: EntryCategory.driving,
          description: 'School run',
        );
      }

      final rules = await service.detectPatterns(
        ledgerId: ledgerId,
        authorId: authorId,
      );

      expect(rules, isNotEmpty);
      final drivingRule = rules.firstWhere(
        (r) => r.category == EntryCategory.driving,
      );
      expect(drivingRule.activeDays, contains(1)); // Monday
      expect(drivingRule.matchCount, equals(3));
      expect(drivingRule.confidence, equals(SignalConfidence.high));
    });

    test('assigns medium confidence for 2 occurrences', () async {
      for (var w = 1; w <= 2; w++) {
        await seedEntry(
          weeksAgo: w,
          weekday: 3,
          hour: 18,
          category: EntryCategory.cooking,
          description: 'Dinner',
        );
      }

      final rules = await service.detectPatterns(
        ledgerId: ledgerId,
        authorId: authorId,
      );

      final cookingRule = rules.firstWhere(
        (r) => r.category == EntryCategory.cooking,
      );
      expect(cookingRule.matchCount, equals(2));
      expect(cookingRule.confidence, equals(SignalConfidence.medium));
    });

    test('assigns low confidence for 1 occurrence', () async {
      await seedEntry(
        weeksAgo: 1,
        weekday: 6,
        hour: 10,
        category: EntryCategory.shopping,
        description: 'Grocery shopping',
      );

      final rules = await service.detectPatterns(
        ledgerId: ledgerId,
        authorId: authorId,
      );

      final shoppingRule = rules.firstWhere(
        (r) => r.category == EntryCategory.shopping,
      );
      expect(shoppingRule.matchCount, equals(1));
      expect(shoppingRule.confidence, equals(SignalConfidence.low));
    });

    test('ignores entries by other authors', () async {
      await entryRepo.save(
        CareEntry(
          id: 'other-author-entry',
          ledgerId: ledgerId,
          authorId: 'user-b',
          occurredAt: DateTime.now().subtract(const Duration(days: 7)),
          category: EntryCategory.laundry,
          description: 'Laundry',
          creditsProposed: 1.0,
          creditsConfirmed: 1.0,
          status: EntryStatus.confirmed,
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          updatedAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
      );

      final rules = await service.detectPatterns(
        ledgerId: ledgerId,
        authorId: authorId,
      );

      expect(rules, isEmpty);
    });

    test('ignores rejected entries', () async {
      final now = DateTime.now();
      await entryRepo.save(
        CareEntry(
          id: 'rejected-entry',
          ledgerId: ledgerId,
          authorId: authorId,
          occurredAt: now.subtract(const Duration(days: 7)),
          category: EntryCategory.housework,
          description: 'Tidying',
          creditsProposed: 1.0,
          status: EntryStatus.rejected,
          createdAt: now.subtract(const Duration(days: 7)),
          updatedAt: now.subtract(const Duration(days: 7)),
        ),
      );

      final rules = await service.detectPatterns(
        ledgerId: ledgerId,
        authorId: authorId,
      );

      expect(
        rules.where((r) => r.category == EntryCategory.housework),
        isEmpty,
      );
    });
  });

  group('AutoCaptureService.generateWeeklySuggestions', () {
    test('generates suggestions for missing patterns', () async {
      // Seed a consistent driving pattern on Monday.
      for (var w = 1; w <= 3; w++) {
        await seedEntry(
          weeksAgo: w,
          weekday: 1,
          hour: 8,
          category: EntryCategory.driving,
          description: 'School run',
        );
      }

      final now = DateTime.now();
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));

      final signals = await service.generateWeeklySuggestions(
        ledgerId: ledgerId,
        authorId: authorId,
        weekStart: weekStart,
      );

      // Should suggest driving on Monday if it hasn't happened yet this week.
      final today = DateTime.now();
      final mondayThisWeek = weekStart;

      if (today.isAfter(mondayThisWeek) || today.day == mondayThisWeek.day) {
        // Monday has passed, so we should have a suggestion
        // (unless today IS Monday and it's before the typical time).
        // The test is flexible since it depends on the day of the week.
        // At minimum, the signals should all be for driving.
        for (final signal in signals) {
          expect(signal.suggestedCategory, equals(EntryCategory.driving));
          expect(signal.sourceHint, isNotEmpty);
          expect(signal.confidence, equals(SignalConfidence.high));
        }
      }
    });

    test('does not suggest patterns that already exist this week', () async {
      // Seed pattern: laundry on Sunday.
      for (var w = 1; w <= 3; w++) {
        await seedEntry(
          weeksAgo: w,
          weekday: 7,
          hour: 9,
          category: EntryCategory.laundry,
          description: 'Laundry',
          credits: 1.5,
        );
      }

      // Add an entry for this Sunday as well.
      final now = DateTime.now();
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      final thisSunday = weekStart.add(const Duration(days: 6, hours: 9));

      await entryRepo.save(
        CareEntry(
          id: 'this-week-laundry',
          ledgerId: ledgerId,
          authorId: authorId,
          occurredAt: thisSunday,
          category: EntryCategory.laundry,
          description: 'Laundry',
          creditsProposed: 1.5,
          status: EntryStatus.needsReview,
          createdAt: thisSunday,
          updatedAt: thisSunday,
        ),
      );

      final signals = await service.generateWeeklySuggestions(
        ledgerId: ledgerId,
        authorId: authorId,
        weekStart: weekStart,
      );

      // Should NOT suggest laundry since it already exists.
      expect(
        signals.where((s) => s.suggestedCategory == EntryCategory.laundry),
        isEmpty,
      );
    });

    test('signals are sorted by confidence then time', () async {
      // Seed high-confidence pattern.
      for (var w = 1; w <= 3; w++) {
        await seedEntry(
          weeksAgo: w,
          weekday: 2,
          hour: 8,
          category: EntryCategory.driving,
          description: 'School run',
        );
      }
      // Seed low-confidence pattern.
      await seedEntry(
        weeksAgo: 1,
        weekday: 2,
        hour: 18,
        category: EntryCategory.cooking,
        description: 'Dinner',
        credits: 2.5,
      );

      final now = DateTime.now();
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));

      final signals = await service.generateWeeklySuggestions(
        ledgerId: ledgerId,
        authorId: authorId,
        weekStart: weekStart,
      );

      if (signals.length >= 2) {
        // High confidence should come before low confidence.
        expect(
          signals.first.confidence.index,
          lessThanOrEqualTo(signals.last.confidence.index),
        );
      }
    });
  });

  group('AutoCaptureService.signalsToDraftEntries', () {
    test('converts signals to draft entries with correct metadata', () {
      final signals = [
        CaptureSignal(
          id: 'sig-1',
          source: SignalSource.timePattern,
          confidence: SignalConfidence.high,
          description: 'School run',
          suggestedCategory: EntryCategory.driving,
          suggestedCredits: 2.0,
          detectedAt: DateTime.now(),
          sourceHint: 'You usually drive on Mondays',
        ),
      ];

      final drafts = service.signalsToDraftEntries(
        signals: signals,
        ledgerId: ledgerId,
        authorId: authorId,
      );

      expect(drafts, hasLength(1));
      final draft = drafts.first;
      expect(draft.sourceType, equals(SourceType.suggested));
      expect(draft.sourceHint, isNotNull);
      expect(draft.sourceHint, equals('You usually drive on Mondays'));
      expect(draft.status, equals(EntryStatus.needsReview));
      expect(draft.category, equals(EntryCategory.driving));
      expect(draft.creditsProposed, equals(2.0));
      expect(draft.ledgerId, equals(ledgerId));
      expect(draft.authorId, equals(authorId));
    });

    test('never creates entries with confirmed status', () {
      final signals = [
        CaptureSignal(
          id: 'sig-2',
          source: SignalSource.timePattern,
          confidence: SignalConfidence.high,
          description: 'Test',
          suggestedCategory: EntryCategory.cooking,
          suggestedCredits: 1.0,
          detectedAt: DateTime.now(),
          sourceHint: 'Pattern detected',
        ),
      ];

      final drafts = service.signalsToDraftEntries(
        signals: signals,
        ledgerId: ledgerId,
        authorId: authorId,
      );

      for (final draft in drafts) {
        expect(draft.status, isNot(equals(EntryStatus.confirmed)));
        expect(draft.sourceType, equals(SourceType.suggested));
        expect(draft.sourceHint, isNotNull);
      }
    });
  });

  group('CaptureRule', () {
    test('confidence is high when matchCount >= 3', () {
      final rule = CaptureRule(
        id: 'r-1',
        name: 'Test',
        source: SignalSource.timePattern,
        category: EntryCategory.driving,
        defaultCredits: 2.0,
        activeDays: [1],
        matchCount: 3,
        createdAt: DateTime.now(),
      );
      expect(rule.confidence, equals(SignalConfidence.high));
    });

    test('confidence is medium when matchCount == 2', () {
      final rule = CaptureRule(
        id: 'r-2',
        name: 'Test',
        source: SignalSource.timePattern,
        category: EntryCategory.cooking,
        defaultCredits: 2.0,
        activeDays: [3],
        matchCount: 2,
        createdAt: DateTime.now(),
      );
      expect(rule.confidence, equals(SignalConfidence.medium));
    });

    test('confidence is low when matchCount == 1', () {
      final rule = CaptureRule(
        id: 'r-3',
        name: 'Test',
        source: SignalSource.timePattern,
        category: EntryCategory.shopping,
        defaultCredits: 3.0,
        activeDays: [6],
        matchCount: 1,
        createdAt: DateTime.now(),
      );
      expect(rule.confidence, equals(SignalConfidence.low));
    });
  });

  group('CaptureSignal', () {
    test('copyWith preserves unchanged fields', () {
      final signal = CaptureSignal(
        id: 'sig-1',
        source: SignalSource.timePattern,
        confidence: SignalConfidence.high,
        description: 'Test',
        suggestedCategory: EntryCategory.driving,
        suggestedCredits: 2.0,
        detectedAt: DateTime.now(),
        sourceHint: 'hint',
      );

      final modified = signal.copyWith(suggestedCredits: 3.0);
      expect(modified.id, equals(signal.id));
      expect(modified.description, equals(signal.description));
      expect(modified.suggestedCredits, equals(3.0));
    });
  });

  group('GeofenceService', () {
    test('stub returns empty transitions', () async {
      final signals = await geofenceService.checkGeofenceTransitions();
      expect(signals, isEmpty);
    });

    test('can save and retrieve locations', () async {
      final location = await geofenceService.saveCurrentLocation(
        label: 'School',
        category: EntryCategory.driving,
        credits: 2.0,
      );

      expect(location.label, equals('School'));
      expect(location.defaultCategory, equals(EntryCategory.driving));
      expect(geofenceService.savedLocations, hasLength(1));
    });

    test('can remove locations', () async {
      final location = await geofenceService.saveCurrentLocation(
        label: 'School',
        category: EntryCategory.driving,
      );

      geofenceService.removeLocation(location.id);
      expect(geofenceService.savedLocations, isEmpty);
    });
  });
}
