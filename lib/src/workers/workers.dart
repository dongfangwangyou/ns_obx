import 'dart:async';

import '../rx/core/rx_interface.dart';

/// 可释放的 Rx 副作用监听句柄
///
/// 由 [ever]、[once]、[debounce]、[interval] 返回，不再使用时调用 [dispose] 取消订阅。
/// 可配合 `ObxLifecycleMixin.worker()` 在页面 dispose 时自动释放。
class Worker {
  StreamSubscription<dynamic>? _subscription;
  final _TimerHolder? _timerHolder;
  bool _disposed = false;

  Worker._(this._subscription, [this._timerHolder]);

  /// 取消订阅并清理关联 Timer
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timerHolder?.cancel();
    _subscription?.cancel();
    _subscription = null;
  }
}

class _TimerHolder {
  Timer? timer;

  void cancel() {
    timer?.cancel();
    timer = null;
  }
}

/// 每次 [rx] 变化时调用 [callback]（不包含注册时的当前值）
Worker ever<T>(RxInterface<T> rx, void Function(T) callback) {
  return Worker._(rx.listen(callback));
}

/// [rx] 第一次变化时调用 [callback] 后自动取消
Worker once<T>(RxInterface<T> rx, void Function(T) callback) {
  late StreamSubscription<T> sub;
  sub = rx.listen((value) {
    callback(value);
    sub.cancel();
  });
  return Worker._(sub);
}

/// [rx] 变化后等待 [time] 静默期再调用 [callback]；连续变化会重置计时。
///
/// [leading] 为 `true` 时采用 leading 模式：窗口内首次变化立即调用，
/// 后续变化在 [time] 静默前被忽略；静默结束后下一次变化再次立即触发。
Worker debounce<T>(
  RxInterface<T> rx,
  void Function(T) callback, {
  Duration time = const Duration(milliseconds: 800),
  bool leading = false,
}) {
  final holder = _TimerHolder();
  var leadingActive = false;
  final sub = rx.listen((value) {
    holder.cancel();
    if (leading) {
      if (!leadingActive) {
        leadingActive = true;
        callback(value);
      }
      holder.timer = Timer(time, () => leadingActive = false);
    } else {
      holder.timer = Timer(time, () => callback(value));
    }
  });
  return Worker._(sub, holder);
}

/// [rx] 变化后至多每 [time] 调用一次 [callback]（窗口内首次立即触发，其余忽略）
///
/// 与 [debounce] 对称：debounce 为尾随（静默后触发），interval 为节流（固定窗口）。
Worker interval<T>(
  RxInterface<T> rx,
  void Function(T) callback, {
  Duration time = const Duration(seconds: 1),
}) {
  final holder = _TimerHolder();
  var active = false;
  final sub = rx.listen((value) {
    if (active) return;
    active = true;
    callback(value);
    holder.cancel();
    holder.timer = Timer(time, () => active = false);
  });
  return Worker._(sub, holder);
}
