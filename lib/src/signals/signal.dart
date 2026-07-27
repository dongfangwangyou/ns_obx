import 'dart:async';

/// [Signal] 是 Dart 中最轻量级、最高性能的事件处理方式
/// 语法类似 [StreamController]，但使用简单的回调方式工作
/// 每个事件只调用一个函数，没有缓冲区，内存消耗极低
class Signal<T> {
  /// Called when the first listener is added.
  final void Function()? onListen;

  /// Called when a listener pauses its subscription.
  final void Function()? onPause;

  /// Called when a listener resumes its subscription.
  final void Function()? onResume;

  /// Called when a listener cancels its subscription.
  final FutureOr<void> Function()? onCancel;

  /// Creates a [Signal] with optional lifecycle callbacks.
  Signal({this.onListen, this.onPause, this.onResume, this.onCancel});

  /// 订阅者列表（null 表示已关闭）
  List<SignalSubscription<T>>? _onData = <SignalSubscription<T>>[];

  /// 通知中标记（并发安全设计），使用 _isBusy 标记防止遍历过程中修改订阅列表
  bool _isBusy = false;

  /// 待添加的订阅者（在 _isBusy 期间暂存，通知结束后批量处理）
  final List<SignalSubscription<T>> _pendingAdditions = [];

  /// 待移除的订阅者（在 _isBusy 期间暂存，通知结束后批量处理）
  final List<SignalSubscription<T>> _pendingRemovals = [];

  /// 订阅者数量
  int get length => _onData?.length ?? 0;

  /// 是否有订阅者
  bool get hasListeners => _onData?.isNotEmpty ?? false;

  /// 是否已关闭
  bool get isClosed => _onData == null;

  /// 缓存的 Stream 适配器（避免重复分配）
  _SignalStreamAdapter<T>? _streamAdapter;

  /// 信号流适配器
  Stream<T> get stream => _streamAdapter ??= _SignalStreamAdapter(this);

  /// 内部存储值
  T? _value;

  /// 当前值
  T? get value => _value;

  /// 发射事件
  /// 当信号已关闭时，会抛出异常
  void emit(T event) {
    assert(!isClosed, '不能向已关闭的信号发射事件');
    _value = event; // 更新当前值
    _notifyData(event); // 通知订阅者
  }

  /// 发射错误
  /// 当信号已关闭时，会抛出异常
  void emitError(Object error, [StackTrace? stackTrace]) {
    assert(!isClosed, '不能向已关闭的信号发射错误');
    _notifyError(error, stackTrace); // 通知订阅者
  }

  /// 关联订阅者（内部方法）
  /// 在通知期间暂存到待处理列表，通知结束后批量添加
  void _attach(SignalSubscription<T> subs) {
    if (_onData == null) return;
    if (_isBusy) {
      _pendingAdditions.add(subs);
    } else {
      _onData!.add(subs);
    }
  }

  /// 解除订阅者（内部方法）
  /// 在通知期间暂存到待处理列表，通知结束后批量移除
  bool _detach(SignalSubscription<T> subs) {
    if (_onData == null) return false;
    if (_isBusy) {
      _pendingRemovals.add(subs);
      return true;
    }
    return _onData!.remove(subs);
  }

  /// 处理待添加和待移除的订阅者
  void _processPending() {
    if (_pendingRemovals.isNotEmpty) {
      for (final subs in _pendingRemovals) {
        _onData?.remove(subs);
      }
      _pendingRemovals.clear();
    }
    if (_pendingAdditions.isNotEmpty) {
      for (final subs in _pendingAdditions) {
        _onData?.add(subs);
      }
      _pendingAdditions.clear();
    }
  }

  /// 遍历未暂停的订阅者；单订阅时走 fast path
  void _forEachActive(
    List<SignalSubscription<T>> list,
    void Function(SignalSubscription<T> item) action,
  ) {
    if (list.length == 1) {
      if (!list[0].isPaused) action(list[0]);
      return;
    }
    for (final item in list) {
      if (!item.isPaused) action(item);
    }
  }

  /// 通知订阅者
  void _notifyData(T data) {
    if (_onData?.isEmpty ?? true) return;
    _isBusy = true;
    try {
      _forEachActive(_onData!, (item) => item._data?.call(data));
    } finally {
      _isBusy = false;
      _processPending();
    }
  }

