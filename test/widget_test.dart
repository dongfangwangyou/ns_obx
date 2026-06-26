import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ns_obx/ns_obx.dart';

class CounterPage extends StatelessWidget {
  final RxInt counter;

  const CounterPage(this.counter, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Obx(() => Text('${counter.value}')),
        ),
      ),
    );
  }
}

/// 使用 ObxValue 的开关 Widget
class ObxValueSwitch extends StatelessWidget {
  final RxBool state;
  final VoidCallback? onChanged;

  const ObxValueSwitch(this.state, {super.key, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ObxValue<RxBool>(
          (data) => GestureDetector(
            onTap: () {
              data.toggle();
              onChanged?.call();
            },
            child: Text(data.isTrue ? 'ON' : 'OFF'),
          ),
          state,
        ),
      ),
    );
  }
}

void main() {
  setUp(() {
    RxInterface.resetProxy();
  });

  // ============================================================
  // Obx 重建逻辑
  // ============================================================
  group('Obx rebuild logic', () {
    testWidgets('Obx coalesces multiple Rx changes in same frame',
        (tester) async {
      var buildCount = 0;
      final a = 0.obs;
      final b = 0.obs;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Obx(() {
            buildCount++;
            return Text('${a.value}-${b.value}');
          }),
        ),
      ));

      expect(buildCount, 1);

      a.value = 1;
      b.value = 2;
      await tester.pump();

      expect(buildCount, 2);
      expect(find.text('1-2'), findsOneWidget);
    });

    testWidgets('Obx rebuilds when Rx value changes', (tester) async {
      final counter = 0.obs;

      await tester.pumpWidget(CounterPage(counter));
      expect(find.text('0'), findsOneWidget);

      counter.value = 5;
      await tester.pump();
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('Obx rebuilds multiple times on sequential changes',
        (tester) async {
      final counter = 0.obs;

      await tester.pumpWidget(CounterPage(counter));
      expect(find.text('0'), findsOneWidget);

      for (var i = 1; i <= 3; i++) {
        counter.value = i;
        await tester.pump();
        expect(find.text('$i'), findsOneWidget);
      }
    });

    testWidgets('two Obx widgets with different Rx update independently',
        (tester) async {
      final a = 0.obs;
      final b = 10.obs;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Obx(() => Text('A: ${a.value}')),
              Obx(() => Text('B: ${b.value}')),
            ],
          ),
        ),
      ));

      expect(find.text('A: 0'), findsOneWidget);
      expect(find.text('B: 10'), findsOneWidget);

      a.value = 1;
      await tester.pump();
      expect(find.text('A: 1'), findsOneWidget);
      expect(find.text('B: 10'), findsOneWidget);

      b.value = 20;
      await tester.pump();
      expect(find.text('A: 1'), findsOneWidget);
      expect(find.text('B: 20'), findsOneWidget);
    });

    testWidgets('Obx with RxString rebuilds', (tester) async {
      final text = 'hello'.obs;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Obx(() => Text(text.value)),
        ),
      ));

      expect(find.text('hello'), findsOneWidget);
      text.value = 'world';
      await tester.pump();
      expect(find.text('world'), findsOneWidget);
    });

    testWidgets('Obx with RxBool rebuilds', (tester) async {
      final flag = true.obs;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Obx(() => Text(flag.value ? 'YES' : 'NO')),
        ),
      ));

      expect(find.text('YES'), findsOneWidget);
      flag.toggle();
      await tester.pump();
      expect(find.text('NO'), findsOneWidget);
    });

    testWidgets('Obx drops stale Rx subscriptions after conditional rebuild',
        (tester) async {
      final showA = true.obs;
      final a = 0.obs;
      final b = 0.obs;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Obx(() {
            if (showA.value) {
              return Text('A: ${a.value}');
            }
            return Text('B: ${b.value}');
          }),
        ),
      ));

      expect(find.text('A: 0'), findsOneWidget);

      showA.value = false;
      await tester.pump();
      expect(find.text('B: 0'), findsOneWidget);

      // 已切换到 B 分支，修改 a 不应触发 rebuild
      a.value = 99;
      await tester.pump();
      expect(find.text('B: 0'), findsOneWidget);

      b.value = 42;
      await tester.pump();
      expect(find.text('B: 42'), findsOneWidget);
    });

    testWidgets('Obx rebuilds when RxList changes', (tester) async {
      final items = <String>[].obs;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Obx(() => Text('count: ${items.length}')),
        ),
      ));

      expect(find.text('count: 0'), findsOneWidget);

      items.add('a');
      await tester.pump();
      expect(find.text('count: 1'), findsOneWidget);

      items.addAll(['b', 'c']);
      await tester.pump();
      expect(find.text('count: 3'), findsOneWidget);
    });

    testWidgets('Obx rebuilds when RxMap changes', (tester) async {
      final map = <String, int>{}.obs;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Obx(() => Text('keys: ${map.keys.length}')),
        ),
      ));

      expect(find.text('keys: 0'), findsOneWidget);

      map['a'] = 1;
      await tester.pump();
      expect(find.text('keys: 1'), findsOneWidget);

      map.addAll({'b': 2, 'c': 3});
      await tester.pump();
      expect(find.text('keys: 3'), findsOneWidget);
    });

    testWidgets('nested Obx widgets update independently', (tester) async {
      final outer = 0.obs;
      final inner = 0.obs;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Obx(() => Column(
                children: [
                  Text('outer: ${outer.value}'),
                  Obx(() => Text('inner: ${inner.value}')),
                ],
              )),
        ),
      ));

      expect(find.text('outer: 0'), findsOneWidget);
      expect(find.text('inner: 0'), findsOneWidget);

      inner.value = 5;
      await tester.pump();
      expect(find.text('outer: 0'), findsOneWidget);
      expect(find.text('inner: 5'), findsOneWidget);

      outer.value = 9;
      await tester.pump();
      expect(find.text('outer: 9'), findsOneWidget);
      expect(find.text('inner: 5'), findsOneWidget);
    });

    testWidgets('Obx rebuilds when bindStream updates Rx', (tester) async {
      final rx = 0.obs;
      final controller = StreamController<int>();
      rx.bindStream(controller.stream);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Obx(() => Text('val: ${rx.value}')),
        ),
      ));
      expect(find.text('val: 0'), findsOneWidget);

      controller.add(42);
      await tester.pump();
      expect(find.text('val: 42'), findsOneWidget);

      await controller.close();
      rx.close();
    });

    testWidgets(
        'bindStream continues after Obx drops Rx from conditional branch',
        (tester) async {
      final showBound = true.obs;
      final bound = 0.obs;
      final other = 0.obs;
      final controller = StreamController<int>();
      bound.bindStream(controller.stream);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Obx(() {
            if (showBound.value) {
              return Text('bound: ${bound.value}');
            }
            return Text('other: ${other.value}');
          }),
        ),
      ));

      controller.add(5);
      await tester.pump();
      expect(find.text('bound: 5'), findsOneWidget);

      showBound.value = false;
      await tester.pump();
      expect(find.text('other: 0'), findsOneWidget);

      // Obx 已 detach bound，但 bindStream 仍同步上游；UI 不应 rebuild
      controller.add(99);
      await tester.pump();
      expect(bound.value, 99);
      expect(find.text('other: 0'), findsOneWidget);

      showBound.value = true;
      await tester.pump();
      expect(find.text('bound: 99'), findsOneWidget);

      controller.add(100);
      await tester.pump();
      await tester.pump();
      expect(find.text('bound: 100'), findsOneWidget);

      await controller.close();
      bound.close();
      showBound.close();
      other.close();
    });

    testWidgets('Obx drops stale RxList dependency after conditional rebuild',
        (tester) async {
      final showList = true.obs;
      final items = <int>[].obs;
      final counter = 0.obs;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Obx(() {
            if (showList.value) {
              return Text('list: ${items.length}');
            }
            return Text('counter: ${counter.value}');
          }),
        ),
      ));

      expect(find.text('list: 0'), findsOneWidget);

      showList.value = false;
      await tester.pump();
      expect(find.text('counter: 0'), findsOneWidget);

      items.add(1);
      items.add(2);
      await tester.pump();
      expect(find.text('counter: 0'), findsOneWidget);

      counter.value = 7;
      await tester.pump();
      expect(find.text('counter: 7'), findsOneWidget);
    });
  });

  // ============================================================
  // ObxValue 本地状态
  // ============================================================
  group('ObxValue', () {
    testWidgets('ObxValue displays initial state', (tester) async {
      final state = false.obs;

      await tester.pumpWidget(ObxValueSwitch(state));
      expect(find.text('OFF'), findsOneWidget);
    });

    testWidgets('ObxValue updates display on toggle', (tester) async {
      final state = true.obs;

      await tester.pumpWidget(ObxValueSwitch(state));
      expect(find.text('ON'), findsOneWidget);

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(find.text('OFF'), findsOneWidget);
    });
  });

  // ============================================================
  // ObxLifecycleMixin 资源释放
  // ============================================================
  group('ObxLifecycleMixin', () {
    testWidgets('Rx stops notifying after dispose', (tester) async {
      int notifyCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: _DisposeNotifyTestWidget(
          onNotify: () => notifyCount++,
        ),
      ));

      // initState 中设置 value=1 触发一次通知
      expect(notifyCount, 1);

      // 从树中移除 Widget 触发 dispose
      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      // dispose 后不再有额外通知
      final countAfterDispose = notifyCount;
      await tester.pump();
      expect(notifyCount, countAfterDispose);
    });

    testWidgets('rx() returns the same Rx instance', (tester) async {
      RxInt? received;
      final original = 42.obs;

      await tester.pumpWidget(MaterialApp(
        home: _AutoDisposeReturnWidget(
          rx: original,
          onRx: (r) => received = r,
        ),
      ));

      expect(received, same(original));
    });

    testWidgets('no leak after multiple create/dispose cycles',
        (tester) async {
      for (var i = 0; i < 3; i++) {
        await tester.pumpWidget(const MaterialApp(
          home: _DisposeNotifyTestWidget(),
        ));
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      }
      // 无异常即通过
    });
  });

  // ============================================================
  // ObxWidget 生命周期
  // ============================================================
  group('ObxWidget lifecycle', () {
    testWidgets('setState after unmount does not crash', (tester) async {
      final counter = 0.obs;

      await tester.pumpWidget(CounterPage(counter));

      // 移除 Widget
      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      // 修改值不应崩溃（mounted 守卫生效）
      counter.value = 99;
      await tester.pump();
    });
  });
}

