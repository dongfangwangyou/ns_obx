import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ns_obx_example/main.dart';

void main() {
  testWidgets('app loads with demo drawer', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('ns_obx'), findsOneWidget);
    expect(find.text('Basic Rx'), findsOneWidget);
  });

  testWidgets('drawer shows all demo pages', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Collections'), findsOneWidget);
    expect(find.text('Workers'), findsOneWidget);
    expect(find.text('AutoDispose'), findsOneWidget);
  });

  testWidgets('counter increments on Basic Rx page', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Count: 0'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '+1'));
    await tester.pump();

    expect(find.text('Count: 1'), findsOneWidget);
  });
}
