import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'rx_collection.dart';

/// Set 的扩展方法
extension RxSetExtension<E> on Set<E> {
  /// 将 Set 转换为响应式集合
  RxSet<E> get obs {
    return RxSet<E>(<E>{})..addAll(this);
  }
}

/// 响应式集合类，类似 `Set<E>` 但具有响应式能力
class RxSet<E> extends RxCollection<Set<E>> with SetMixin<E> {
  /// Creates a reactive set wrapping a copy of [initial].
  RxSet([Set<E> initial = const {}]) {
    initializeValue(Set.from(initial));
  }

  /// 响应式地添加集合元素，返回自身支持链式调用
  RxSet<E> operator +(Set<E> val) {
    addAll(val);
    return this;
  }

  /// 使用回调批量更新集合
  ///
  /// 回调参数为底层 [Set]（与 [rawValue] 相同引用）。回调内：
  /// - 调用 [add] / [remove] / [assign] 等 Rx 方法：各自 no-op 优化仍生效，且不会单独 [refresh]
  /// - 直接改底层集合（如 `set.remove(item)`）：不会触发中间 [refresh]，
  ///   仅在回调结束后若内容有变化则统一通知一次
  void update(void Function(Set<E> set) fn) {
    final before = Set<E>.from(rawValue);
    batchUpdating = true;
    try {
      fn(rawValue);
    } finally {
      batchUpdating = false;
    }
    if (!setEquals(before, rawValue)) {
      refresh();
    }
  }

  @override
  @protected
  set value(Set<E> val) {
    if (rawValue == val) return;
    super.value = val;
  }

  @override
  bool add(E value) {
    final added = rawValue.add(value);
    if (added) {
      refreshUnlessBatching();
    }
    return added;
  }

  @override
  bool contains(Object? element) =>
      readTracked((set) => set.contains(element));

  @override
  Iterator<E> get iterator => readTracked((set) => set.iterator);

  @override
  int get length => readTracked((set) => set.length);

  @override
  E? lookup(Object? element) => readTracked((set) => set.lookup(element));

  @override
  bool remove(Object? value) {
    final hasRemoved = rawValue.remove(value);
    if (hasRemoved) {
      refreshUnlessBatching();
    }
    return hasRemoved;
  }

  @override
  Set<E> toSet() => Set<E>.from(rawValue);

  @override
  void addAll(Iterable<E> elements) {
    if (elements.isEmpty) return;
    for (final e in elements) {
      if (!rawValue.contains(e)) {
        rawValue.addAll(elements);
        refreshUnlessBatching();
        return;
      }
    }
  }

  @override
  void clear() {
    if (rawValue.isEmpty) return;
    rawValue.clear();
    refreshUnlessBatching();
  }

  @override
  void removeAll(Iterable<Object?> elements) {
    final len = rawValue.length;
    rawValue.removeAll(elements);
    if (rawValue.length != len) refreshUnlessBatching();
  }

  @override
  void retainAll(Iterable<Object?> elements) {
    final len = rawValue.length;
    rawValue.retainAll(elements);
    if (rawValue.length != len) refreshUnlessBatching();
  }

  @override
  void retainWhere(bool Function(E) test) {
    final len = rawValue.length;
    rawValue.retainWhere(test);
    if (rawValue.length != len) refreshUnlessBatching();
  }

  @override
  void removeWhere(bool Function(E element) test) {
    final len = rawValue.length;
    rawValue.removeWhere(test);
    if (rawValue.length != len) refreshUnlessBatching();
  }

  /// 仅当 [condition] 为 true 时添加 [item] 到集合
  void addIf(dynamic condition, E item) {
    if (evaluateCondition(condition)) add(item);
  }

  /// 仅当 [condition] 为 true 时添加 [items] 到集合
  void addAllIf(dynamic condition, Iterable<E> items) {
    if (evaluateCondition(condition)) addAll(items);
  }

  /// 用 [item] 替换集合中的所有现有项
  void assign(E item) {
    if (rawValue.length == 1 && rawValue.contains(item)) return;
    rawValue.clear();
    rawValue.add(item);
    refreshUnlessBatching();
  }

  /// 用 [items] 替换集合中的所有现有项
  void assignAll(Iterable<E> items) {
    final next = Set<E>.from(items);
    if (setEquals(rawValue, next)) return;
    rawValue.clear();
    rawValue.addAll(next);
    refreshUnlessBatching();
  }
}
