import 'dart:async';

import 'package:flutter/widgets.dart';

import '../rx/rx.dart';
import '../workers/workers.dart';
import 'rx_disposable.dart';

/// Rx 页面生命周期混入：自动追踪并在 [dispose] 时释放 Rx / 订阅 / Worker。
///
/// 配合 [State] 与 `Obx` 使用，解决页面级资源手动释放易遗漏的问题。
/// 底层通过 [RxDisposable] 实现，非 Widget 作用域可直接使用 [RxDisposable]。
///
/// 示例：
/// ```dart
/// class MyPage extends StatefulWidget {
///   @override
///   State<MyPage> createState() => _MyPageState();
/// }
///
/// class _MyPageState extends State<MyPage> with RxLifecycleMixin {
///   late final count = rx(0.obs);
///   late final name = rx(''.obs);
///
///   @override
///   Widget build(BuildContext context) {
///     return Obx(() => Text('${count.value}'));
///   }
/// }
/// ```
mixin RxLifecycleMixin<W extends StatefulWidget> on State<W> {
  final _disposable = RxDisposable();

  /// 注册 Rx 变量，[dispose] 时自动释放
  ///
  /// 返回传入的 Rx 变量本身，支持 `late final` 声明：
  /// ```dart
  /// late final count = rx(0.obs);
  /// ```
  @protected
  R rx<R extends RxInterface<dynamic>>(R reactive) => _disposable.rx(reactive);

  /// 注册 [StreamSubscription]，[dispose] 时自动取消
  @protected
  StreamSubscription<R> subscription<R>(StreamSubscription<R> sub) =>
      _disposable.subscription(sub);

  /// 监听 Rx 变量变化，自动追踪返回的订阅
  @protected
  StreamSubscription<R> listen<R>(
    RxInterface<R> rx,
    void Function(R) onData,
  ) =>
      _disposable.listen(rx, onData);

  /// 注册 [Worker]，[dispose] 时自动 [Worker.dispose]
  @protected
  Worker worker(Worker w) => _disposable.worker(w);

  /// 释放所有已注册的 Rx、订阅与 Worker
  ///
  /// 由 [dispose] 自动调用，通常无需手动调用。
  @protected
  @mustCallSuper
  void disposeRx() => _disposable.dispose();

  @override
  void dispose() {
    disposeRx();
    super.dispose();
  }
}
