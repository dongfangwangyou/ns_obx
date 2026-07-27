import 'package:flutter_test/flutter_test.dart';
import 'package:ns_obx/ns_obx.dart';

/// 轻量级性能回归测试。
///
/// 这些测试不断言绝对耗时（避免 CI 抖动），而是验证关键操作在合理规模下
/// 仍保持正确行为与预期通知次数，从而捕获性能退化或重复通知回归。
void main() {
  group('Rx notification benchmarks', () {
    test('1000 sequential RxInt assignments produce 1000 notifications', () {
      final rx = 0.obs;
      var count = 0;
      rx.listen((_) => count++);

      const iterations = 1000;
      for (var i = 0; i < iterations; i++) {
        rx.value = i;
      }

      expect(count, iterations);
    });

    test('RxList.update coalesces 1000 mutations into single notification', () {
      final list = <int>[].obs;
      var count = 0;
      list.listen((_) => count++);

      list.update((items) {
        for (var i = 0; i < 1000; i++) {
          items.add(i);
        }
      });

      expect(list.length, 1000);
      expect(count, 1);
    });

    test('Signal notifies 1000 listeners without error', () {
      final signal = Signal<int>();
      final counts = List<int>.filled(100, 0);
      final subscriptions = <SignalSubscription<int>>[];

      for (var i = 0; i < counts.length; i++) {
        subscriptions.add(signal.listen((_) => counts[i]++));
      }

      const iterations = 1000;
      for (var i = 0; i < iterations; i++) {
        signal.emit(i);
      }

      for (final count in counts) {
        expect(count, iterations);
      }

      for (final sub in subscriptions) {
        sub.cancel();
      }
      signal.close();
    });

    test('select-derived Rx updates 1000 times through parent', () {
      final source = 0.obs;
      final derived = source.select((v) => v * 2);
      var count = 0;
      derived.listen((_) => count++);

      const iterations = 1000;
      for (var i = 0; i < iterations; i++) {
        source.value = i;
      }

      expect(derived.value, 1998);
      expect(count, iterations);

      source.close();
      expect(derived.isClosed, true);
    });

    test('RxDisposable bulk dispose of 1000 Rx variables', () {
      final disposable = RxDisposable();
      final rxs = <RxInt>[];

      for (var i = 0; i < 1000; i++) {
        rxs.add(disposable.rx(i.obs));
      }

      disposable.dispose();

      for (final rx in rxs) {
        expect(rx.isClosed, true);
      }
    });
  });
}