  /// 通知订阅者错误
  void _notifyError(Object error, [StackTrace? stackTrace]) {
    assert(!isClosed, '不能向已关闭的信号添加错误');
    if (_onData?.isEmpty ?? true) return;

    _isBusy = true;
    try {
      final itemsToRemove = <SignalSubscription<T>>[];
      _forEachActive(_onData!, (item) {
        item._onError?.call(error, stackTrace ?? StackTrace.empty);
        if (item.cancelOnError ?? false) {
          itemsToRemove.add(item);
          item.pause();
          item._onDone?.call();
        }
      });
      for (final item in itemsToRemove) {
        _onData!.remove(item);
      }
    } finally {
      _isBusy = false;
      _processPending();
    }
  }

  /// 通知订阅者关闭
  void _notifyDone() {
    assert(!isClosed, '不能关闭已关闭的信号');
    if (_onData?.isEmpty ?? true) return;
    _isBusy = true;
    try {
      _forEachActive(_onData!, (item) => item._onDone?.call());
    } finally {
      _isBusy = false;
    }
  }

  /// 关闭信号
  /// 重复调用为安全 no-op。
  /// 关闭后 [value] 仍保留最后的值，便于 onDone 回调中读取
  void close() {
    if (isClosed) return;
    _notifyDone();
    _onData = null;
    _isBusy = false;
    _pendingAdditions.clear();
    _pendingRemovals.clear();
    // 注意：不再清除 _value，保留最后的值以供 onDone 回调读取
  }

  /// 订阅信号
  /// 当信号已关闭时，会抛出异常
  SignalSubscription<T> listen(
    void Function(T event) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final subs = SignalSubscription<T>(
      _detach,
      onPause: onPause,
      onResume: onResume,
      onCancel: onCancel,
    )
      ..onData(onData)
      ..onError(onError)
      ..onDone(onDone)
      ..cancelOnError = cancelOnError;
    _attach(subs);
    onListen?.call();
    return subs;
  }
}

/// [SignalSubscription] 信号订阅服务
class SignalSubscription<T> implements StreamSubscription<T> {
  final bool Function(SignalSubscription<T> subs) _detach;

  /// Called when this subscription is paused.
  final void Function()? onPause;

  /// Called when this subscription is resumed.
  final void Function()? onResume;

  /// Called when this subscription is cancelled.
  final FutureOr<void> Function()? onCancel;

  /// Creates a subscription with lifecycle callbacks.
  SignalSubscription(this._detach,
      {this.onPause, this.onResume, this.onCancel});

  bool _isPaused = false;

  /// Whether the subscription should be cancelled after the first error.
  bool? cancelOnError = false;
  void Function(T data)? _data;
  void Function(Object error, StackTrace stackTrace)? _onError;
  void Function()? _onDone;

  @override
  bool get isPaused => _isPaused;

  /// 接收数据
  @override
  void onData(void Function(T data)? handleData) => _data = handleData;

  /// 错误处理
  ///
  /// 支持 `void Function(Object)` 与 `void Function(Object, StackTrace)` 两种签名。
  @override
  void onError(Function? handleError) {
    if (handleError == null) {
      _onError = null;
      return;
    }
    // 兼容 void Function(Object) 与 void Function(Object, StackTrace)
    if (handleError is void Function(Object, StackTrace)) {
      _onError = handleError;
    } else if (handleError is void Function(Object)) {
      _onError = (Object error, StackTrace stackTrace) => handleError(error);
    } else {
      throw ArgumentError.value(
        handleError,
        'handleError',
        'onError callback must be either void Function(Object) or void Function(Object, StackTrace)',
      );
    }
  }

  /// 流关闭通知
  @override
  void onDone(void Function()? handleDone) => _onDone = handleDone;

  /// 暂停
  @override
  void pause([Future<void>? resumeSignal]) {
    _isPaused = true;
    onPause?.call();
  }

  /// 恢复
  @override
  void resume() {
    _isPaused = false;
    onResume?.call();
  }

  /// 彻底取消订阅
  /// 特别要注意资源释放：不用时必须cancel()防止内存泄漏
  @override
  Future<void> cancel() {
    _detach(this);
    onCancel?.call();
    return Future.value();
  }

  @override
  Future<E> asFuture<E>([E? futureValue]) => Future.value(futureValue);
}

/// Stream 适配器，将 Signal 适配为标准 Stream
class _SignalStreamAdapter<T> extends Stream<T> {
  final Signal<T> _signal;

  _SignalStreamAdapter(this._signal);

  @override
  SignalSubscription<T> listen(void Function(T event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return _signal.listen(
      onData ?? (_) {},
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
