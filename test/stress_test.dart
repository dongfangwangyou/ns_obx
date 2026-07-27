import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ns_obx/ns_obx.dart';

void main() {
  setUp(() {
    RxInterface.resetProxy();
  });

  group('Widget lifecycle stress', () {
    testWidgets('RxLifecycleMixin survives 100 mount/unmount cycles',
        (tester) async {
      final counter = 0.obs;

      for (var i = 0; i < 100; i++) {
        await tester.pumpWidget(MaterialApp(
          home: _StressWidget(counter),
        ));
        counter.value++;
        await tester.pump();

        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      }

      expect(counter.isClosed, isFalse);
      counter.close();
    });

    testWidgets('conditional branch sweep handles 500 rapid switches',
        (tester) async {
      final showA = true.obs;
      final a = 0.obs;
      final b = 0.obs;
      var buildCount = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Obx(() {
            buildCount++;
            if (showA.value) {
              return Text('A: ${a.value}');
            }
            return Text('B: ${b.value}');
          }),
        ),
      ));

      for (var i = 0; i < 500; i++) {
        showA.toggle();
        if (showA.value) {
          a.value = i;
        } else {
          b.value = i;
        }
        await tester.pump();
      }

      expect(find.text('A: ${a.value}'), findsOneWidget);
      expect(buildCount, lessThan(1200)); // 允许少量额外 rebuild

      showA.close();
      a.close();
      b.close();
    });
  });

  group('Workers stress', () {
    test('debounce survives 1000 rapid inputs', () async {
      final query = ''.obs;
      final calls = <String>[];
      final worker = debounce(
        query,
        (q) => calls.add(q),
        time: const Duration(milliseconds: 10),
      );

      for (var i = 0; i < 1000; i++) {
        query.value = 'q$i';
      }

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(calls.length, lessThan(10));
      expect(calls.last, 'q999');

      worker.dispose();
      query.close();
    });

    test('interval throttles 1000 rapid inputs', () async {
      final ticks = 0.obs;
      final calls = <int>[];
      final worker = interval(
        ticks,
        (v) => calls.add(v),
        time: const Duration(milliseconds: 10),
      );

      for (var i = 0; i < 1000; i++) {
        ticks.value = i;
      }

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(calls.length, lessThan(10));
      expect(calls.first, 0);

      worker.dispose();
      ticks.close();
    });
  });

  group('Collections stress', () {
    test('RxList batch update with 10000 items', () {
      final list = <int>[].obs;
      var count = 0;
      list.listen((_) => count++);

      list.update((items) {
        for (var i = 0; i < 10000; i++) {
          items.add(i);
        }
      });

      expect(list.length, 10000);
      expect(count, 1);
      list.close();
    });

    test('RxMap batch update with 5000 entries', () {
      final map = <String, int>{}.obs;
      var count = 0;
      map.listen((_) => count++);

      map.batchUpdate((m) {
        for (var i = 0; i < 5000; i++) {
          m['k$i'] = i;
        }
      });

      expect(map.length, 5000);
      expect(count, 1);
      map.close();
    });
  });

  group('Signal event bus stress', () {
    test('1000 events across 50 subscribers', () {
      final bus = Signal<int>();
      final counts = List<int>.filled(50, 0);
      final subs = <SignalSubscription<int>>[];

      for (var i = 0; i < counts.length; i++) {
        subs.add(bus.listen((_) => counts[i]++));
      }

      for (var i = 0; i < 1000; i++) {
        bus.emit(i);
      }

      for (final count in counts) {
        expect(count, 1000);
      }

      for (final sub in subs) {
        sub.cancel();
      }
      bus.close();
    });
  });

  group('Real-world search scenario', () {
    testWidgets('search with debounce and loading state', (tester) async {
      final query = ''.obs;
      final loading = false.obs;
      final results = <String>[].obs;
      final worker = debounce(
        query,
        (q) {
          loading.value = true;
          results.value = List.generate(10, (i) => '$q-$i');
          loading.value = false;
        },
        time: const Duration(milliseconds: 10),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Obx(() => Column(
                children: [
                  if (loading.value) const Text('Loading'),
                  Text('Results: ${results.length}'),
                ],
              )),
        ),
      ));

      for (var i = 0; i < 50; i++) {
        query.value = 'term$i';
      }
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Results: 10'), findsOneWidget);

      worker.dispose();
      query.close();
      loading.close();
      results.close();
    });
  });
}

class _StressWidget extends StatefulWidget {
  final RxInt counter;
  const _StressWidget(this.counter);

  @override
  State<_StressWidget> createState() => _StressWidgetState();
}

class _StressWidgetState extends State<_StressWidget> with RxLifecycleMixin {
  @override
  Widget build(BuildContext context) {
    return Obx(() => Text('${widget.counter.value}'));
  }
}
