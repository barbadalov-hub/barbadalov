import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/money/presentation/pages/receipt_page.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/features/money/presentation/widgets/add_transaction_sheet.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

class _FixedClock implements Clock {
  @override
  DateTime now() => DateTime(2026, 3, 5, 10);
}

Widget _host(Widget page, {required ProviderContainer container}) =>
    UncontrolledProviderScope(
      container: container,
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

void main() {
  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          keyValueStoreProvider.overrideWithValue(
              InMemoryKeyValueStore({'onboarding.done': 'true'})),
          clockProvider.overrideWithValue(_FixedClock()),
        ],
      );

  void bigSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('receipt save records one expense per item', (tester) async {
    bigSurface(tester);
    final container = makeContainer();
    addTearDown(container.dispose);

    // Warm the transactions stream so saves are reflected when we read it.
    final sub = container.listen(transactionsProvider, (_, __) {});
    addTearDown(sub.close);

    await tester.pumpWidget(_host(const ReceiptPage(), container: container));
    await tester.pump();

    // A three-item grocery receipt.
    const text = 'Bread 18.50\nMilk 21.50\nApples 12.00\nTOTAL 52.00';
    await tester.enterText(find.byType(TextField).first, text);

    await tester.tap(find.text('Analyze'));
    await tester.pump();

    final saveBtn = find.text('Save as expenses');
    await tester.ensureVisible(saveBtn);
    await tester.tap(saveBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(); // let the transactions stream emit

    // Each of the three items became its own transaction (not one lumped
    // per-category expense), keeping the product name as the note.
    final txns = container.read(transactionsProvider).valueOrNull ?? const [];
    expect(txns.length, 3);
    expect(txns.map((t) => t.note).toSet(),
        containsAll(<String>['Bread', 'Milk', 'Apples']));
  });

  testWidgets('add-expense sheet offers a scan-receipt button', (tester) async {
    bigSurface(tester);
    final container = makeContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_host(
      Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => AddTransactionSheet.show(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      container: container,
    ));
    await tester.pump(); // localizations load asynchronously
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Expense is the default type, so the receipt entry point is visible.
    expect(find.text('Scan a receipt'), findsOneWidget);
  });
}
