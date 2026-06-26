import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'rx_collection.dart';

/// List 的扩展方法
extension RxListExtension<E> on List<E> {
  /// 将 List 转换为响应式列表
  RxList<E> get obs => RxList<E>(this);
}

/// 响应式列表类，类似 `List<T>` 但具有响应式能力
class RxList<E> extends RxCollection<List<E>> with ListMixin<E> {
  RxList([List<E> initial = const []]) {
    initializeValue(List.from(initial));
  }

  void _refreshIfChanged(List<E> before) {
    if (!listEquals(before, rawValue)) {
      refreshUnlessBatching();
    }
  }

  /// 使用回调批量更新列表
  ///
  /// 回调参数为底层 [List]（与 [rawValue] 相同引用）。回调内：
  /// - 调用 [add] / [removeWhere] 等 Rx 方法：各自 no-op 优化仍生效，且不会单独 [refresh]
  /// - 直接改底层列表（如 `list.removeAt(0)`）：不会触发中间 [refresh]，
  ///   仅在回调结束后若内容有变化则统一通知一次
  void update(void Function(List<E> list) fn) {
    final before = List<E>.from(rawValue);
    batchUpdating = true;
    try {
      fn(rawValue);
    } finally {
      batchUpdating = false;
    }
    if (!listEquals(before, rawValue)) {
      refresh();
    }
  }

  /// 创建一个填充指定值的列表
  factory RxList.filled(int length, E fill, {bool growable = false}) {
    return RxList(List.filled(length, fill, growable: growable));
  }

  /// 创建一个空列表
  factory RxList.empty({bool growable = false}) {
    return RxList(List.empty(growable: growable));
  }

  /// 从可迭代对象创建列表
  factory RxList.from(Iterable<E> elements, {bool growable = true}) {
    return RxList(List.from(elements, growable: growable));
  }

  /// 从可迭代对象创建类型安全的列表
  factory RxList.of(Iterable<E> elements, {bool growable = true}) {
    return RxList(List.of(elements, growable: growable));
  }

  /// 生成一个指定长度的列表
  factory RxList.generate(int length, E Function(int index) generator,
      {bool growable = true}) {
    return RxList(List.generate(length, generator, growable: growable));
  }

  /// 创建一个不可修改的列表
  factory RxList.unmodifiable(Iterable<E> elements) {
    return RxList(List.unmodifiable(elements));
  }

  /// 返回当前列表快照，**不**注册 Obx 依赖
  @override
  List<E> toList({bool growable = true}) =>
      List<E>.from(rawValue, growable: growable);

  @override
  Iterator<E> get iterator => readTracked((list) => list.iterator);

  @override
  void operator []=(int index, E val) {
    if (rawValue[index] == val) return;
    rawValue[index] = val;
    refreshUnlessBatching();
  }

  /// 响应式地添加元素，返回自身支持链式调用
  @override
  RxList<E> operator +(Iterable<E> val) {
    addAll(val);
    return this;
  }

  @override
  E operator [](int index) {
    return value[index];
  }

  @override
  void add(E element) {
    rawValue.add(element);
    refreshUnlessBatching();
  }

  @override
  void addAll(Iterable<E> iterable) {
    if (iterable.isEmpty) return;
    rawValue.addAll(iterable);
    refreshUnlessBatching();
  }

  @override
  void removeWhere(bool Function(E element) test) {
    final len = rawValue.length;
    rawValue.removeWhere(test);
    if (rawValue.length != len) refreshUnlessBatching();
  }

  @override
  void retainWhere(bool Function(E element) test) {
    final len = rawValue.length;
    rawValue.retainWhere(test);
    if (rawValue.length != len) refreshUnlessBatching();
  }

  @override
  int get length => value.length;

  @override
  set length(int newLength) {
    if (rawValue.length == newLength) return;
    rawValue.length = newLength;
    refreshUnlessBatching();
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    if (iterable.isEmpty) return;
    rawValue.insertAll(index, iterable);
    refreshUnlessBatching();
  }

  @override
  void insert(int index, E element) {
    rawValue.insert(index, element);
    refreshUnlessBatching();
  }

  @override
  E removeAt(int index) {
    final result = rawValue.removeAt(index);
    refreshUnlessBatching();
    return result;
  }

  @override
  bool remove(Object? element) {
    final removed = rawValue.remove(element);
    if (removed) refreshUnlessBatching();
    return removed;
  }

  @override
  E removeLast() {
    final result = rawValue.removeLast();
    refreshUnlessBatching();
    return result;
  }

  @override
  void removeRange(int start, int end) {
    if (end <= start) return;
    rawValue.removeRange(start, end);
    refreshUnlessBatching();
  }

  @override
  void clear() {
    if (rawValue.isEmpty) return;
    rawValue.clear();
    refreshUnlessBatching();
  }

  @override
  void fillRange(int start, int end, [E? fillValue]) {
    final value = fillValue as E;
    for (var i = start; i < end; i++) {
      if (rawValue[i] != value) {
        rawValue.fillRange(start, end, value);
        refreshUnlessBatching();
        return;
      }
    }
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    if (end <= start) return;
    final before = List<E>.from(rawValue);
    rawValue.setRange(start, end, iterable, skipCount);
    _refreshIfChanged(before);
  }

  @override
  void replaceRange(int start, int end, Iterable<E> newContents) {
    final before = List<E>.from(rawValue);
    rawValue.replaceRange(start, end, newContents);
    _refreshIfChanged(before);
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    final before = List<E>.from(rawValue);
    rawValue.setAll(index, iterable);
    _refreshIfChanged(before);
  }

  @override
  void shuffle([Random? random]) {
    final before = List<E>.from(rawValue);
    rawValue.shuffle(random);
    _refreshIfChanged(before);
  }

  @override
  Iterable<E> get reversed => readTracked((list) => list.reversed);

  @override
  Iterable<E> where(bool Function(E) test) {
    return value.where(test);
  }

  @override
  Iterable<T> whereType<T>() {
    return value.whereType<T>();
  }

  @override
  void sort([int Function(E a, E b)? compare]) {
    final before = List<E>.from(rawValue);
    rawValue.sort(compare);
    if (before.length != rawValue.length) {
      refreshUnlessBatching();
      return;
    }
    for (var i = 0; i < before.length; i++) {
      if (before[i] != rawValue[i]) {
        refreshUnlessBatching();
        return;
      }
    }
  }

  /// 仅当 [item] 不为 null 时添加到列表（仅适用于 E 为可空类型的场景）
  void addNonNull(E item) {
    if (item != null) add(item);
  }

  /// 仅当 [condition] 为 true 时添加 [item] 到列表
  void addIf(dynamic condition, E item) {
    if (evaluateCondition(condition)) add(item);
  }

  /// 仅当 [condition] 为 true 时添加 [items] 到列表
  void addAllIf(dynamic condition, Iterable<E> items) {
    if (evaluateCondition(condition)) addAll(items);
  }

  /// 用 [item] 替换列表中的所有现有项
  void assign(E item) {
    if (rawValue.length == 1 && rawValue[0] == item) return;
    rawValue.clear();
    rawValue.add(item);
    refreshUnlessBatching();
  }

  /// 用 [items] 替换列表中的所有现有项
  void assignAll(Iterable<E> items) {
    final next = List<E>.from(items);
    if (listEquals(rawValue, next)) return;
    rawValue.clear();
    rawValue.addAll(next);
    refreshUnlessBatching();
  }
}
