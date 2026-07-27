import 'package:flutter/foundation.dart';

import '../core/reactive_mixin.dart';
import '../core/rx_interface.dart';
import '../core/rx_subject_mixin.dart';

/// 延迟求值的条件，用于 `addIf` / `addAllIf` 等 API。
///
/// 传入 `() => bool` 时会在添加前调用，避免每次手动写 `if (cond())`.
typedef RxCondition = bool Function();

/// 响应式集合基类，组合 RxSubjectMixin 与 ReactiveMixin。
///
/// RxList、RxMap、RxSet 继承此类，再 mixin 对应集合接口。
abstract class RxCollection<T> with RxSubjectMixin<T>, ReactiveMixin<T> implements RxInterface<T> {
  /// `update` / `batchUpdate` 期间抑制子操作的单独 refresh
  @protected
  bool batchUpdating = false;

  /// Notifies listeners unless a batch update is in progress.
  @protected
  void refreshUnlessBatching() {
    if (!batchUpdating) refresh();
  }

  /// 读操作：注册一次 Obx 依赖，数据来自 [rawValue]
  @protected
  R readTracked<R>(R Function(T collection) fn) {
    RxInterface.proxy?.addListener(subject);
    return fn(rawValue);
  }

  /// 解析 `addIf` / `addAllIf` 的 condition（`bool` 或 [RxCondition]）
  @protected
  bool evaluateCondition(dynamic condition) {
    if (condition is RxCondition) condition = condition();
    return condition is bool && condition;
  }
}
