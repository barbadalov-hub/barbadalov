import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/money/presentation/pages/warranty_page.dart';
import 'package:lifeos/features/money/presentation/providers/money_providers.dart';
import 'package:lifeos/features/money/presentation/providers/purchase_providers.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';

/// Buying something is one event, not two. Recording the warranty and the
/// expense separately is the kind of double entry that makes people stop using
/// a feature — but posting old purchases as fresh expenses would be worse than
/// the typing it saves.
void main() {
  late ProviderContainer container;

  Future<void> openSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    container = ProviderContainer(overrides: [
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
        home: const Scaffold(body: PurchaseSheet()),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('a purchase made today offers to log the expense, on by default',
      (tester) async {
    await openSheet(tester);

    final toggle = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(toggle.value, isTrue,
        reason: 'money entered today is money that just left');
  });

  testWidgets('saving records both the warranty and the expense',
      (tester) async {
    await openSheet(tester);

    const t = AppLocalizations('ru');
    // By position: title, shop, price — the order they appear in the sheet.
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Наушники');
    await tester.enterText(fields.at(2), '7990');
    await tester.pump();

    await tester.tap(find.text(t.tr('common.save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(container.read(purchasesProvider), hasLength(1));
    // transactionsProvider is a stream: reading it synchronously right after a
    // write returns the value from before the write.
    final tx = await container.read(transactionsProvider.future);
    expect(tx, hasLength(1));
    expect(tx.single.amount.major, 7990);
    expect(tx.single.note, contains('Наушники'));
  });

  testWidgets('switching it off keeps the money history untouched',
      (tester) async {
    await openSheet(tester);
    const t = AppLocalizations('ru');

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Чайник');
    await tester.enterText(fields.at(2), '3000');
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();

    await tester.tap(find.text(t.tr('common.save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(container.read(purchasesProvider), hasLength(1));
    expect(await container.read(transactionsProvider.future), isEmpty);
  });

  testWidgets('a purchase with no price never invents an expense',
      (tester) async {
    await openSheet(tester);
    const t = AppLocalizations('ru');

    await tester.enterText(find.byType(TextField).at(0), 'Подарок');
    await tester.tap(find.text(t.tr('common.save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(container.read(purchasesProvider), hasLength(1));
    expect(await container.read(transactionsProvider.future), isEmpty,
        reason: 'a zero expense is not a transaction');
  });
}
