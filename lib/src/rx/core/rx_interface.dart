import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../signals/signal.dart';
import 'rx_subject_mixin.dart';

// ---------------------------------------------------------------------------
// RxProxyContract — proxy 观察者实例契约
// ---------------------------------------------------------------------------

/// Proxy 观察者实例契约（依赖登记 + 订阅 / 生命周期）。
///
/// **Dependency** — 读 `.value` 时由 Rx 调用 [addListener]；Obx sweep 通过
/// [removeListener] / [clearListeners] 维护依赖表。
///
/// **Notifier** — [listen] 订阅值变化（Rx）或 rebuild 通知（ObxObserver）；
/// [close] 释放资源。
///
/// Rx 发布侧由 [RxSubjectMixin] 实现（Dependency 为空操作，Notifier 基于 subject）；
/// Obx 侧由 ObxObserver 实现。
abstract class RxProxyContract<T> {
  /// 是否有已注册的 proxy 依赖
  bool get canUpdate;

  /// 注册 proxy 依赖（读 `.value` 时由 Rx 调用）
  void addListener(Signal<T> signal);

  /// 移除之前通过 [addListener] 注册的 proxy 依赖
  void removeListener(Signal<T> signal);

  /// 清除全部 proxy 依赖，不关闭内部 Signal
  ///
  /// 一次性全量重置；完全释放请用 [close]。
  void clearListeners();

  /// 关闭并释放资源
  void close();

  /// 订阅值变化（Rx）或 rebuild 通知（ObxObserver）
  StreamSubscription<T> listen(
    void Function(T event) onData, {
    void Function(Object error, StackTrace stackTrace)? onError,
    void Function()? onDone,
    bool cancelOnError = false,
  });
}

// ---------------------------------------------------------------------------
// RxInterface — 统一契约 + static proxy 上下文
// ---------------------------------------------------------------------------

/// 响应式对象统一契约 + 静态 proxy 上下文。
///
/// 实例方法见 [RxProxyContract]；Obx 增量 stale 清理（begin/endDependencySweep）
/// 在 ObxObserver 内实现，不在此接口上。
///
/// Proxy 仅通过 [notifyDependents] 写入（Obx rebuild 栈）；外部只读 [proxy]。
/// 压栈实现见 `_buildWithProxy`；单测可经 [testDependents] 调用。
abstract class RxInterface<T> implements RxProxyContract<T> {
  // ---------------------------------------------------------------------------
  // Proxy — 静态 proxy 上下文（只读对外；写入仅 notifyDependents）
  // ---------------------------------------------------------------------------

  static RxInterface<void>? _proxy;

  /// 当前活跃的观察者代理（读 `.value` 时用于登记依赖）
  static RxInterface<void>? get proxy => _proxy;

  /// Obx rebuild 路径：压栈 observer → 执行 builder → 恢复。
  ///
  /// Debug 模式下若 builder 未读取任何 Rx（[RxProxyContract.canUpdate] 为 false），
  /// 触发断言提示 Obx 使用不当。
  static T notifyDependents<T>(
      RxInterface<void> observer, ValueGetter<T> builder) {
    final result = _buildWithProxy(observer, builder);
    assert(
      observer.canUpdate,
      '''
        [NsObx] 检测到 Obx 使用不当。
        
        问题分析：
        - 可能在 Obx 外部使用了响应式变量
        - 或者在 Obx 中使用了非响应式变量
        
        建议：
        - 确保只在 Obx 中使用 .obs 响应式变量
        - 如果不需要响应式更新，请使用 Builder widget 代替
        ''',
    );
    return result;
  }

  /// 单测专用：与 [notifyDependents] 相同的 proxy 压栈，但不检查 [canUpdate]。
  ///
  /// 用于验证 `peek`、集合 unwrap 等「不应登记依赖」的读路径。
  @visibleForTesting
  static T testDependents<T>(
          RxInterface<void> observer, ValueGetter<T> builder) =>
      _buildWithProxy(observer, builder);

  static T _buildWithProxy<T>(
      RxInterface<void> observer, ValueGetter<T> builder) {
    final oldObserver = _proxy;
    _proxy = observer;
    try {
      return builder();
    } finally {
      _proxy = oldObserver;
    }
  }

  /// 重置 proxy（测试 teardown）
  @visibleForTesting
  static void resetProxy() {
    _proxy = null;
  }
}
