import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../signals/signal.dart';
import 'rx_interface.dart';

/// Rx 发布侧：持有 subject，广播与生命周期。
///
/// 实现 [RxProxyContract]：Dependency 为空操作，Notifier 基于 subject。
/// Proxy 依赖表仅由 ObxObserver 维护。
mixin RxSubjectMixin<T> implements RxProxyContract<T> {
  /// The underlying [Signal] that broadcasts value changes and manages
  /// listeners for this Rx.
  @protected
  Signal<T> subject = Signal<T>();

  @override
  bool get canUpdate => false;

  /// subject 是否已关闭
  bool get isClosed => subject.isClosed;

  /// Proxy 依赖由 ObxObserver 登记；Rx 发布侧不实现 relay。
  @override
  void addListener(Signal<T> signal) {}

  @override
  void removeListener(Signal<T> signal) {}

  @override
  void clearListeners() {}

  @override
  StreamSubscription<T> listen(
    void Function(T) onData, {
    void Function(Object error, StackTrace stackTrace)? onError,
    void Function()? onDone,
    bool cancelOnError = false,
  }) =>
      subject.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  @override
  void close() => subject.close();
}
