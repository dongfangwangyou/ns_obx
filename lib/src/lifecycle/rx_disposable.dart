import 'dart:async';

import '../rx/rx.dart';
import '../workers/workers.dart';

/// 通用 Rx 资源释放器，可在任意对象（Controller、Service、BLoC 等）中使用。
///
/// 功能与 `RxLifecycleMixin` 等价，但不依赖 Flutter StatefulWidget State，方便在非
/// Widget 作用域中统一管理 Rx、StreamSubscription 与 Worker 的生命周期。
///
/// 示例：
/// ```dart
/// class UserController {
///   final _disposable = RxDisposable();
///   late final users = _disposable.rx(<User>[].obs);
///   late final query = _disposable.rx(''.obs);
///
///   UserController() {
///     _disposable.worker(debounce(query, _search));
///   }
///
///   void dispose() => _disposable.dispose();
/// }
/// ```
class RxDisposable {
  final _rxList = <RxInterface<dynamic>>[];
  final _subscriptions = <StreamSubscription<dynamic>>[];
  List<Worker>? _workers;
  bool _disposed = false;

  /// 是否已释放
  bool get isDisposed => _disposed;

  void _throwIfDisposed() {
    if (_disposed) {
      throw StateError('RxDisposable has already been disposed');
    }
  }

  /// 注册 Rx 变量，[dispose] 时自动调用其 close 方法
  ///
  /// 返回传入的 Rx 变量本身，支持链式声明。
  R rx<R extends RxInterface<dynamic>>(R reactive) {
    _throwIfDisposed();
    _rxList.add(reactive);
    return reactive;
  }

  /// 注册 [StreamSubscription]，[dispose] 时自动取消
  StreamSubscription<R> subscription<R>(StreamSubscription<R> sub) {
    _throwIfDisposed();
    _subscriptions.add(sub);
    return sub;
  }

  /// 监听 Rx 变量变化，自动追踪返回的订阅
  StreamSubscription<R> listen<R>(
    RxInterface<R> rx,
    void Function(R) onData,
  ) {
    _throwIfDisposed();
    final sub = rx.listen(onData);
    _subscriptions.add(sub);
    return sub;
  }

  /// 注册 [Worker]，[dispose] 时自动 [Worker.dispose]
  Worker worker(Worker w) {
    _throwIfDisposed();
    (_workers ??= []).add(w);
    return w;
  }

  /// 释放所有已注册的 Rx、订阅与 Worker
  ///
  /// 多次调用安全，后续再注册会抛出 [StateError]。
  void dispose() {
    if (_disposed) return;
    _disposed = true;

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
}
