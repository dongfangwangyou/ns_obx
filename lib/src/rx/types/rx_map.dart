import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'rx_collection.dart';

/// Map 的扩展方法
extension RxMapExtension<K, V> on Map<K, V> {
  /// 将 Map 转换为响应式映射
  RxMap<K, V> get obs {
    return RxMap<K, V>(this);
  }
}

/// 响应式映射类，类似 `Map<K, V>` 但具有响应式能力
class RxMap<K, V> extends RxCollection<Map<K, V>> with MapMixin<K, V> {
  RxMap([Map<K, V> initial = const {}]) {
    initializeValue(Map.from(initial));
  }

  /// 批量更新映射
  ///
  /// 回调参数为底层 [Map]（与 [rawValue] 相同引用）。回调内：
  /// - 调用 `[]=` / [remove] / [addAll] 等 Rx 方法：各自 no-op 优化仍生效，且不会单独 [refresh]
  /// - 直接改底层映射（如 `map.remove(key)`）：不会触发中间 [refresh]，
  ///   仅在回调结束后若内容有变化则统一通知一次
  ///
  /// 单键更新请用 [update]；逐键变换请用 [updateAll]。
  void batchUpdate(void Function(Map<K, V> map) fn) {
    final before = Map<K, V>.from(rawValue);
    batchUpdating = true;
    try {
      fn(rawValue);
    } finally {
      batchUpdating = false;
    }
    if (!mapEquals(before, rawValue)) {
      refresh();
    }
  }

  /// 从另一个 Map 创建
  factory RxMap.from(Map<K, V> other) {
    return RxMap(Map.from(other));
  }

  /// 创建一个与 [other] 具有相同键值对的 [LinkedHashMap]
  factory RxMap.of(Map<K, V> other) {
    return RxMap(Map.of(other));
  }

  /// 创建一个包含 [other] 所有条目且不可修改的哈希映射
  factory RxMap.unmodifiable(Map<dynamic, dynamic> other) {
    return RxMap(Map.unmodifiable(other));
  }

  /// 创建一个标识映射，使用默认实现 [LinkedHashMap]
  factory RxMap.identity() {
    return RxMap(Map.identity());
  }

  /// 返回当前映射快照，**不**注册 Obx 依赖
  Map<K, V> toMap() => Map<K, V>.from(rawValue);

  @override
  V? operator [](Object? key) {
    return value[key as K];
  }

  @override
  void operator []=(K key, V value) {
    if (rawValue.containsKey(key) && rawValue[key] == value) return;
    rawValue[key] = value;
    refreshUnlessBatching();
  }

  @override
  void clear() {
    if (rawValue.isEmpty) return;
    rawValue.clear();
    refreshUnlessBatching();
  }

  @override
  Iterable<K> get keys => readTracked((map) => map.keys);

  @override
  bool containsKey(Object? key) => readTracked((map) => map.containsKey(key));

  @override
  bool containsValue(Object? value) =>
      readTracked((map) => map.containsValue(value));

  @override
  V? remove(Object? key) {
    if (!rawValue.containsKey(key)) {
      return null;
    }
    final val = rawValue.remove(key);
    refreshUnlessBatching();
    return val;
  }

  /// 仅当 [condition] 为 true 时添加键值对
  void addIf(dynamic condition, K key, V value) {
    if (evaluateCondition(condition)) {
      this[key] = value;
    }
  }

  /// 仅当 [condition] 为 true 时添加所有键值对
  void addAllIf(dynamic condition, Map<K, V> values) {
    if (evaluateCondition(condition)) addAll(values);
  }

  /// 用单个键值对替换映射中的所有现有项
  void assign(K key, V val) {
    if (rawValue.length == 1 &&
        rawValue.containsKey(key) &&
        rawValue[key] == val) {
      return;
    }
    rawValue.clear();
    rawValue[key] = val;
    refreshUnlessBatching();
  }

  /// 用 [val] 替换映射中的所有现有项
  void assignAll(Map<K, V> val) {
    if (this == val) return;
    if (mapEquals(rawValue, val)) return;
    rawValue.clear();
    rawValue.addAll(val);
    refreshUnlessBatching();
  }

  @override
  void addAll(Map<K, V> elements) {
    if (elements.isEmpty) return;
    for (final e in elements.entries) {
      if (!rawValue.containsKey(e.key) || rawValue[e.key] != e.value) {
        rawValue.addAll(elements);
        refreshUnlessBatching();
        return;
      }
    }
  }

  @override
  void removeWhere(bool Function(K key, V value) test) {
    final len = rawValue.length;
    rawValue.removeWhere(test);
    if (rawValue.length != len) refreshUnlessBatching();
  }

  @override
  V update(
    K key,
    V Function(V value) update, {
    V Function()? ifAbsent,
  }) {
    if (rawValue.containsKey(key)) {
      final newValue = update(rawValue[key] as V);
      if (rawValue[key] == newValue) return newValue;
      rawValue[key] = newValue;
      refreshUnlessBatching();
      return newValue;
    }
    if (ifAbsent != null) {
      final newValue = ifAbsent();
      rawValue[key] = newValue;
      refreshUnlessBatching();
      return newValue;
    }
    throw ArgumentError.value(key, 'key', 'Key not in map');
  }

  @override
  void updateAll(V Function(K key, V value) update) {
    final before = Map<K, V>.from(rawValue);
    rawValue.updateAll(update);
    if (!mapEquals(before, rawValue)) {
      refreshUnlessBatching();
    }
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    if (rawValue.containsKey(key)) {
      return rawValue[key] as V;
    }
    final newValue = ifAbsent();
    rawValue[key] = newValue;
    refreshUnlessBatching();
    return newValue;
  }

}
