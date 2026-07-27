import '../core/reactive_mixin.dart';
import '../core/rx_interface.dart';
import '../core/rx_subject_mixin.dart';

/// 响应式基类，管理所有类型的流逻辑
///
/// 组合 RxSubjectMixin 与 ReactiveMixin，提供响应式对象的完整能力。
abstract class _RxImpl<T> extends RxInterface<T>
    with RxSubjectMixin<T>, ReactiveMixin<T> {
  _RxImpl(T initial) {
    initializeValue(initial);
  }

  void addError(Object error, [StackTrace? stackTrace]) {
    subject.emitError(error, stackTrace);
  }

  /// 将当前值通过 [mapper] 映射为新的 Stream
  Stream<R> map<R>(R Function(T? data) mapper) => stream.map(mapper);

  /// 使用回调内部更新 [value]，适用于自定义 Rx 类型
  /// 更新后会自动触发通知，刷新依赖的 Widget
  void update([void Function(T val)? fn]) {
    fn?.call(value);
    refresh();
  }

  /// 基于当前值创建新的响应式对象
  ///
  /// 派生 Rx [close] 时会自动取消对父 Rx 的 listen；父 Rx [close] 时也会自动
  /// [close] 派生 Rx，避免在父级生命周期结束后继续泄漏派生对象。
  Rx<R> select<R>(R Function(T value) selector) {
    final result = Rx<R>(selector(value));
    result.linkSubscription(
      listen(
        (val) {
          if (!result.subject.isClosed) {
            result.value = selector(val);
          }
        },
        onDone: result.close,
      ),
    );
    return result;
  }

  /// 条件映射，当值非 null 时执行 [onData]，否则返回 [orElse]
  R when<R>({
    required R Function(T value) onData,
    required R orElse,
  }) {
    final val = value;
    if (val != null) {
      return onData(val);
    }
    return orElse;
  }

  /// 将当前值映射到另一个值
  R mapTo<R>(R Function(T value) mapper) => mapper(value);

  /// 检查值是否满足条件
  bool test(bool Function(T value) predicate) => predicate(value);

  /// 当值满足条件时执行回调
  void where(void Function(T value) callback, {bool Function(T value)? condition}) {
    final cond = condition ?? (_) => true;
    if (cond(value)) {
      callback(value);
    }
  }
}

/// 自定义类型的响应式包装类
/// 用于 Dart 原生类型之外的自定义类型，如 User().obs 会使用 `Rx` 作为包装
class Rx<T> extends _RxImpl<T> {
  Rx(super.initial);

  /// 创建一个空的 Rx 对象（仅适用于可空类型）
  Rx.empty() : super(null as T);

  /// 从异步计算创建 Rx
  static Future<Rx<T>> fromFuture<T>(Future<T> future) async {
    final result = await future;
    return Rx<T>(result);
  }

  /// 从流创建 Rx
  /// 返回 [Rx<T?>] 类型，初始值为 null，流事件到达后自动更新
  static Rx<T?> fromStream<T>(Stream<T> stream) {
    final rx = Rx<T?>(null);
    rx.bindStream(stream);
    return rx;
  }

  /// 使用提供器函数创建 Rx
  static Rx<T> provider<T>(T Function() provider) => Rx<T>(provider());
}

/// 可空类型的响应式包装类
class RxNullable<T> extends Rx<T?> {
  RxNullable([super.initial]);

  /// 检查值是否为 null
  bool get isNull => value == null;

  /// 检查值是否不为 null
  bool get isNotNull => value != null;

  /// 如果值不为 null 则执行回调
  R? let<R>(R Function(T value) block) {
    final val = value;
    if (val != null) {
      return block(val);
    }
    return null;
  }

  /// 如果值为 null 则执行回调
  R? ifNull<R>(R Function() block) {
    if (value == null) {
      return block();
    }
    return null;
  }

  /// 获取值，如果为 null 则返回默认值
  T getOrElse(T defaultValue) => value ?? defaultValue;

  /// 获取值，如果为 null 则抛出异常
  T getOrThrow([Object? error]) {
    final val = value;
    if (val != null) {
      return val;
    }
    throw error ?? StateError('Value is null');
  }
}
