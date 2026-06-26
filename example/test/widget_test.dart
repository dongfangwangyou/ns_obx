import 'package:flutter_test/flutter_test.dart';
import 'package:ns_obx_example/main.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const NsObxExampleApp());
  // IndexedStack keeps all tabs mounted (AutoDispose timers); avoid pumpAndSettle.
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _selectTab(WidgetTester tester, String label) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('app loads with all demo tabs', (tester) async {
    await _pumpApp(tester);

    expect(find.text('ns_obx Example'), findsOneWidget);
    expect(find.text('Basic Rx'), findsOneWidget);
    expect(find.text('Collections'), findsOneWidget);
    expect(find.text('Nullable'), findsOneWidget);
    expect(find.text('Signal'), findsOneWidget);
    expect(find.text('AutoDispose'), findsOneWidget);
    expect(find.text('Workers'), findsOneWidget);
    expect(find.text('Boundaries'), findsOneWidget);
  });

  testWidgets('basic counter increments', (tester) async {
    await _pumpApp(tester);

    expect(find.text('Count: 0'), findsOneWidget);

    await tester.tap(find.text('+1'));
    await tester.pump();

    expect(find.text('Count: 1'), findsOneWidget);
  });

  testWidgets('switch to collections tab shows RxList', (tester) async {
    await _pumpApp(tester);
    await _selectTab(tester, 'Collections');

    expect(find.text('1. RxList<String>'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);
  });

  testWidgets('workers tab shows debounce search field', (tester) async {
    await _pumpApp(tester);
    await _selectTab(tester, 'Workers');

    expect(find.textContaining('ever + interval'), findsOneWidget);
    expect(find.text('Type to search (500ms debounce)'), findsOneWidget);
  });
}
