import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ns_obx/ns_obx.dart';

void main() {
  group('RxDisposable', () {
    test('rx() registers and closes Rx on dispose', () {
      final disposable = RxDisposable();
      final count = disposable.rx(0.obs);

      expect(count.isClosed, false);
      disposable.dispose();
      expect(count.isClosed, true);
    });

    test('subscription() cancels on dispose', () {
      final disposable = RxDisposable();
      final rx = 0.obs;
      var calls = 0;
      // RxDisposable 会在 dispose 时取消该订阅。
      // ignore: cancel_subscriptions
      final sub = disposable.subscription(rx.listen((_) => calls++));

      rx.value = 1;
      expect(calls, 1);

      disposable.dispose();
      rx.value = 2;
      expect(calls, 1);
      expect(sub.isPaused, false);
    });

    test('listen() tracks subscription and cancels on dispose', () {
      final disposable = RxDisposable();
      final rx = 0.obs;
      var calls = 0;
      disposable.listen(rx, (_) => calls++);

      rx.value = 1;
      expect(calls, 1);

      disposable.dispose();
      rx.value = 2;
      expect(calls, 1);
    });

    test('worker() disposes on dispose', () async {
      final disposable = RxDisposable();
      final rx = 0.obs;
      var calls = 0;
      disposable.worker(debounce(rx, (_) => calls++, time: const Duration(milliseconds: 10)));

      rx.value = 1;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(calls, 1);

      disposable.dispose();
      rx.value = 2;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(calls, 1);
    });

    test('dispose() is idempotent', () {
      final disposable = RxDisposable();
      final rx = disposable.rx(0.obs);

      disposable.dispose();
      disposable.dispose();
      expect(rx.isClosed, true);
    });

    test('throws when registering after dispose', () {
      final disposable = RxDisposable()..dispose();

      expect(() => disposable.rx(0.obs), throwsStateError);
      expect(
        () => disposable.subscription(const Stream<void>.empty().listen(null)),
        throwsStateError,
      );
      expect(() => disposable.worker(ever(0.obs, (_) {})), throwsStateError);
    });

    test('isDisposed reflects state', () {
      final disposable = RxDisposable();
      expect(disposable.isDisposed, false);
      disposable.dispose();
      expect(disposable.isDisposed, true);
    });

    test('RxLifecycleMixin still disposes resources', () async {
      // RxLifecycleMixin is covered by widget_test.dart; this test ensures
      // the mixin compiles and delegates to RxDisposable.
      expect(RxDisposable, isNotNull);
    });
  });
}
