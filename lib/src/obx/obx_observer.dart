import 'dart:async';
import 'dart:ui';

import '../rx/core/reactive_mixin.dart';
import '../rx/core/rx_interface.dart';
import '../signals/signal.dart';

/// Obx UI 观察者：proxy 依赖表 + 增量 sweep + rebuild。
///
/// 每个 Signal 至多一条 [SignalSubscription]（一对一）。
/// 读 `.value` 时经 [RxInterface.proxy] 调用 [addListener] → [_dispatch]。
///
/// bindStream、select 等上游订阅在 Rx 侧走 [ReactiveMixin.linkSubscription]，
/// 不进入 [_dependencies]。
class ObxObserver implements RxInterface<void> {
  ObxObserver([VoidCallback? onNotify]) : _onNotify = onNotify;
  final List<VoidCallback> _listenCallbacks = [];
  final Map<Signal<dynamic>, SignalSubscription<dynamic>> _dependencies = {};
  Set<Signal<dynamic>>? _dependencySweep;
  VoidCallback? _onNotify;
  bool _closed = false;

  bool get _mayAttach => !_closed;

  @override
  bool get canUpdate => _dependencies.isNotEmpty;

  /// 开始依赖扫描：将当前 proxy 依赖放入待移除集合
  void beginDependencySweep() {
    _dependencySweep = _dependencies.keys.toSet();
  }

  /// 结束依赖扫描：移除本轮 builder 未读到的依赖
  void endDependencySweep() {
    final stale = _dependencySweep;
    if (stale == null) return;
    _dependencySweep = null;
    for (final signal in stale) {
      removeListener(signal);
    }
  }

  void _dispatch() {
    if (_closed) return;
    _onNotify?.call();
    // 快照后再派发：listen() 的 cancel 会同步 remove，避免遍历时 ConcurrentModificationError
    for (final cb in List<VoidCallback>.of(_listenCallbacks)) {
      cb();
    }
  }

  @override
  void addListener(Signal<void> signal) {
    _dependencySweep?.remove(signal);
    if (!_mayAttach || _dependencies.containsKey(signal)) return;
    _dependencies[signal] = signal.listen((_) => _dispatch());
  }

  @override
  void removeListener(Signal<void> signal) {
    _dependencies.remove(signal)?.cancel();
  }

  @override
  void clearListeners() {
    _dependencySweep = null;
    for (final sub in _dependencies.values) {
      sub.cancel();
    }
    _dependencies.clear();
  }

  @override
  StreamSubscription<void> listen(
    void Function(void event) onData, {
    void Function(Object error, StackTrace stackTrace)? onError,
    void Function()? onDone,
    bool cancelOnError = false,
  }) {
    void handler() => onData(null);
    _listenCallbacks.add(handler);
    return _ObserverStreamSubscription(() => _listenCallbacks.remove(handler));
  }

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _onNotify = null;
    clearListeners();
    _listenCallbacks.clear();
  }
}

class _ObserverStreamSubscription implements StreamSubscription<void> {
  _ObserverStreamSubscription(this._onCancel);

  final VoidCallback _onCancel;
  bool _isPaused = false;

  @override
  bool get isPaused => _isPaused;

  @override
  void onData(void Function(void data)? handleData) {}

  @override
  void onError(Function? handleError) {}

  @override
  void onDone(VoidCallback? handleDone) {}

  @override
  void pause([Future<void>? resumeSignal]) => _isPaused = true;

  @override
  void resume() => _isPaused = false;

  @override
  Future<void> cancel() {
    _onCancel();
    return Future.value();
  }

  @override
  Future<E> asFuture<E>([E? futureValue]) => Future.value(futureValue);
}
