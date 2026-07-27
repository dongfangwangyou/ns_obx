import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ns_obx/ns_obx.dart';

/// 集成场景测试：以普通 widget test 方式运行，覆盖 Counter、RxLifecycleMixin
/// 页面释放、Signal 事件总线等端到端场景。
///
/// 与 integration_test/ 不同，本文件无需平台工程即可通过 `flutter test` 直接执行。
void main() {
  setUp(() {
    RxInterface.resetProxy();
  });

  group('ns_obx integration scenarios', () {
    testWidgets('counter increments and rebuilds', (tester) async {
      final counter = 0.obs;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Obx(() => Text('${counter.value}', key: const Key('counterValue'))),
          floatingActionButton: FloatingActionButton(
            key: const Key('incrementButton'),
            onPressed: () => counter.value++,
            child: const Icon(Icons.add),
          ),
        ),
      ));

      expect(find.text('0'), findsOneWidget);

      await tester.tap(find.byKey(const Key('incrementButton')));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      counter.close();
    });

    testWidgets('RxLifecycleMixin disposes resources after pop', (tester) async {
      final counter = 0.obs;
      var notifyCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: _DisposableTestPage(counter, () => notifyCount++),
      ));

      expect(notifyCount, 1);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      final countAfterDispose = notifyCount;
      counter.value = 99;
      await tester.pump();
      expect(notifyCount, countAfterDispose);

      counter.close();
    });

    testWidgets('Signal event bus delivers events to multiple subscribers',
        (tester) async {
      final bus = Signal<int>();
      final received = <int>[];

      bus.listen((v) => received.add(v));
      bus.listen((v) => received.add(v * 10));

      bus.emit(3);
      await tester.pump();

      expect(received, [3, 30]);
      bus.close();
    });

    testWidgets('real-world todo list scenario', (tester) async {
      final todos = <String>[].obs;
      final input = TextEditingController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(
                controller: input,
                key: const Key('todoInput'),
                onSubmitted: (v) {
                  if (v.isNotEmpty) todos.add(v);
                  input.clear();
                },
              ),
              Expanded(
                child: Obx(() => ListView.builder(
                      itemCount: todos.length,
                      itemBuilder: (_, i) => Text(todos[i]),
                    )),
              ),
            ],
          ),
        ),
      ));

      await tester.enterText(find.byKey(const Key('todoInput')), 'Buy milk');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.text('Buy milk'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('todoInput')), 'Walk dog');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.text('Buy milk'), findsOneWidget);
      expect(find.text('Walk dog'), findsOneWidget);

      todos.close();
    });
  });
}

class _DisposableTestPage extends StatefulWidget {
  final RxInt counter;
  final void Function() onNotify;

  const _DisposableTestPage(this.counter, this.onNotify);

  @override
  State<_DisposableTestPage> createState() => _DisposableTestPageState();
}

class _DisposableTestPageState extends State<_DisposableTestPage>
    with RxLifecycleMixin {
  @override
  void initState() {
    super.initState();
    listen<int>(widget.counter, (_) => widget.onNotify());
    widget.counter.value = 1;
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
