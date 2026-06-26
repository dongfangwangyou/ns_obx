import 'package:flutter_test/flutter_test.dart';
import 'package:ns_obx/ns_obx.dart';

void main() {
  group('Workers', () {
    test('ever fires on each change', () {
      final count = 0.obs;
      final values = <int>[];

      final w = ever(count, values.add);

      count.value = 1;
      count.value = 2;
      count.value = 2; // same value, no notification
      count.value = 3;

      expect(values, [1, 2, 3]);
      w.dispose();
    });

    test('ever does not fire on subscribe', () {
      final count = 5.obs;
      var called = false;

      ever(count, (_) => called = true);

      expect(called, isFalse);
    });

    test('once fires only once', () {
      final count = 0.obs;
      var callCount = 0;

      once(count, (_) => callCount++);

      count.value = 1;
      count.value = 2;
      count.value = 3;

      expect(callCount, 1);
    });

    test('debounce fires after quiet period', () async {
      final query = ''.obs;
      final values = <String>[];

      debounce(
        query,
        values.add,
        time: const Duration(milliseconds: 50),
      );

      query.value = 'a';
      query.value = 'ab';
      query.value = 'abc';

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(values, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(values, ['abc']);
    });

    test('debounce resets timer on rapid changes', () async {
      final query = ''.obs;
      final values = <String>[];

      debounce(
        query,
        values.add,
        time: const Duration(milliseconds: 50),
      );

      query.value = 'x';
      await Future<void>.delayed(const Duration(milliseconds: 40));
      query.value = 'xy';
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(values, isEmpty);

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(values, ['xy']);
    });

    test('debounce leading fires immediately then suppresses', () async {
      final query = ''.obs;
      final values = <String>[];

      debounce(
        query,
        values.add,
        time: const Duration(milliseconds: 50),
        leading: true,
      );

      query.value = 'a';
      expect(values, ['a']);

      query.value = 'ab';
      query.value = 'abc';
      expect(values, ['a']);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      query.value = 'd';
      expect(values, ['a', 'd']);
    });

    test('debounce leading resets window on each change', () async {
      final query = ''.obs;
      final values = <String>[];

      debounce(
        query,
        values.add,
        time: const Duration(milliseconds: 50),
        leading: true,
      );

      query.value = 'x';
      expect(values, ['x']);

      await Future<void>.delayed(const Duration(milliseconds: 40));
      query.value = 'y';
      expect(values, ['x']);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      query.value = 'z';
      expect(values, ['x', 'z']);
    });

    test('Worker.dispose cancels subscription', () {
      final count = 0.obs;
      var callCount = 0;

      final w = ever(count, (_) => callCount++);

      count.value = 1;
      expect(callCount, 1);

      w.dispose();
      count.value = 2;
      expect(callCount, 1);
    });

    test('Worker.dispose cancels pending debounce', () async {
      final query = ''.obs;
      var called = false;

      final w = debounce(
        query,
        (_) => called = true,
        time: const Duration(milliseconds: 50),
      );

      query.value = 'test';
      w.dispose();

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(called, isFalse);
    });

    test('interval fires immediately then throttles', () async {
      final count = 0.obs;
      final values = <int>[];

      interval(
        count,
        values.add,
        time: const Duration(milliseconds: 50),
      );

      count.value = 1;
      count.value = 2;
      count.value = 3;
      expect(values, [1]);

      await Future<void>.delayed(const Duration(milliseconds: 60));
      count.value = 4;
      expect(values, [1, 4]);
    });

    test('interval does not fire on subscribe', () {
      final count = 5.obs;
      var called = false;

      interval(count, (_) => called = true);

      expect(called, isFalse);
    });

    test('Worker.dispose cancels interval window', () async {
      final count = 0.obs;
      final values = <int>[];

      final w = interval(
        count,
        values.add,
        time: const Duration(milliseconds: 50),
      );

      count.value = 1;
      expect(values, [1]);

      w.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      count.value = 2;
      expect(values, [1]);
    });
  });
}
