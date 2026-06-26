import 'dart:async';

import 'package:flutter/widgets.dart';

import '../rx/core/rx_interface.dart';
import '../workers/workers.dart';

/// Obx 页面生命周期混入：自动追踪并在 [dispose] 时释放 Rx / 订阅 / Worker。
///
/// 配合 [State] 与 `Obx` 使用，解决页面级资源手动释放易遗漏的问题。
///
/// 示例：
/// ```dart
/// class MyPage extends StatefulWidget {
///   @override
///   State<MyPage> createState() => _MyPageState();
/// }
///
/// class _MyPageState extends State<MyPage> with ObxLifecycleMixin {
///   late final count = rx(0.obs);
///   late final name = rx(''.obs);
///
///   @override
///   Widget build(BuildContext context) {
///     return Obx(() => Text('${count.value}'));
///   }
/// }
/// ```
mixin ObxLifecycleMixin<W extends StatefulWidget> on State<W> {
  final _rxList = <RxInterface<dynamic>>[];
  final _subscriptions = <StreamSubscription<dynamic>>[];
  List<Worker>? _workers;

  /// 注册 Rx 变量，[dispose] 时自动释放
  ///
  /// 返回传入的 Rx 变量本身，支持 `late final` 声明：
  /// ```dart
  /// late final count = rx(0.obs);
  /// ```
  @protected
  R rx<R extends RxInterface<dynamic>>(R reactive) {
    _rxList.add(reactive);
    return reactive;
  }

  /// 注册 [StreamSubscription]，[dispose] 时自动取消
  @protected
  StreamSubscription<R> subscription<R>(StreamSubscription<R> sub) {
    _subscriptions.add(sub);
    return sub;
  }

  /// 监听 Rx 变量变化，自动追踪返回的订阅
  @protected
  StreamSubscription<R> listen<R>(
    RxInterface<R> rx,
    void Function(R) onData,
  ) {
    final sub = rx.listen(onData);
    _subscriptions.add(sub);
    return sub;
  }

  /// 注册 [Worker]，[dispose] 时自动 [Worker.dispose]
  @protected
  Worker worker(Worker w) {
    (_workers ??= []).add(w);
    return w;
  }

  /// 释放所有已注册的 Rx、订阅与 Worker
  ///
  /// 由 [dispose] 自动调用，通常无需手动调用。
  @protected
  @mustCallSuper
  void disposeRx() {
    final workers = _workers;
    if (workers != null) {
      for (final w in workers) {
        w.dispose();
      }
      workers.clear();
    }

    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    for (final rx in _rxList) {
      rx.close();
    }
    _rxList.clear();
  }

  @override
  void dispose() {
    disposeRx();
    super.dispose();
  }
}
