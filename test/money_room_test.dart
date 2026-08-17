import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/money/domain/entities/category.dart';
import 'package:lifeos/features/money/presentation/pages/money_page.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';

void main() {
  Future<ProviderContainer> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: [
      keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore({})),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
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
        home: const MoneyPage(),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));
    return container;
  }

  testWidgets('the income button opens the sheet on income', (tester) async {
    await open(tester);
    const t = AppLocalizations('ru');

    await tester.tap(find.text(t.tr('money.income')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The segmented control reports which side the sheet actually opened on.
    // Both chips used to open it on "expense", so the income one simply lied.
    final segmented = tester.widget<SegmentedButton<TransactionType>>(
      find.byType(SegmentedButton<TransactionType>),
    );
    expect(segmented.selected, {TransactionType.income});
  });

  testWidgets('the expense button still opens on expense', (tester) async {
    await open(tester);
    const t = AppLocalizations('ru');

    await tester.tap(find.text(t.tr('money.expense')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final segmented = tester.widget<SegmentedButton<TransactionType>>(
      find.byType(SegmentedButton<TransactionType>),
    );
    expect(segmented.selected, {TransactionType.expense});
  });

  group('the affordability card', () {
    testWidgets('says nothing until an amount is typed', (tester) async {
      await open(tester);
      const t = AppLocalizations('ru');

      expect(find.text(t.tr('afford.title')), findsOneWidget);
      // An empty field is not a question, so there must be no verdict yet.
      expect(find.textContaining('осталось'), findsNothing);
    });

    testWidgets('answers on an empty account without dividing by zero',
        (tester) async {
      final container = await open(tester);
      // Nothing logged: no income, so there is nothing free to spend.
      expect(container.read(currentBudgetProvider).income.minorUnits, 0);

      await tester.enterText(find.byType(TextField).last, '500');
      await tester.pump();

      const t = AppLocalizations('ru');
      expect(find.text(t.tr('afford.nothingLeft')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
