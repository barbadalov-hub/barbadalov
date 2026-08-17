import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/clock.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/money/domain/entities/purchase.dart';
import 'package:lifeos/features/money/presentation/pages/warranty_page.dart';
import 'package:lifeos/features/money/presentation/providers/purchase_providers.dart';
import 'package:lifeos/shared/models/money.dart';
import 'package:lifeos/shared/providers/core_providers.dart';
import 'package:lifeos/shared/theme/app_theme.dart';

class _FixedClock implements Clock {
  final DateTime _now;
  const _FixedClock(this._now);
  @override
  DateTime now() => _now;
}

void main() {
  late ProviderContainer container;

  Future<void> open(WidgetTester tester, DateTime now,
      {List<Purchase> seed = const []}) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = InMemoryKeyValueStore({});
    container = ProviderContainer(overrides: [
      keyValueStoreProvider.overrideWithValue(store),
      clockProvider.overrideWithValue(_FixedClock(now)),
    ]);
    addTearDown(container.dispose);

    if (seed.isNotEmpty) {
      container
          .read(jsonStoreProvider)
          .saveList<Purchase>('purchases.list', seed, (p) => p.toJson());
    }

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
        home: const WarrantyPage(),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));
  }

  /// The scenario the whole feature exists for.
  testWidgets('headphones bought five months ago are still under warranty',
      (tester) async {
    final bought = DateTime(2026, 1, 10);
    await open(
      tester,
      DateTime(2026, 6, 12),
      seed: [
        Purchase(
          id: 'hp',
          title: 'Наушники',
          shop: 'DNS',
          price: Money.fromMajor(7990),
          boughtAt: bought,
          until: Purchase.addMonths(bought, 12),
        ),
      ],
    );

    expect(find.text('Наушники'), findsOneWidget);
    // Not "you missed it" — seven months of cover left, and the app says so
    // instead of leaving the user to buy a replacement they do not need.
    expect(find.textContaining('На гарантии до'), findsOneWidget);
    expect(find.textContaining('осталось'), findsOneWidget);
  });

  testWidgets('cover about to lapse is listed above cover with time to spare',
      (tester) async {
    final now = DateTime(2026, 6, 12);
    await open(tester, now, seed: [
      Purchase(
        id: 'safe',
        title: 'Холодильник',
        price: Money.fromMajor(30000),
        boughtAt: DateTime(2026, 1, 1),
        until: DateTime(2028, 1, 1),
      ),
      Purchase(
        id: 'soon',
        title: 'Чайник',
        price: Money.fromMajor(3000),
        boughtAt: DateTime(2025, 7, 1),
        until: DateTime(2026, 7, 1),
      ),
    ]);

    final kettle = tester.getTopLeft(find.text('Чайник')).dy;
    final fridge = tester.getTopLeft(find.text('Холодильник')).dy;
    expect(kettle, lessThan(fridge),
        reason: 'the one about to lapse is the one worth acting on');
  });

  testWidgets('an empty shelf explains the point instead of showing nothing',
      (tester) async {
    await open(tester, DateTime(2026, 6, 12));
    const t = AppLocalizations('ru');
    expect(find.text(t.tr('warranty.emptyTitle')), findsOneWidget);
    expect(find.textContaining('Наушники ломаются'), findsOneWidget);
  });

  test('deleting a purchase takes its receipt with it', () async {
    final c = ProviderContainer(overrides: [
      keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore({})),
      clockProvider.overrideWithValue(_FixedClock(DateTime(2026, 6, 12))),
    ]);
    addTearDown(c.dispose);

    final added = await c.read(purchasesProvider.notifier).add(
          title: 'Тостер',
          price: Money.fromMajor(2000),
          boughtAt: DateTime(2026, 6, 1),
        );
    expect(c.read(purchasesProvider).length, 1);

    await c.read(purchasesProvider.notifier).remove(added.id);
    expect(c.read(purchasesProvider), isEmpty);
  });

  test('the badge counts only what is about to lapse', () {
    final now = DateTime(2026, 6, 12);
    final c = ProviderContainer(overrides: [
      keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore({})),
      clockProvider.overrideWithValue(_FixedClock(now)),
    ]);
    addTearDown(c.dispose);

    c.read(jsonStoreProvider).saveList<Purchase>(
      'purchases.list',
      [
        Purchase(
          id: 'a',
          title: 'a',
          price: Money.zero(),
          boughtAt: now,
          until: DateTime(2026, 6, 20),
        ),
        Purchase(
          id: 'b',
          title: 'b',
          price: Money.zero(),
          boughtAt: now,
          until: DateTime(2030, 1, 1),
        ),
        Purchase(id: 'c', title: 'c', price: Money.zero(), boughtAt: now),
      ],
      (p) => p.toJson(),
    );

    expect(c.read(endingSoonCountProvider), 1);
  });
}
