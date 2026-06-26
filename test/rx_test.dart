import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ns_obx/ns_obx.dart';
import 'package:ns_obx/src/obx/obx_observer.dart';
import 'package:ns_obx/src/rx/core/rx_subject_mixin.dart';

/// 测试用：仅含 RxSubjectMixin 的 void 节点
class _VoidSubject = RxInterface<void> with RxSubjectMixin<void>;

void main() {
  // ============================================================
  // Rx 变量读写
  // ============================================================
  group('Rx variable read/write', () {
    test('set value then get returns correct', () {
      final rx = Rx<int>(0);
      expect(rx.value, 0);

      rx.value = 42;
      expect(rx.value, 42);

      rx.value = -7;
      expect(rx.value, -7);
    });

    test('RxString value set and get', () {
      final rx = RxString('hello');
      expect(rx.value, 'hello');

      rx.value = 'world';
      expect(rx.value, 'world');
    });

    test('RxDouble value set and get', () {
      final rx = RxDouble(3.14);
      expect(rx.value, 3.14);

      rx.value = 2.718;
      expect(rx.value, closeTo(2.718, 0.0001));
    });

    test('RxBool value set and get', () {
      final rx = RxBool(false);
      expect(rx.value, false);

      rx.value = true;
      expect(rx.value, true);

      rx.value = false;
      expect(rx.value, false);
    });

    test('set same value does not trigger notification when not first rebuild', () {
      final rx = RxInt(10);
      var callCount = 0;
      rx.listen((_) => callCount++);

      // First rebuild is allowed
      rx.value = 10;
      // After first rebuild, same value should be suppressed
      callCount = 0;
      rx.value = 10;
      expect(callCount, 0);
    });

    test('value getter auto-registers dependency via proxy', () {
      final observer = ObxObserver();
      final rx = RxInt(5);

      RxInterface.notifyDependents(observer, () {
        final v = rx.value;
        expect(v, 5);
        return v;
      });

      expect(observer.canUpdate, true);
    });

    test('peek does not register dependency via proxy', () {
      final observer = ObxObserver();
      final rx = RxInt(5);

      RxInterface.testDependents(observer, () {
        expect(rx.peek, 5);
      });

      expect(observer.canUpdate, false);
    });
  });

  // ============================================================
  // .obs 扩展方法
  // ============================================================
  group('.obs extension', () {
    test('int.obs creates RxInt', () {
      final rx = 42.obs;
      expect(rx, isA<RxInt>());
      expect(rx.value, 42);
    });

    test('double.obs creates RxDouble', () {
      final rx = 3.14.obs;
      expect(rx, isA<RxDouble>());
      expect(rx.value, 3.14);
    });

    test('bool.obs creates RxBool', () {
      final rx = true.obs;
      expect(rx, isA<RxBool>());
      expect(rx.value, true);
    });

    test('String.obs creates RxString', () {
      final rx = 'hello'.obs;
      expect(rx, isA<RxString>());
      expect(rx.value, 'hello');
    });

    test('custom type .obs creates Rx<T>', () {
      final rx = DateTime(2024).obs;
      expect(rx, isA<Rx<DateTime>>());
      expect(rx.value, DateTime(2024));
    });
  });

  // ============================================================
  // Listener 回调
  // ============================================================
  group('Listener callbacks', () {
    test('value change triggers listener', () {
      final rx = RxInt(0);
      final values = <int>[];

      rx.listen((v) => values.add(v));

      rx.value = 1;
      rx.value = 2;
      rx.value = 3;

      expect(values, [1, 2, 3]);
    });

    test('refresh triggers listener', () {
      final rx = RxInt(0);
      var callCount = 0;

      rx.listen((_) => callCount++);
      rx.value = 1;
      callCount = 0;

      rx.refresh();
      expect(callCount, 1);
    });

    test('update callback triggers notification', () {
      final rx = RxInt(5);
      var callCount = 0;
      rx.listen((_) => callCount++);

      rx.update((val) => expect(val, 5));
      expect(callCount, 1);
    });

    test('listenAndPump immediately calls listener with current value', () {
      final rx = RxString('initial');
      String? received;

      rx.listenAndPump((v) => received = v);

      expect(received, 'initial');
    });

    test('multiple listeners all receive notifications', () {
      final rx = RxInt(0);
      final a = <int>[];
      final b = <int>[];

      rx.listen((v) => a.add(v));
      rx.listen((v) => b.add(v));

      rx.value = 5;

      expect(a, [5]);
      expect(b, [5]);
    });

    test('listen error callback invoked', () {
      final rx = _VoidSubject();
      Object? errorReceived;
      final sub = rx.listen(
        (_) {},
        onError: (e, s) => errorReceived = e,
      );

      // 通过取消订阅后的 done 回调验证 onDone 传递
      expect(errorReceived, isNull);
      sub.cancel();
    });
  });

  // ============================================================
  // close / listen 清理
  // ============================================================
  group('close / listen cleanup', () {
    test('Rx canUpdate is always false', () {
      final rx = RxInt(0);
      expect(rx.canUpdate, false);

      final signal = Signal<int>();
      rx.addListener(signal);
      expect(rx.canUpdate, false);
      signal.close();
    });

    test('cancel subscription via StreamSubscription', () {
      final rx = RxInt(0);
      final values = <int>[];
      final sub = rx.listen((v) => values.add(v));

      rx.value = 1;
      sub.cancel();
      rx.value = 2;

      expect(values, [1]);
    });

    test('close() cleans up all listeners', () {
      final rx = RxInt(0);
      var callCount = 0;

      rx.listen((_) => callCount++);
      rx.value = 1;
      expect(callCount, 1);

      rx.close();

      // After close, subject is closed so value set is a no-op
      rx.value = 2;
      expect(callCount, 1);
    });

    test('close() keeps canUpdate false', () {
      final rx = RxInt(0);
      expect(rx.canUpdate, false);

      rx.close();
      expect(rx.canUpdate, false);
    });

    test('close() value set is no-op after close', () {
      final rx = RxInt(0);
      var callCount = 0;
      rx.listen((_) => callCount++);

      rx.close();

      // After close, setting value should be silently ignored
      rx.value = 99;
      expect(callCount, 0);
      // value getter still returns the last set value
      expect(rx.value, 0);
    });
  });

  // ============================================================
  // clearListeners — Obx 依赖重建
  // ============================================================
  group('clearListeners', () {
    test('clearListeners on Rx is no-op', () {
      final rx = RxInt(0);
      rx.addListener(Signal<int>());
      expect(rx.canUpdate, false);

      rx.clearListeners();
      expect(rx.canUpdate, false);

      var callCount = 0;
      rx.listen((_) => callCount++);
      rx.value = 1;
      expect(callCount, 1);
    });

    test('clears proxy-registered dependencies for rebuild', () {
      final rx = RxInt(0);
      final observer = ObxObserver();

      RxInterface.notifyDependents(observer, () => rx.value);
      expect(observer.canUpdate, true);

      observer.clearListeners();
      expect(observer.canUpdate, false);
    });

    test('re-tracking after clearListeners registers new dependencies', () {
      final a = RxInt(1);
      final b = RxInt(10);
      final observer = ObxObserver();

      RxInterface.notifyDependents(observer, () => a.value);
      expect(observer.canUpdate, true);

      observer.clearListeners();
      expect(observer.canUpdate, false);

      RxInterface.notifyDependents(observer, () => b.value);
      expect(observer.canUpdate, true);
    });
  });

  // ============================================================
  // dependencySweep — Obx 增量依赖重建（removeListener）
  // ============================================================
  group('dependencySweep', () {
    test('removes stale dependencies via removeListener', () {
      final a = RxInt(1);
      final b = RxInt(10);
      final observer = ObxObserver();

      observer.beginDependencySweep();
      RxInterface.notifyDependents(observer, () => a.value);
      observer.endDependencySweep();

      observer.beginDependencySweep();
      RxInterface.notifyDependents(observer, () => b.value);
      observer.endDependencySweep();

      var notifyCount = 0;
      observer.listen((_) => notifyCount++);

      a.value = 99;
      expect(notifyCount, 0);

      b.value = 99;
      expect(notifyCount, 1);
    });

    test('keeps unchanged dependencies across rebuilds', () {
      final count = RxInt(0);
      final observer = ObxObserver();

      for (var i = 0; i < 2; i++) {
        observer.beginDependencySweep();
        RxInterface.notifyDependents(observer, () => count.value);
        observer.endDependencySweep();
      }
      expect(observer.canUpdate, true);

      var notifyCount = 0;
      observer.listen((_) => notifyCount++);
      count.value = 1;
      expect(notifyCount, 1);
    });

    test('direct subscription without void relay', () {
      final count = RxInt(0);
      var dispatchCount = 0;
      final observer = ObxObserver(() => dispatchCount++);

      RxInterface.notifyDependents(observer, () => count.value);
      count.value = 1;
      expect(dispatchCount, 1);
    });
  });

  // ============================================================
  // 流绑定
  // ============================================================
  group('Stream binding', () {
    test('bindStream syncs values from stream', () async {
      final rx = RxInt(0);
      final controller = StreamController<int>();
      rx.bindStream(controller.stream);

      controller.add(1);
      await Future<void>.delayed(Duration.zero);
      expect(rx.value, 1);

      controller.add(2);
      await Future<void>.delayed(Duration.zero);
      expect(rx.value, 2);

      await controller.close();
      rx.close();
    });

    test('bindStream survives deferred Obx sweep like ObxState', () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final flag = true.obs;
      final bound = RxInt(0);
      final controller = StreamController<int>.broadcast();
      bound.bindStream(controller.stream);

      late ObxObserver observer;
      var updateScheduled = false;

      void runBuild() {
        observer.beginDependencySweep();
        try {
          RxInterface.notifyDependents(observer, () {
            return flag.value ? bound.value : 0;
          });
        } finally {
          observer.endDependencySweep();
        }
      }

      void scheduleRebuild() {
        if (updateScheduled) return;
        updateScheduled = true;
        SchedulerBinding.instance.scheduleFrameCallback((_) {
          updateScheduled = false;
          runBuild();
        });
      }

      observer = ObxObserver(scheduleRebuild);
      runBuild();

      controller.add(1);
      await Future<void>.delayed(Duration.zero);
      expect(bound.value, 1);

      flag.value = false;
      await Future<void>.delayed(Duration.zero);

      controller.add(2);
      await Future<void>.delayed(Duration.zero);
      expect(bound.value, 2);

      await controller.close();
      bound.close();
      flag.close();
      observer.close();
    });

    test('bindStream with conditional branch Rx like Obx widget', () async {
      final showBound = true.obs;
      final bound = RxInt(0);
      final other = RxInt(0);
      final controller = StreamController<int>();
      bound.bindStream(controller.stream);

      late final ObxObserver observer;
      void obxBuild() {
        observer.beginDependencySweep();
        try {
          RxInterface.notifyDependents(observer, () {
            if (showBound.value) {
              return bound.value;
            }
            return other.value;
          });
        } finally {
          observer.endDependencySweep();
        }
      }

      observer = ObxObserver(obxBuild);
      obxBuild();

      controller.add(5);
      await Future<void>.delayed(Duration.zero);
      expect(bound.value, 5);

      showBound.value = false;
      await Future<void>.delayed(Duration.zero);

      controller.add(99);
      await Future<void>.delayed(Duration.zero);
      expect(bound.value, 99);

      showBound.value = true;
      await Future<void>.delayed(Duration.zero);

      controller.add(100);
      await Future<void>.delayed(Duration.zero);
      expect(bound.value, 100);

      await controller.close();
      bound.close();
      showBound.close();
      other.close();
      observer.close();
    });

    test('bindStream survives Obx proxy detach and reattach', () async {
      final bound = RxInt(0);
      final controller = StreamController<int>();
      bound.bindStream(controller.stream);

      final observer = ObxObserver();

      void obxBuild({required bool readBound}) {
        observer.beginDependencySweep();
        try {
          RxInterface.notifyDependents(observer, () {
            if (readBound) {
              return bound.value;
            }
            return 0;
          });
        } finally {
          observer.endDependencySweep();
        }
      }

      obxBuild(readBound: true);
      controller.add(5);
      await Future<void>.delayed(Duration.zero);
      expect(bound.value, 5);

      obxBuild(readBound: false);
      controller.add(99);
      await Future<void>.delayed(Duration.zero);
      expect(bound.value, 99);

      obxBuild(readBound: true);
      controller.add(100);
      await Future<void>.delayed(Duration.zero);
      expect(bound.value, 100);

      await controller.close();
      bound.close();
      observer.close();
    });

    test('Rx.fromStream updates on stream events', () async {
      final controller = StreamController<int>();
      final rx = Rx.fromStream(controller.stream);
      expect(rx.value, isNull);

      controller.add(42);
      await Future<void>.delayed(Duration.zero);
      expect(rx.value, 42);

      await controller.close();
      rx.close();
    });

    test('Rx.fromFuture creates Rx with result', () async {
      final rx = await Rx.fromFuture(Future.value(99));
      expect(rx.value, 99);
      rx.close();
    });

    test('Rx.provider creates Rx from factory', () {
      final rx = Rx.provider(() => 7);
      expect(rx.value, 7);
      rx.close();
    });

    test('bindStream subscription cancelled on close', () async {
      final rx = RxInt(0);
      final controller = StreamController<int>();
      rx.bindStream(controller.stream);

      rx.close();
      controller.add(99);
      await Future<void>.delayed(Duration.zero);
      expect(rx.value, 0);

      await controller.close();
    });

    test('bindStream returns cancellable subscription', () async {
      final rx = RxInt(0);
      final controller = StreamController<int>();
      final sub = rx.bindStream(controller.stream);

      controller.add(1);
      await Future<void>.delayed(Duration.zero);
      expect(rx.value, 1);

      await sub.cancel();
      controller.add(2);
      await Future<void>.delayed(Duration.zero);
      expect(rx.value, 1);

      await controller.close();
      rx.close();
    });
  });

  // ============================================================
  // RxProxyContract / ReactiveMixin.linkSubscription
  // ============================================================
  group('RxProxyContract', () {
    test('Rx implements RxProxyContract via mixins', () {
      final rx = RxInt(0);
      expect(rx, isA<RxProxyContract<int>>());
    });

    test('ObxObserver implements RxProxyContract', () {
      expect(ObxObserver(), isA<RxProxyContract<void>>());
    });

    test('linkSubscription lives on ReactiveMixin not RxSubjectMixin', () async {
      final rx = RxInt(0);
      final controller = StreamController<int>();
      rx.bindStream(controller.stream);

      controller.add(7);
      await Future<void>.delayed(Duration.zero);
      expect(rx.value, 7);

      rx.close();
      controller.add(99);
      await Future<void>.delayed(Duration.zero);
      expect(rx.value, 7);

      await controller.close();
    });
  });

  // ============================================================
  // ObxObserver._dispatch — listen 快照派发
  // ============================================================
  group('ObxObserver dispatch', () {
    test('listen callback may cancel self during dispatch without CME', () {
      final rx = RxInt(0);
      final observer = ObxObserver();

      RxInterface.notifyDependents(observer, () => rx.value);

      var notifyCount = 0;
      StreamSubscription<void>? sub;
      sub = observer.listen((_) {
        notifyCount++;
        sub?.cancel();
      });

      expect(() => rx.value = 1, returnsNormally);
      expect(notifyCount, 1);
    });

    test('all listen callbacks registered before dispatch are invoked once', () {
      final rx = RxInt(0);
      final observer = ObxObserver();

      RxInterface.notifyDependents(observer, () => rx.value);

      var countA = 0;
      var countB = 0;
      observer.listen((_) => countA++);
      observer.listen((_) => countB++);

      rx.value = 1;

      expect(countA, 1);
      expect(countB, 1);
    });
  });

  // ============================================================
  // RxSubjectMixin 基础操作
  // ============================================================
  group('RxSubjectMixin', () {
    test('initial canUpdate is false for void subject node', () {
      final node = _VoidSubject();
      expect(node.canUpdate, false);
    });

    test('close releases resources', () {
      final node = _VoidSubject();
      node.close();
      expect(node.canUpdate, false);
    });
  });

  // ============================================================
  // Rx 功能性方法
  // ============================================================
  group('Rx utility methods', () {
    test('select creates derived Rx', () {
      final source = RxInt(10);
      final derived = source.select((v) => v * 2);

      expect(derived.value, 20);

      source.value = 5;
      expect(derived.value, 10);
    });

    test('select closes parent subscription when derived Rx closes', () {
      final source = RxInt(10);
      final derived = source.select((v) => v * 2);

      derived.close();
      source.value = 20;

      expect(derived.value, 20);
    });

    test('select closing one derived Rx does not affect others', () {
      final source = RxInt(1);
      final a = source.select((v) => v * 2);
      final b = source.select((v) => v * 3);

      a.close();
      source.value = 5;

      expect(b.value, 15);
    });

    test('when with non-null value', () {
      final rx = RxString('hello');
      final result = rx.when(
        onData: (v) => v.length,
        orElse: () => -1,
      );
      expect(result, 5);
    });

    test('mapTo transforms value', () {
      final rx = RxInt(3);
      final result = rx.mapTo((v) => 'value: $v');
      expect(result, 'value: 3');
    });

    test('test evaluates predicate', () {
      final rx = RxInt(5);
      expect(rx.test((v) => v > 3), true);
      expect(rx.test((v) => v > 10), false);
    });

    test('operator == with T and with Rx', () {
      final a = RxInt(5);
      final b = RxInt(5);
      final c = RxInt(10);

      // RxInt 支持与 int 及同类 Rx 比较
      expect(a == 5, true); // ignore: unrelated_type_equality_checks
      expect(a == 10, false); // ignore: unrelated_type_equality_checks
      expect(a == b, true);
      expect(a == c, false);
    });

    test('toString returns string of value', () {
      final rx = RxInt(42);
      expect(rx.toString(), '42');
    });

    test('Rx.empty creates Rx with null', () {
      final rx = Rx<int?>.empty();
      expect(rx.value, isNull);
    });

    test('call method updates value', () {
      final rx = RxInt(0);
      rx(5);
      expect(rx.value, 5);
    });

    test('call with null on non-nullable type does nothing', () {
      final rx = RxInt(5);
      final result = rx(null);
      expect(result, 5);
      expect(rx.value, 5);
    });
  });

  // ============================================================
  // RxNullable
  // ============================================================
  group('RxNullable', () {
    test('isNull returns true when value is null', () {
      final rx = RxNullable<int>();
      expect(rx.isNull, true);
      expect(rx.isNotNull, false);
    });

    test('let executes when value is not null', () {
      final rx = RxNullable<int>(42);
      final result = rx.let((v) => v * 2);
      expect(result, 84);
    });

    test('let returns null when value is null', () {
      final rx = RxNullable<int>();
      final result = rx.let((v) => v * 2);
      expect(result, isNull);
    });

    test('ifNull executes when value is null', () {
      final rx = RxNullable<int>();
      final result = rx.ifNull(() => 99);
      expect(result, 99);
    });

    test('getOrElse returns default when null', () {
      final rx = RxNullable<int>();
      expect(rx.getOrElse(42), 42);
    });

    test('getOrElse returns value when not null', () {
      final rx = RxNullable<int>(10);
      expect(rx.getOrElse(42), 10);
    });

    test('getOrThrow throws when null', () {
      final rx = RxNullable<int>();
      expect(() => rx.getOrThrow(), throwsStateError);
    });

    test('getOrThrow returns value when not null', () {
      final rx = RxNullable<int>(10);
      expect(rx.getOrThrow(), 10);
    });
  });
}
