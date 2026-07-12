import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/features/cloud/presentation/pages/account_page.dart';
import 'package:lifeos/features/achievements/presentation/pages/achievements_page.dart';
import 'package:lifeos/features/ai/presentation/pages/ai_page.dart';
import 'package:lifeos/features/appearance/presentation/pages/appearance_page.dart';
import 'package:lifeos/features/backup/presentation/pages/backup_page.dart';
import 'package:lifeos/features/money/presentation/pages/budget_limits_page.dart';
import 'package:lifeos/features/money/presentation/pages/category_rules_page.dart';
import 'package:lifeos/features/coach/presentation/pages/coach_page.dart';
import 'package:lifeos/features/money/presentation/pages/csv_import_page.dart';
import 'package:lifeos/features/wellness/presentation/pages/cycle_page.dart';
import 'package:lifeos/features/food/presentation/pages/diet_page.dart';
import 'package:lifeos/features/food/presentation/pages/food_page.dart';
import 'package:lifeos/features/goals/presentation/pages/goals_page.dart';
import 'package:lifeos/features/health/presentation/pages/health_page.dart';
import 'package:lifeos/features/history/presentation/pages/history_page.dart';
import 'package:lifeos/features/insights/presentation/pages/insights_page.dart';
import 'package:lifeos/features/lifeweeks/presentation/pages/life_weeks_page.dart';
import 'package:lifeos/features/health/presentation/pages/measurements_page.dart';
import 'package:lifeos/features/mind/presentation/pages/mind_page.dart';
import 'package:lifeos/features/money/presentation/pages/money_page.dart';
import 'package:lifeos/features/mind/presentation/pages/mood_journal_page.dart';
import 'package:lifeos/features/home/presentation/pages/home_shell.dart';
import 'package:lifeos/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:lifeos/features/notifications/presentation/pages/notifications_page.dart';
import 'package:lifeos/features/monetization/presentation/pages/pro_page.dart';
import 'package:lifeos/features/profile/presentation/pages/profile_page.dart';
import 'package:lifeos/features/money/presentation/pages/receipt_page.dart';
import 'package:lifeos/features/money/presentation/pages/recurring_page.dart';
import 'package:lifeos/features/reminders/presentation/pages/reminders_page.dart';
import 'package:lifeos/features/reports/presentation/pages/report_page.dart';
import 'package:lifeos/features/security/presentation/pages/security_settings_page.dart';
import 'package:lifeos/features/wellness/presentation/pages/vitality_page.dart';
import 'package:lifeos/features/wellness/presentation/pages/wellness_page.dart';
import 'package:lifeos/features/health/presentation/pages/workout_guide_page.dart';
import 'package:lifeos/features/health/presentation/pages/workouts_page.dart';
import 'package:lifeos/features/wrapped/presentation/pages/wrapped_page.dart';

/// Renders every top-level screen (each reachable from the app) in isolation and
/// asserts it builds with no thrown exception — a broad "do all the screens
/// still work" guard across all feature modules. Data comes from the seeded
/// in-memory providers; the clock is pinned so date-driven screens are stable.
class _FixedClock implements Clock {
  @override
  DateTime now() => DateTime(2026, 3, 5, 10);
}

Widget _host(Widget page) => ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(
            InMemoryKeyValueStore({'onboarding.done': 'true'})),
        clockProvider.overrideWithValue(_FixedClock()),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    );

final Map<String, Widget Function()> _pages = {
    'AccountPage': () => const AccountPage(),
    'AchievementsPage': () => const AchievementsPage(),
    'AiPage': () => const AiPage(),
    'AppearancePage': () => const AppearancePage(),
    'BackupPage': () => const BackupPage(),
    'BudgetLimitsPage': () => const BudgetLimitsPage(),
    'CategoryRulesPage': () => const CategoryRulesPage(),
    'CoachPage': () => const CoachPage(),
    'CsvImportPage': () => const CsvImportPage(),
    'CyclePage': () => const CyclePage(),
    'DietPage': () => const DietPage(),
    'FoodPage': () => const FoodPage(),
    'GoalsPage': () => const GoalsPage(),
    'HealthPage': () => const HealthPage(),
    'HistoryPage': () => const HistoryPage(),
    'InsightsPage': () => const InsightsPage(),
    'LifeWeeksPage': () => const LifeWeeksPage(),
    'MeasurementsPage': () => const MeasurementsPage(),
    'MindPage': () => const MindPage(),
    'MoneyPage': () => const MoneyPage(),
    'MoodJournalPage': () => const MoodJournalPage(),
    'MorePage': () => const MorePage(),
    'NotificationSettingsPage': () => const NotificationSettingsPage(),
    'NotificationsPage': () => const NotificationsPage(),
    'ProPage': () => const ProPage(),
    'ProfilePage': () => const ProfilePage(),
    'ReceiptPage': () => const ReceiptPage(),
    'RecurringPage': () => const RecurringPage(),
    'RemindersPage': () => const RemindersPage(),
    'ReportPage': () => const ReportPage(),
    'SecuritySettingsPage': () => const SecuritySettingsPage(),
    'VitalityPage': () => const VitalityPage(),
    'WellnessPage': () => const WellnessPage(),
    'WorkoutGuidePage': () => const WorkoutGuidePage(),
    'WorkoutsPage': () => const WorkoutsPage(),
    'WrappedPage': () => const WrappedPage(),
};

void main() {
  testWidgets('every screen builds without throwing', (tester) async {
    tester.view.physicalSize = const Size(1400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final failures = <String, String>{};
    for (final entry in _pages.entries) {
      try {
        await tester.pumpWidget(_host(entry.value()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(seconds: 1));
        final ex = tester.takeException();
        if (ex != null) failures[entry.key] = ex.toString().split('\n').first;
      } catch (e) {
        failures[entry.key] = e.toString().split('\n').first;
      }
    }
    final report =
        failures.entries.map((e) => '  ${e.key}: ${e.value}').join('\n');
    expect(failures, isEmpty, reason: 'Screens that threw:\n$report');
  });
}