// ============================================================
// 测试辅助: ObxLifecycleMixin — 通知计数验证 dispose
// ============================================================

class _DisposeNotifyTestWidget extends StatefulWidget {
  final void Function()? onNotify;

  const _DisposeNotifyTestWidget({this.onNotify});

  @override
  State<StatefulWidget> createState() => _DisposeNotifyTestState();
}

class _DisposeNotifyTestState extends State<StatefulWidget>
    with ObxLifecycleMixin {
  @override
  void initState() {
    super.initState();
    final counter = rx(0.obs);
    listen<int>(counter, (_) {
      (widget as _DisposeNotifyTestWidget).onNotify?.call();
    });
    // 触发初始通知
    counter.value = 1;
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

// ============================================================
// 测试辅助: 验证 rx() 返回同一实例
// ============================================================

class _AutoDisposeReturnWidget extends StatefulWidget {
  final RxInt rx;
  final void Function(RxInt)? onRx;

  const _AutoDisposeReturnWidget({required this.rx, this.onRx});

  @override
  State<StatefulWidget> createState() => _AutoDisposeReturnState();
}

class _AutoDisposeReturnState extends State<StatefulWidget>
    with ObxLifecycleMixin {
  @override
  void initState() {
    super.initState();
    final result = rx((widget as _AutoDisposeReturnWidget).rx);
    (widget as _AutoDisposeReturnWidget).onRx?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
