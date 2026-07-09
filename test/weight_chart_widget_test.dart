import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/health/presentation/widgets/health_charts.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

void main() {
  testWidgets('weight trend card renders the chart and the delta',
      (tester) async {
    final store = InMemoryKeyValueStore({
      'health.weightHistory': jsonEncode([
        {'date': '2026-06-10T08:00:00', 'kg': 74.2},
        {'date': '2026-06-20T08:00:00', 'kg': 73.0},
        {'date': '2026-07-01T08:00:00', 'kg': 72.0},
      ]),
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [keyValueStoreProvider.overrideWithValue(store)],
        child: const MaterialApp(
          locale: Locale('uk'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: WeightTrendCard()),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Динаміка ваги'), findsOneWidget);
    expect(find.text('-2.2 kg'), findsOneWidget); // 74.2 → 72.0
    expect(find.byType(CustomPaint), findsWidgets); // the line chart itself
  });
}
