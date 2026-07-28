import 'package:flutter_test/flutter_test.dart';
import 'package:missed_call/app.dart';

void main() {
  testWidgets('boots into the prologue and shows the first line + chrome',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MissedCallApp());
    await tester.pump(const Duration(milliseconds: 50));

    // First narration line of the 'ring' node.
    expect(find.textContaining('Ты не сразу понимаешь'), findsOneWidget);
    // Localized chrome (defaults to ru) and the night clock.
    expect(find.text('щадящий: выкл'), findsOneWidget);
    expect(find.text('03:14'), findsOneWidget);
  });

  testWidgets('the language toggle switches chrome to English',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MissedCallApp());
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('RU'));
    await tester.pump();

    expect(find.text('safe mode: off'), findsOneWidget);
  });
}
