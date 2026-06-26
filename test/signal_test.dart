import 'package:flutter_test/flutter_test.dart';
import 'package:ns_obx/ns_obx.dart';

void main() {
  // ============================================================
  // Signal 基础操作
  // ============================================================
  group('Signal basic operations', () {
    test('add triggers listener with value', () {
      final signal = Signal<int>();
      int? received;
      signal.listen((v) => received = v);

      signal.add(42);
      expect(received, 42);
    });

    test('hasListeners after adding subscription', () {
      final signal = Signal<int>();
      expect(signal.hasListeners, false);

      signal.listen((_) {});
      expect(signal.hasListeners, true);
    });

    test('length reflects subscription count', () {
      final signal = Signal<int>();
      expect(signal.length, 0);

      final sub1 = signal.listen((_) {});
      expect(signal.length, 1);

      final sub2 = signal.listen((_) {});
      expect(signal.length, 2);

      sub1.cancel();
      expect(signal.length, 1);

      sub2.cancel();
      expect(signal.length, 0);
    });

    test('value retains last added value', () {
      final signal = Signal<int>();
      expect(signal.value, isNull);

      signal.add(10);
      expect(signal.value, 10);

      signal.add(20);
      expect(signal.value, 20);
    });

    test('add without listeners updates value and skips notify', () {
      final signal = Signal<int>();
      expect(signal.hasListeners, false);

      signal.add(42);
      expect(signal.value, 42);
      expect(signal.hasListeners, false);
    });

    test('addError without listeners does not throw', () {
      final signal = Signal<int>();
      expect(signal.hasListeners, false);

      expect(() => signal.addError('err'), returnsNormally);
    });

    test('close marks signal as closed', () {
      final signal = Signal<int>();
      expect(signal.isClosed, false);

      signal.close();
      expect(signal.isClosed, true);
    });

    test('close notifies onDone', () {
      final signal = Signal<int>();
      var doneCalled = false;

      signal.listen((_) {}, onDone: () => doneCalled = true);
      signal.close();

      expect(doneCalled, true);
    });

    test('close retains last value', () {
      final signal = Signal<int>();
      signal.add(99);
      signal.close();

      expect(signal.value, 99);
    });
  });

  // ============================================================
  // Signal 并发安全
  // ============================================================
  group('Signal concurrent safety', () {
    test('add subscription during notification does not throw', () {
      final signal = Signal<int>();
      SignalSubscription<int>? lateSubToCancel;

      // Listener 1: during notification, adds a new listener
      signal.listen((v) {
        if (v == 1) {
          lateSubToCancel = signal.listen((_) {});
        }
      });

      // Should not throw
      signal.add(1);
      signal.add(2);

      expect(lateSubToCancel, isNotNull);
      // Clean up
      lateSubToCancel?.cancel();
    });

    test('remove subscription during notification does not throw', () {
      final signal = Signal<int>();
      SignalSubscription<int>? subToRemove;

      // Listener 1: during notification, cancels itself
      subToRemove = signal.listen((v) {
        if (v == 1) {
          subToRemove?.cancel();
        }
      });

      signal.listen((_) {});

      // Should not throw
      signal.add(1);
      signal.add(2);
    });

    test('pending additions processed after notification', () {
      final signal = Signal<int>();
      final received = <int>[];

      // First listener: when receiving 1, adds second listener
      signal.listen((v) {
        received.add(v);
        if (v == 1) {
          signal.listen((inner) => received.add(inner + 100));
        }
      });

      // The second listener added during notification 1 should
      // be processed after the current notification batch
      signal.add(1);
      // Second add should reach both listeners
      signal.add(2);

      // First listener: 1, 2
      // Second listener: starts at 2 -> 102
      expect(received, [1, 2, 102]);
    });

    test('pending removals processed after notification', () {
      final signal = Signal<int>();
      final received = <int>[];
      late SignalSubscription<int> sub2;

      final sub1 = signal.listen((v) {
        received.add(v);
        if (v == 1) {
          sub2.cancel();
        }
      });

      sub2 = signal.listen((v) {
        received.add(v + 50);
      });

      // During notification of value 1, sub2 is cancelled
      signal.add(1);
      // sub2 should be removed for the next notification
      signal.add(2);

      // Value 1: both listeners fire -> 1, 51
      // Value 2: only sub1 fires -> 2
      expect(received, [1, 51, 2]);

      sub1.cancel();
    });

    test('multiple add/remove during notification counts correctly', () {
      final signal = Signal<int>();
      late SignalSubscription<int> sub1, sub2, sub3, sub4;

      final received = <int>[];

      sub1 = signal.listen((v) {
        received.add(v);
        if (v == 1) {
          sub2.cancel();
          sub3 = signal.listen((inner) => received.add(inner + 200));
        }
        if (v == 2) {
          sub4 = signal.listen((inner) => received.add(inner + 300));
        }
      });

      sub2 = signal.listen((v) => received.add(v + 100));

      // Notify 1: sub2 cancelled, sub3 added as pending
      signal.add(1);
      // Notify 2: listeners = [sub1, sub3], sub4 added as pending
      signal.add(2);
      // Notify 3: listeners = [sub1, sub3, sub4]
      signal.add(3);

      // sub1: 1, 2, 3
      // sub2: 101 (then cancelled before value 2)
      // sub3: 202, 203
      // sub4: 303
      expect(received, [1, 101, 2, 202, 3, 203, 303]);

      sub1.cancel();
      sub3.cancel();
      sub4.cancel();
    });

    test('length is correct after concurrent modifications', () {
      final signal = Signal<int>();
      late SignalSubscription<int> sub2;

      signal.listen((v) {
        if (v == 1) {
          sub2.cancel();
          // Also add new listener
          expect(signal.length, 2); // still 2 during notification
        }
      });

      sub2 = signal.listen((_) {});

      expect(signal.length, 2);
      signal.add(1);
      // sub2 cancelled
      expect(signal.length, 1);
    });

    test('listener throw resets busy and processes pending', () {
      final signal = Signal<int>();
      final received = <int>[];
      late SignalSubscription<int> badSub;

      badSub = signal.listen((v) {
        badSub.cancel();
        throw StateError('boom');
      });

      signal.listen((v) => received.add(v));

      expect(() => signal.add(1), throwsStateError);
      expect(received, isEmpty);

      signal.add(2);
      expect(received, [2]);
    });
  });

  // ============================================================
  // Signal 生命周期回调
  // ============================================================
  group('Signal lifecycle callbacks', () {
    test('onListen fires when subscription added', () {
      var listenCalled = false;
      final signal = Signal<int>(onListen: () => listenCalled = true);

      expect(listenCalled, false);
      signal.listen((_) {});
      expect(listenCalled, true);
    });

    test('onCancel fires when subscription cancelled', () {
      var cancelCalled = false;
      final signal = Signal<int>();

      final sub = SignalSubscription<int>(
        (s) => true,
        onCancel: () => cancelCalled = true,
      );
      signal.addSubscription(sub);
      sub.cancel();

      expect(cancelCalled, true);
    });

    test('pause and resume callbacks', () {
      var pauseCalled = false;
      var resumeCalled = false;

      final signal = Signal<int>();
      final sub = SignalSubscription<int>(
        (s) => true,
        onPause: () => pauseCalled = true,
        onResume: () => resumeCalled = true,
      );

      signal.addSubscription(sub);

      expect(sub.isPaused, false);
      sub.pause();
      expect(sub.isPaused, true);
      expect(pauseCalled, true);

      sub.resume();
      expect(sub.isPaused, false);
      expect(resumeCalled, true);

      sub.cancel();
    });

    test('paused subscription does not receive data', () {
      final signal = Signal<int>();
      int? received;

      final sub = signal.listen((v) => received = v);
      sub.pause();

      signal.add(42);
      expect(received, isNull);

      sub.resume();
      signal.add(99);
      expect(received, 99);

      sub.cancel();
    });
  });

  // ============================================================
  // Signal Error handling
  // ============================================================
  group('Signal error handling', () {
    test('addError triggers onError', () {
      final signal = Signal<int>();
      Object? errorReceived;
      StackTrace? stackReceived;

      signal.listen(
        (_) {},
        onError: (Object e, [StackTrace? s]) {
          errorReceived = e;
          if (s != null) {
            stackReceived = s;
          }
        },
      );

      final stack = StackTrace.current;
      signal.addError('boom', stack);
      expect(errorReceived, 'boom');
      expect(stackReceived, stack);
    });

    test('cancelOnError removes subscriber on error', () {
      final signal = Signal<int>();
      final received = <int>[];

      signal.listen(
        (v) => received.add(v),
        cancelOnError: true,
      );

      signal.listen((v) => received.add(v + 100));

      signal.add(1);
      signal.addError('error');
      // After error, first subscriber cancelled
      signal.add(2);

      expect(received, [1, 101, 102]);
    });
  });

  // ============================================================
  // Signal stream adapter
  // ============================================================
  group('Signal stream adapter', () {
    test('stream emits values', () {
      final signal = Signal<int>();
      final received = <int>[];

      signal.stream.listen((v) => received.add(v));

      signal.add(1);
      signal.add(2);
      signal.add(3);

      expect(received, [1, 2, 3]);
    });

    test('stream getter returns cached adapter', () {
      final signal = Signal<int>();
      expect(identical(signal.stream, signal.stream), isTrue);
    });
  });
}
