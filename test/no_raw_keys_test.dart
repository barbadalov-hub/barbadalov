import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/goals/presentation/pages/goals_page.dart';
import 'package:lifeos/features/health/presentation/pages/health_page.dart';
import 'package:lifeos/features/home/presentation/pages/today_page.dart';
import 'package:lifeos/features/mind/presentation/pages/mind_page.dart';
import 'package:lifeos/features/money/presentation/pages/money_page.dart';
import 'package:lifeos/features/planner/presentation/pages/planner_page.dart';
import 'package:lifeos/features/rooms/presentation/pages/rooms_page.dart';
import 'package:lifeos/features/telescope/presentation/pages/telescope_page.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';

/// Looks like `money.history` or `ftip.payYourself`: a dotted identifier with
/// no spaces, starting with a letter. Prices ("8.5"), times and sentences do
/// not match, so a hit is almost certainly a key that never reached `tr()`.
final _looksLikeKey = RegExp(r'^[a-z][A-Za-z0-9]*(\.[A-Za-z0-9]+)+$');

/// Some strings genuinely travel as keys — `tr` returns the key itself when a
/// translation is missing, and `i18n_usage_test` already guards that. This
/// catches the *other* half: a key that is correctly in the table but is
/// printed without ever being looked up.
///
/// That is how "ftip.payYourself" ended up as the Money room's headline
/// sentence on every account with nothing logged — which is every new account.
void main() {
  const screens = <String, Widget>{
    'rooms': RoomsPage(),
    'today': TodayPage(),
    'telescope': TelescopePage(),
    'planner': PlannerPage(),
    'money': MoneyPage(),
    'body': HealthPage(),
    'mind': MindPage(),
    'goals': GoalsPage(),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} never prints a raw localization key',
        (tester) async {
      tester.view.physicalSize = const Size(420, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          // An untouched account: the state where fallback copy is used, and
          // therefore where an untranslated fallback actually shows up.
          keyValueStoreProvider.overrideWithValue(
              InMemoryKeyValueStore({'onboarding.done': 'true'})),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: entry.value,
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 1));

      final offenders = <String>[];
      for (final widget in tester.allWidgets.whereType<Text>()) {
        final data = widget.data;
        if (data != null && _looksLikeKey.hasMatch(data.trim())) {
          offenders.add(data.trim());
        }
      }

      expect(offenders, isEmpty,
          reason: '${entry.key} shows untranslated keys: $offenders');
    });
  }
}
