import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ns_obx/ns_obx.dart';

void main() {
  setUp(() {
    RxInterface.resetProxy();
  });

  group('Rx boundary behavior after close', () {
    test('value setter does not notify after close', () {
      final rx = 0.obs;
      var count = 0;
      rx.listen((_) => count++);

      rx.close();
      rx.value = 1;

      expect(count, 0);
      expect(rx.value, 0);
    });

    test('refresh is no-op after close', () {
      final rx = 0.obs;
      var count = 0;
      rx.listen((_) => count++);

      rx.close();
      expect(() => rx.refresh(), returnsNormally);
      expect(count, 0);
    });

    test('listenAndPump returns subscription but does not emit after close',
        () {
      final rx = 0.obs;
      var count = 0;

      rx.close();
      final sub = rx.listenAndPump((_) => count++);

      expect(sub, isA<StreamSubscription<int>>());
      expect(count, 0);
      sub.cancel();
    });

    test('bindStream throws StateError when Rx is closed', () {
      final rx = 0.obs;
      final controller = StreamController<int>();
      rx.close();

      expect(
        () => rx.bindStream(controller.stream),
        throwsA(isA<StateError>()),
      );

      controller.close();
    });

    test('call() does not throw after close', () {
      final rx = 0.obs;
      rx.close();
      expect(() => rx(1), returnsNormally);
      expect(rx.value, 0);
    });
  });

  group('Signal boundary behavior after close', () {
    test('value is retained after close', () {
      final signal = Signal<int>();
      signal.emit(42);
      signal.close();
      expect(signal.value, 42);
    });

    test('listen returns subscription but does not notify after close', () {
      final signal = Signal<int>()..close();
      var count = 0;
      final sub = signal.listen((_) => count++);

      expect(sub, isA<SignalSubscription<int>>());
      expect(count, 0);
      sub.cancel();
    });

    test('close is idempotent', () {
      final signal = Signal<int>();
      signal.close();
      expect(signal.close, returnsNormally);
      expect(signal.isClosed, isTrue);
    });
  });

  group('Obx boundary behavior after widget unmount', () {
    testWidgets('setState after unmount does not crash', (tester) async {
      final counter = 0.obs;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: Obx(() => Text('${counter.value}'))),
      ));
      expect(find.text('0'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();

      counter.value = 1;
      await tester.pump();
      expect(find.text('1'), findsNothing);
    });
  });

  group('Worker boundary behavior', () {
    test('dispose is idempotent', () {
      final rx = 0.obs;
      final worker = ever(rx, (_) {});
      worker.dispose();
      expect(worker.dispose, returnsNormally);
      rx.close();
    });
  });

  group('RxDisposable boundary behavior', () {
    test('throws StateError when registering after dispose', () {
      final disposable = RxDisposable();
      disposable.dispose();

      expect(
        () => disposable.rx(0.obs),
        throwsA(isA<StateError>()),
      );
      expect(
        () => disposable.subscription(const Stream<int>.empty().listen((_) {})),
        throwsA(isA<StateError>()),
      );
      expect(
        () => disposable.worker(ever(0.obs, (_) {})),
        throwsA(isA<StateError>()),
      );
    });

    test('dispose is idempotent', () {
      final disposable = RxDisposable();
      final rx = disposable.rx(0.obs);
      disposable.dispose();
      expect(disposable.dispose, returnsNormally);
      expect(rx.isClosed, isTrue);
    });
  });
}
