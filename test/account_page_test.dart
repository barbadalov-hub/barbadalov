import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/i18n/app_localizations.dart';
import 'package:lifeos/core/services/key_value_store.dart';
import 'package:lifeos/features/cloud/presentation/pages/account_page.dart';
import 'package:lifeos/shared/providers/core_providers.dart';

Widget _app(InMemoryKeyValueStore store) => ProviderScope(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
      child: const MaterialApp(
        locale: Locale('ru'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: AccountPage(),
      ),
    );

void main() {
  testWidgets('guest state shows the register form; toggles to sign in',
      (tester) async {
    await tester.pumpWidget(_app(InMemoryKeyValueStore()));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Гость (это устройство)'), findsOneWidget);
    expect(find.text('Привяжите данные к почте'), findsOneWidget);
    expect(find.text('Сохранить и синхронизировать'), findsOneWidget);

    await tester.tap(find.text('У меня уже есть аккаунт'));
    await tester.pump();
    expect(find.text('Вход в аккаунт'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Войти'), findsOneWidget);
  });

  testWidgets('signed-in state shows the email and a sign-out button',
      (tester) async {
    final store = InMemoryKeyValueStore({'cloud.email': 'arkadiy@example.com'});
    await tester.pumpWidget(_app(store));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('arkadiy@example.com'), findsOneWidget);
    expect(find.text('Выйти'), findsOneWidget);
    expect(find.text('Сохранить и синхронизировать'), findsNothing);
  });
}
