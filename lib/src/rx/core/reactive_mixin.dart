import 'dart:async';
import 'package:flutter/foundation.dart';
import 'rx_interface.dart';
import 'rx_subject_mixin.dart';

/// 响应式对象混入，提供响应式值的核心操作能力。
///
/// 上游订阅（bindStream、select 等）通过 [linkSubscription] 登记，
/// [close] 时自动取消，不进入 Obx proxy 依赖表。
mixin ReactiveMixin<T> on RxSubjectMixin<T> {
  late T _value;

  List<StreamSubscription<dynamic>>? _linkedSubscriptions;

  /// 注册在 [close] 时自动取消的上游订阅（bindStream、select 等）
  @protected
  void linkSubscription(StreamSubscription<dynamic> subscription) {
    (_linkedSubscriptions ??= []).add(subscription);
  }

  @override
  void close() {
    final linked = _linkedSubscriptions;
    if (linked != null) {
      for (final subscription in linked) {
        subscription.cancel();
      }
      linked.clear();
    }
    super.close();
  }

  /// 初始化值，不触发刷新
  void initializeValue(T val) {
    _value = val;
  }

  /// 直接更新 [value] 并发送到 Stream
  /// 当使用自定义类型的 Rx 时，可调用此方法刷新 UI
  void refresh() {
    if (subject.isClosed) return;
    subject.emit(_value);
  }

  /// 使 Rx 对象可以像函数一样调用
  /// 通过 `rx(someOtherValue)` 方式更新值，便于直接赋值给 onChange 回调
  ///
  /// 修复说明：当 T 为可空类型时，传入 null 也应正确赋值
  T call([T? v]) {
    if (v != null || null is T) {
      value = v as T;
    }
    return value;
  }

  /// 是否为首次重建
  @protected
  bool isFirstRebuild = true;

  /// 是否已发送通知
  @protected
  bool hasNotified = false;

  /// 等同于 `toString()`，但作为 getter 提供
  String get string => _value.toString();

  @override
  String toString() => _value.toString();

  /// 相等性判断，支持与内部值或其他 Rx 对象比较
  @override
  bool operator ==(Object o) {
    if (o is T) return _value == o;
    if (o is ReactiveMixin<T>) return _value == o._value;
    return false;
  }

  @override
  int get hashCode => _value.hashCode;

  /// 更新 [value] 并发送到流，仅当值与前一个值不同时才更新观察者 Widget
  set value(T val) {
    if (subject.isClosed) return;
    hasNotified = false;
    if (_value == val && !isFirstRebuild) return;
    isFirstRebuild = false;
    _value = val;
    hasNotified = true;
    subject.emit(_value);
  }

  /// 返回当前 [value]，访问时自动注册依赖
  T get value {
    RxInterface.proxy?.addListener(subject);
    return _value;
  }

  /// 读取当前值，**不**注册 Obx 依赖
  ///
  /// 适用于副作用回调、日志、或与 `getOrElse` 等组合的非 UI 读取。
  /// 集合类型请优先用 `RxList.toList`、`RxMap.toMap`、`RxSet.toSet`。
  T get peek => _value;

  /// 获取内部值（不触发依赖注册），供子类写操作使用
  /// 写操作通过此 getter 获取引用后原地修改，再调用 [refresh] 触发通知
  @protected
  T get rawValue => _value;

  /// A [Stream] that emits every new [value] and can be listened to directly.
  Stream<T> get stream => subject.stream;

  /// 返回一个 [StreamSubscription]，与 [listen] 类似，但会先用当前 [value] 初始化流
  StreamSubscription<T> listenAndPump(void Function(T event) onData,
      {void Function(Object, StackTrace)? onError,
      void Function()? onDone,
      bool? cancelOnError}) {
    final subscription = listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError ?? false,
    );

    if (!subject.isClosed) {
      subject.emit(_value);
    }

    return subscription;
  }

  /// 将现有的 `Stream<T>` 绑定到此 `Rx<T>`，保持值同步
  ///
  /// 返回 [StreamSubscription]，可手动 [StreamSubscription.cancel]；
  /// Rx [close] 时也会自动取消。
  StreamSubscription<T> bindStream(Stream<T> stream) {
    if (subject.isClosed) {
      throw StateError('Cannot bind stream to a closed Rx');
    }
    final subscription = stream.listen((va) => value = va);
    linkSubscription(subscription);
    return subscription;
  }
}
