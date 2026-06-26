import 'package:flutter_test/flutter_test.dart';
import 'package:ns_obx/ns_obx.dart';
import 'package:ns_obx/src/obx/obx_observer.dart';

void main() {
  // ============================================================
  // RxCollection 基类
  // ============================================================
  group('RxCollection', () {
    test('RxList extends RxCollection', () {
      expect(RxList<int>(), isA<RxCollection<List<int>>>());
    });

    test('RxMap extends RxCollection', () {
      expect(RxMap<String, int>(), isA<RxCollection<Map<String, int>>>());
    });

    test('RxSet extends RxCollection', () {
      expect(RxSet<int>(), isA<RxCollection<Set<int>>>());
    });

    test('iterator via readTracked registers proxy dependency', () {
      final list = RxList<int>([1, 2, 3]);
      final observer = ObxObserver();

      RxInterface.notifyDependents(observer, () {
        var sum = 0;
        for (final n in list) {
          sum += n;
        }
        return sum;
      });

      expect(observer.canUpdate, true);
    });

    test('addIf with RxCondition on map and set', () {
      final map = RxMap<String, int>();
      map.addIf(() => true, 'a', 1);
      expect(map.toMap(), {'a': 1});

      final set = RxSet<int>();
      set.addIf(() => false, 99);
      set.addIf(true, 1);
      expect(set.toSet(), {1});
    });
  });

  // ============================================================
  // RxList
  // ============================================================
  group('RxList', () {
    test('initial value is empty list', () {
      final list = RxList<int>();
      expect(list.toList(), isEmpty);
      expect(list.length, 0);
    });

    test('constructor with initial values', () {
      final list = RxList<int>([1, 2, 3]);
      expect(list.toList(), [1, 2, 3]);
      expect(list.length, 3);
    });

    test('add triggers notification', () {
      final list = RxList<int>([]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.add(1);
      expect(list.toList(), [1]);
      expect(callCount, 1);
    });

    test('addAll triggers notification', () {
      final list = RxList<int>([]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.addAll([1, 2, 3]);
      expect(list.toList(), [1, 2, 3]);
      expect(callCount, 1);
    });

    test('empty addAll does not notify', () {
      final list = RxList<int>([1]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.addAll([]);
      expect(list.toList(), [1]);
      expect(callCount, 0);
    });

    test('removeWhere triggers notification', () {
      final list = RxList<int>([1, 2, 3, 4, 5]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.removeWhere((e) => e.isOdd);
      expect(list.toList(), [2, 4]);
      expect(callCount, 1);
    });

    test('removeWhere with no matches does not notify', () {
      final list = RxList<int>([2, 4]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.removeWhere((e) => e.isOdd);
      expect(list.toList(), [2, 4]);
      expect(callCount, 0);
    });

    test('retainWhere triggers notification', () {
      final list = RxList<int>([1, 2, 3, 4, 5]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.retainWhere((e) => e.isEven);
      expect(list.toList(), [2, 4]);
      expect(callCount, 1);
    });

    test('retainWhere with no removals does not notify', () {
      final list = RxList<int>([2, 4, 6]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.retainWhere((e) => e.isEven);
      expect(list.toList(), [2, 4, 6]);
      expect(callCount, 0);
    });

    test('sort triggers notification', () {
      final list = RxList<int>([3, 1, 2]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.sort();
      expect(list.toList(), [1, 2, 3]);
      expect(callCount, 1);
    });

    test('sort already sorted does not notify', () {
      final list = RxList<int>([1, 2, 3]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.sort();
      expect(list.toList(), [1, 2, 3]);
      expect(callCount, 0);
    });

    test('[] operator reads from value', () {
      final list = RxList<String>(['a', 'b', 'c']);
      expect(list[0], 'a');
      expect(list[1], 'b');
      expect(list[2], 'c');
    });

    test('[]= triggers notification', () {
      final list = RxList<int>([1, 2, 3]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list[1] = 99;
      expect(list.toList(), [1, 99, 3]);
      expect(callCount, 1);
    });

    test('[]= with same value does not notify', () {
      final list = RxList<int>([1, 2, 3]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list[1] = 2;
      expect(list.toList(), [1, 2, 3]);
      expect(callCount, 0);
    });

    test('operator + adds all elements and triggers notification', () {
      final list = RxList<int>([1, 2]);
      var callCount = 0;
      list.listen((_) => callCount++);

      final result = list + [3, 4];
      expect(result, same(list));
      expect(list.toList(), [1, 2, 3, 4]);
      expect(callCount, 1);
    });

    test('length setter triggers notification', () {
      final list = RxList<int>([1, 2, 3]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.length = 1;
      expect(list.toList(), [1]);
      expect(callCount, 1);
    });

    test('length setter with same value does not notify', () {
      final list = RxList<int>([1, 2, 3]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.length = 3;
      expect(list.toList(), [1, 2, 3]);
      expect(callCount, 0);
    });

    test('insertAll triggers notification', () {
      final list = RxList<int>([1, 4]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.insertAll(1, [2, 3]);
      expect(list.toList(), [1, 2, 3, 4]);
      expect(callCount, 1);
    });

    test('empty insertAll does not notify', () {
      final list = RxList<int>([1, 4]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.insertAll(1, []);
      expect(list.toList(), [1, 4]);
      expect(callCount, 0);
    });

    test('clear triggers single notification', () {
      final list = RxList<int>([1, 2, 3]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.clear();
      expect(list.toList(), isEmpty);
      expect(callCount, 1);
    });

    test('clear empty list does not notify', () {
      final list = RxList<int>();
      var callCount = 0;
      list.listen((_) => callCount++);

      list.clear();
      expect(list.toList(), isEmpty);
      expect(callCount, 0);
    });

    test('removeAt triggers notification', () {
      final list = RxList<int>([1, 2, 3]);
      var callCount = 0;
      list.listen((_) => callCount++);

      expect(list.removeAt(1), 2);
      expect(list.toList(), [1, 3]);
      expect(callCount, 1);
    });

    test('insert triggers notification', () {
      final list = RxList<int>([1, 3]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.insert(1, 2);
      expect(list.toList(), [1, 2, 3]);
      expect(callCount, 1);
    });

    test('remove triggers notification when element exists', () {
      final list = RxList<int>([1, 2, 3]);
      var callCount = 0;
      list.listen((_) => callCount++);

      expect(list.remove(2), true);
      expect(list.toList(), [1, 3]);
      expect(callCount, 1);
    });

    test('remove does not notify when element missing', () {
      final list = RxList<int>([1, 2, 3]);
      var callCount = 0;
      list.listen((_) => callCount++);

      expect(list.remove(99), false);
      expect(list.toList(), [1, 2, 3]);
      expect(callCount, 0);
    });

    test('removeRange triggers single notification', () {
      final list = RxList<int>([1, 2, 3, 4]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.removeRange(1, 3);
      expect(list.toList(), [1, 4]);
      expect(callCount, 1);
    });

    test('removeLast triggers notification', () {
      final list = RxList<int>([1, 2, 3]);
      var callCount = 0;
      list.listen((_) => callCount++);

      expect(list.removeLast(), 3);
      expect(list.toList(), [1, 2]);
      expect(callCount, 1);
    });

    test('replaceRange triggers notification', () {
      final list = RxList<int>([1, 2, 3, 4]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.replaceRange(1, 3, [20, 30]);
      expect(list.toList(), [1, 20, 30, 4]);
      expect(callCount, 1);
    });

    test('fillRange with same values does not notify', () {
      final list = RxList<int>([1, 1, 1]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.fillRange(0, 3, 1);
      expect(list.toList(), [1, 1, 1]);
      expect(callCount, 0);
    });

    test('clear via assign replaces all items', () {
      final list = RxList<int>([1, 2, 3]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.assign(99);
      expect(list.toList(), [99]);
      expect(callCount, 1);
    });

    test('assign with same single item does not notify', () {
      final list = RxList<int>([99]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.assign(99);
      expect(list.toList(), [99]);
      expect(callCount, 0);
    });

    test('assignAll replaces all items', () {
      final list = RxList<int>([1, 2, 3]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.assignAll([4, 5, 6]);
      expect(list.toList(), [4, 5, 6]);
      expect(callCount, 1);
    });

    test('assignAll with same items does not notify', () {
      final list = RxList<int>([4, 5, 6]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.assignAll([4, 5, 6]);
      expect(list.toList(), [4, 5, 6]);
      expect(callCount, 0);
    });

    test('addIf with true condition adds item', () {
      final list = RxList<int>([]);
      list.addIf(true, 42);
      expect(list.toList(), [42]);
    });

    test('addIf with false condition does not add', () {
      final list = RxList<int>([]);
      list.addIf(false, 42);
      expect(list.toList(), isEmpty);
    });

    test('addIf with RxCondition', () {
      final list = RxList<int>([]);
      list.addIf(() => true, 42);
      expect(list.toList(), [42]);
    });

    test('addAllIf with condition', () {
      final list = RxList<int>([1]);
      list.addAllIf(true, [2, 3]);
      expect(list.toList(), [1, 2, 3]);

      list.addAllIf(false, [4, 5]);
      expect(list.toList(), [1, 2, 3]);
    });

    test('RxList.filled creates prefilled list', () {
      final list = RxList.filled(3, 'x');
      expect(list.toList(), ['x', 'x', 'x']);
    });

    test('RxList.generate creates list via generator', () {
      final list = RxList.generate(3, (i) => i * 10);
      expect(list.toList(), [0, 10, 20]);
    });

    test('List.obs extension creates RxList', () {
      final rx = [1, 2, 3].obs;
      expect(rx, isA<RxList<int>>());
      expect(rx.toList(), [1, 2, 3]);
    });

    test('iterator iterates values', () {
      final list = RxList<int>([10, 20, 30]);
      final collected = <int>[];
      for (final e in list) {
        collected.add(e);
      }
      expect(collected, [10, 20, 30]);
    });

    test('reversed returns reversed iterable', () {
      final list = RxList<int>([1, 2, 3]);
      expect(list.reversed.toList(), [3, 2, 1]);
    });

    test('where filters values', () {
      final list = RxList<int>([1, 2, 3, 4]);
      expect(list.where((e) => e.isEven).toList(), [2, 4]);
    });

    test('update modifies list and triggers single notification', () {
      final list = RxList<int>([1, 2]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.update((_) => list.add(3));
      expect(list.toList(), [1, 2, 3]);
      expect(callCount, 1);
    });

    test('update with multiple Rx operations triggers single notification', () {
      final list = RxList<int>([1, 2, 3]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.update((_) {
        list.add(4);
        list.removeWhere((e) => e.isOdd);
      });
      expect(list.toList(), [2, 4]);
      expect(callCount, 1);
    });

    test('update with no change does not notify', () {
      final list = RxList<int>([1, 2]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.update((_) {});
      expect(list.toList(), [1, 2]);
      expect(callCount, 0);
    });

    test('update with direct rawValue mutation triggers single notification', () {
      final list = RxList<int>([1, 2, 3]);
      var callCount = 0;
      list.listen((_) => callCount++);

      list.update((items) {
        items.removeAt(0);
        items.add(4);
      });
      expect(list.toList(), [2, 3, 4]);
      expect(callCount, 1);
    });
  });

  // ============================================================
  // RxMap
  // ============================================================
  group('RxMap', () {
    test('initial value is empty map', () {
      final map = RxMap<String, int>();
      expect(Map.of(map), isEmpty);
    });

    test('constructor with initial values', () {
      final map = RxMap<String, int>({'a': 1, 'b': 2});
      expect(Map.of(map), {'a': 1, 'b': 2});
    });

    test('[] operator reads value', () {
      final map = RxMap<String, int>({'key': 42});
      expect(map['key'], 42);
      expect(map['missing'], isNull);
    });

    test('[]= triggers notification', () {
      final map = RxMap<String, int>();
      var callCount = 0;
      map.listen((_) => callCount++);

      map['a'] = 1;
      map['b'] = 2;
      expect(Map.of(map), {'a': 1, 'b': 2});
      expect(callCount, 2);
    });

    test('[]= with same value does not notify', () {
      final map = RxMap<String, int>({'a': 1});
      var callCount = 0;
      map.listen((_) => callCount++);

      map['a'] = 1;
      expect(Map.of(map), {'a': 1});
      expect(callCount, 0);
    });

    test('remove triggers notification', () {
      final map = RxMap<String, int>({'a': 1, 'b': 2});
      var callCount = 0;
      map.listen((_) => callCount++);

      final removed = map.remove('a');
      expect(removed, 1);
      expect(Map.of(map), {'b': 2});
      expect(callCount, 1);
    });

    test('remove missing key does not notify', () {
      final map = RxMap<String, int>({'a': 1});
      var callCount = 0;
      map.listen((_) => callCount++);

      expect(map.remove('missing'), isNull);
      expect(Map.of(map), {'a': 1});
      expect(callCount, 0);
    });

    test('clear triggers notification', () {
      final map = RxMap<String, int>({'a': 1, 'b': 2});
      var callCount = 0;
      map.listen((_) => callCount++);

      map.clear();
      expect(Map.of(map), isEmpty);
      expect(callCount, 1);
    });

    test('clear empty map does not notify', () {
      final map = RxMap<String, int>();
      var callCount = 0;
      map.listen((_) => callCount++);

      map.clear();
      expect(Map.of(map), isEmpty);
      expect(callCount, 0);
    });

    test('keys returns map keys', () {
      final map = RxMap<String, int>({'a': 1, 'b': 2});
      expect(map.keys.toSet(), {'a', 'b'});
    });

    test('assign replaces all entries', () {
      final map = RxMap<String, int>({'a': 1, 'b': 2});
      var callCount = 0;
      map.listen((_) => callCount++);

      map.assign('c', 3);
      expect(Map.of(map), {'c': 3});
      expect(callCount, 1);
    });

    test('assign with same single entry does not notify', () {
      final map = RxMap<String, int>({'c': 3});
      var callCount = 0;
      map.listen((_) => callCount++);

      map.assign('c', 3);
      expect(Map.of(map), {'c': 3});
      expect(callCount, 0);
    });

    test('assignAll replaces all entries', () {
      final map = RxMap<String, int>({'a': 1});
      var callCount = 0;
      map.listen((_) => callCount++);

      map.assignAll({'x': 10, 'y': 20});
      expect(Map.of(map), {'x': 10, 'y': 20});
      expect(callCount, 1);
    });

    test('assignAll with same entries does not notify', () {
      final map = RxMap<String, int>({'x': 10, 'y': 20});
      var callCount = 0;
      map.listen((_) => callCount++);

      map.assignAll({'x': 10, 'y': 20});
      expect(Map.of(map), {'x': 10, 'y': 20});
      expect(callCount, 0);
    });

    test('addIf with true condition', () {
      final map = RxMap<String, int>();
      map.addIf(true, 'key', 42);
      expect(Map.of(map), {'key': 42});
    });

    test('addIf with false condition', () {
      final map = RxMap<String, int>();
      map.addIf(false, 'key', 42);
      expect(Map.of(map), isEmpty);
    });

    test('addAllIf with condition', () {
      final map = RxMap<String, int>();
      map.addAllIf(true, {'a': 1, 'b': 2});
      expect(Map.of(map), {'a': 1, 'b': 2});
    });

    test('addAll triggers single notification', () {
      final map = RxMap<String, int>({'a': 1});
      var callCount = 0;
      map.listen((_) => callCount++);

      map.addAll({'b': 2, 'c': 3});
      expect(Map.of(map), {'a': 1, 'b': 2, 'c': 3});
      expect(callCount, 1);
    });

    test('addAll with only existing same-value keys does not notify', () {
      final map = RxMap<String, int>({'a': 1, 'b': 2});
      var callCount = 0;
      map.listen((_) => callCount++);

      map.addAll({'a': 1, 'b': 2});
      expect(Map.of(map), {'a': 1, 'b': 2});
      expect(callCount, 0);
    });

    test('empty addAll does not notify', () {
      final map = RxMap<String, int>({'a': 1});
      var callCount = 0;
      map.listen((_) => callCount++);

      map.addAll({});
      expect(Map.of(map), {'a': 1});
      expect(callCount, 0);
    });

    test('removeWhere triggers single notification', () {
      final map = RxMap<String, int>({'a': 1, 'b': 2, 'c': 3});
      var callCount = 0;
      map.listen((_) => callCount++);

      map.removeWhere((_, v) => v.isOdd);
      expect(Map.of(map), {'b': 2});
      expect(callCount, 1);
    });

    test('removeWhere with no matches does not notify', () {
      final map = RxMap<String, int>({'b': 2, 'd': 4});
      var callCount = 0;
      map.listen((_) => callCount++);

      map.removeWhere((_, v) => v.isOdd);
      expect(Map.of(map), {'b': 2, 'd': 4});
      expect(callCount, 0);
    });

    test('update triggers notification', () {
      final map = RxMap<String, int>({'a': 1});
      var callCount = 0;
      map.listen((_) => callCount++);

      expect(map.update('a', (v) => v + 1), 2);
      expect(Map.of(map), {'a': 2});
      expect(callCount, 1);
    });

    test('update with same value does not notify', () {
      final map = RxMap<String, int>({'a': 1});
      var callCount = 0;
      map.listen((_) => callCount++);

      expect(map.update('a', (v) => v), 1);
      expect(Map.of(map), {'a': 1});
      expect(callCount, 0);
    });

    test('update with ifAbsent triggers notification', () {
      final map = RxMap<String, int>({'a': 1});
      var callCount = 0;
      map.listen((_) => callCount++);

      expect(map.update('b', (v) => v, ifAbsent: () => 2), 2);
      expect(Map.of(map), {'a': 1, 'b': 2});
      expect(callCount, 1);
    });

    test('updateAll triggers single notification', () {
      final map = RxMap<String, int>({'a': 1, 'b': 2});
      var callCount = 0;
      map.listen((_) => callCount++);

      map.updateAll((_, v) => v * 10);
      expect(Map.of(map), {'a': 10, 'b': 20});
      expect(callCount, 1);
    });

    test('updateAll with no change does not notify', () {
      final map = RxMap<String, int>({'a': 1, 'b': 2});
      var callCount = 0;
      map.listen((_) => callCount++);

      map.updateAll((_, v) => v);
      expect(Map.of(map), {'a': 1, 'b': 2});
      expect(callCount, 0);
    });

    test('putIfAbsent adds key and triggers notification', () {
      final map = RxMap<String, int>({'a': 1});
      var callCount = 0;
      map.listen((_) => callCount++);

      expect(map.putIfAbsent('b', () => 2), 2);
      expect(Map.of(map), {'a': 1, 'b': 2});
      expect(callCount, 1);
    });

    test('putIfAbsent with existing key does not notify', () {
      final map = RxMap<String, int>({'a': 1});
      var callCount = 0;
      map.listen((_) => callCount++);

      expect(map.putIfAbsent('a', () => 99), 1);
      expect(Map.of(map), {'a': 1});
      expect(callCount, 0);
    });

    test('Map.obs extension creates RxMap', () {
      final rx = {'a': 1, 'b': 2}.obs;
      expect(rx, isA<RxMap<String, int>>());
      expect(Map.of(rx), {'a': 1, 'b': 2});
    });

    test('RxMap.from creates copy', () {
      final original = {'x': 10};
      final map = RxMap<String, int>.from(original);
      original['y'] = 20;
      expect(Map.of(map), {'x': 10});
    });

    test('batchUpdate modifies map and triggers single notification', () {
      final map = RxMap<String, int>({'a': 1});
      var callCount = 0;
      map.listen((_) => callCount++);

      map.batchUpdate((_) => map['b'] = 2);
      expect(Map.of(map), {'a': 1, 'b': 2});
      expect(callCount, 1);
    });

    test('batchUpdate with multiple Rx operations triggers single notification', () {
      final map = RxMap<String, int>({'a': 1, 'b': 2});
      var callCount = 0;
      map.listen((_) => callCount++);

      map.batchUpdate((_) {
        map['c'] = 3;
        map.remove('a');
      });
      expect(Map.of(map), {'b': 2, 'c': 3});
      expect(callCount, 1);
    });

    test('batchUpdate with no change does not notify', () {
      final map = RxMap<String, int>({'a': 1});
      var callCount = 0;
      map.listen((_) => callCount++);

      map.batchUpdate((_) {});
      expect(Map.of(map), {'a': 1});
      expect(callCount, 0);
    });

    test('batchUpdate with direct rawValue mutation triggers single notification', () {
      final map = RxMap<String, int>({'a': 1, 'b': 2});
      var callCount = 0;
      map.listen((_) => callCount++);

      map.batchUpdate((m) {
        m.remove('a');
        m['c'] = 3;
      });
      expect(Map.of(map), {'b': 2, 'c': 3});
      expect(callCount, 1);
    });
  });

  // ============================================================
  // RxSet
  // ============================================================
  group('RxSet', () {
    test('initial value is empty set', () {
      final s = RxSet<int>();
      expect(s.toSet(), isEmpty);
    });

    test('constructor with initial values', () {
      final s = RxSet<int>({1, 2, 3});
      expect(s.toSet(), {1, 2, 3});
    });

    test('add triggers notification', () {
      final s = RxSet<int>();
      var callCount = 0;
      s.listen((_) => callCount++);

      final added = s.add(42);
      expect(added, true);
      expect(s.toSet(), {42});
      expect(callCount, 1);

      // 重复添加不触发 refresh
      callCount = 0;
      final addedAgain = s.add(42);
      expect(addedAgain, false);
      expect(callCount, 0);
    });

    test('addAll triggers notification', () {
      final s = RxSet<int>();
      var callCount = 0;
      s.listen((_) => callCount++);

      s.addAll([1, 2, 3]);
      expect(s.toSet(), {1, 2, 3});
      expect(callCount, 1);
    });

    test('empty addAll does not notify', () {
      final s = RxSet<int>({1});
      var callCount = 0;
      s.listen((_) => callCount++);

      s.addAll([]);
      expect(s.toSet(), {1});
      expect(callCount, 0);
    });

    test('addAll with only existing elements does not notify', () {
      final s = RxSet<int>({1, 2, 3});
      var callCount = 0;
      s.listen((_) => callCount++);

      s.addAll([1, 2, 3]);
      expect(s.toSet(), {1, 2, 3});
      expect(callCount, 0);
    });

    test('remove triggers notification when element exists', () {
      final s = RxSet<int>({1, 2, 3});
      var callCount = 0;
      s.listen((_) => callCount++);

      final removed = s.remove(2);
      expect(removed, true);
      expect(s.toSet(), {1, 3});
      expect(callCount, 1);
    });

    test('remove does not trigger notification when element missing', () {
      final s = RxSet<int>({1, 2, 3});
      var callCount = 0;
      s.listen((_) => callCount++);

      final removed = s.remove(99);
      expect(removed, false);
      expect(callCount, 0);
    });

    test('clear triggers notification', () {
      final s = RxSet<int>({1, 2, 3});
      var callCount = 0;
      s.listen((_) => callCount++);

      s.clear();
      expect(s.toSet(), isEmpty);
      expect(callCount, 1);
    });

    test('clear empty set does not notify', () {
      final s = RxSet<int>();
      var callCount = 0;
      s.listen((_) => callCount++);

      s.clear();
      expect(s.toSet(), isEmpty);
      expect(callCount, 0);
    });

    test('removeAll triggers notification', () {
      final s = RxSet<int>({1, 2, 3, 4, 5});
      var callCount = 0;
      s.listen((_) => callCount++);

      s.removeAll([1, 3, 5]);
      expect(s.toSet(), {2, 4});
      expect(callCount, 1);
    });

    test('removeAll with no matches does not notify', () {
      final s = RxSet<int>({2, 4});
      var callCount = 0;
      s.listen((_) => callCount++);

      s.removeAll([1, 3, 5]);
      expect(s.toSet(), {2, 4});
      expect(callCount, 0);
    });

    test('retainAll triggers notification', () {
      final s = RxSet<int>({1, 2, 3, 4, 5});
      var callCount = 0;
      s.listen((_) => callCount++);

      s.retainAll([2, 4]);
      expect(s.toSet(), {2, 4});
      expect(callCount, 1);
    });

    test('retainAll with no removals does not notify', () {
      final s = RxSet<int>({2, 4});
      var callCount = 0;
      s.listen((_) => callCount++);

      s.retainAll([2, 4, 6]);
      expect(s.toSet(), {2, 4});
      expect(callCount, 0);
    });

    test('retainWhere triggers notification', () {
      final s = RxSet<int>({1, 2, 3, 4, 5});
      var callCount = 0;
      s.listen((_) => callCount++);

      s.retainWhere((e) => e.isEven);
      expect(s.toSet(), {2, 4});
      expect(callCount, 1);
    });

    test('retainWhere with no removals does not notify', () {
      final s = RxSet<int>({2, 4, 6});
      var callCount = 0;
      s.listen((_) => callCount++);

      s.retainWhere((e) => e.isEven);
      expect(s.toSet(), {2, 4, 6});
      expect(callCount, 0);
    });

    test('removeWhere triggers single notification', () {
      final s = RxSet<int>({1, 2, 3, 4, 5});
      var callCount = 0;
      s.listen((_) => callCount++);

      s.removeWhere((e) => e.isOdd);
      expect(s.toSet(), {2, 4});
      expect(callCount, 1);
    });

    test('removeWhere with no matches does not notify', () {
      final s = RxSet<int>({2, 4, 6});
      var callCount = 0;
      s.listen((_) => callCount++);

      s.removeWhere((e) => e.isOdd);
      expect(s.toSet(), {2, 4, 6});
      expect(callCount, 0);
    });

    test('contains checks membership', () {
      final s = RxSet<int>({1, 2, 3});
      expect(s.contains(2), true);
      expect(s.contains(99), false);
    });

    test('length returns size', () {
      final s = RxSet<int>({1, 2, 3});
      expect(s.length, 3);
    });

    test('operator + adds all elements and triggers single notification', () {
      final s = RxSet<int>({1, 2});
      var callCount = 0;
      s.listen((_) => callCount++);

      s + {3, 4};
      expect(s.toSet(), {1, 2, 3, 4});
      expect(callCount, 1);
    });

    test('whole set replacement triggers single notification', () {
      final s = RxSet<int>({1, 2, 3});
      var callCount = 0;
      s.listen((_) => callCount++);

      s.assignAll({4, 5, 6});
      expect(s.toSet(), {4, 5, 6});
      expect(callCount, 1);
    });

    test('assign replaces all items', () {
      final s = RxSet<int>({1, 2, 3});
      var callCount = 0;
      s.listen((_) => callCount++);

      s.assign(99);
      expect(s.toSet(), {99});
      expect(callCount, 1);
    });

    test('assign with same single item does not notify', () {
      final s = RxSet<int>({99});
      var callCount = 0;
      s.listen((_) => callCount++);

      s.assign(99);
      expect(s.toSet(), {99});
      expect(callCount, 0);
    });

    test('assignAll replaces all items', () {
      final s = RxSet<int>({1, 2, 3});
      var callCount = 0;
      s.listen((_) => callCount++);

      s.assignAll({4, 5, 6});
      expect(s.toSet(), {4, 5, 6});
      expect(callCount, 1);
    });

    test('assignAll with same items does not notify', () {
      final s = RxSet<int>({4, 5, 6});
      var callCount = 0;
      s.listen((_) => callCount++);

      s.assignAll({4, 5, 6});
      expect(s.toSet(), {4, 5, 6});
      expect(callCount, 0);
    });

    test('addIf with condition', () {
      final s = RxSet<int>();
      s.addIf(true, 42);
      expect(s.toSet(), {42});
      s.addIf(false, 99);
      expect(s.toSet(), {42});
    });

    test('update modifies value and triggers notification', () {
      final s = RxSet<int>({1, 2});
      var callCount = 0;
      s.listen((_) => callCount++);

      s.update((val) => s.add(3));
      expect(s.toSet(), {1, 2, 3});
      expect(callCount, 1);
    });

    test('update with multiple Rx operations triggers single notification', () {
      final s = RxSet<int>({1, 2});
      var callCount = 0;
      s.listen((_) => callCount++);

      s.update((_) {
        s.add(3);
        s.remove(1);
      });
      expect(s.toSet(), {2, 3});
      expect(callCount, 1);
    });

    test('update with no change does not notify', () {
      final s = RxSet<int>({1, 2});
      var callCount = 0;
      s.listen((_) => callCount++);

      s.update((_) {});
      expect(s.toSet(), {1, 2});
      expect(callCount, 0);
    });

    test('assign inside update triggers single notification', () {
      final s = RxSet<int>({1, 2, 3});
      var callCount = 0;
      s.listen((_) => callCount++);

      s.update((_) => s.assign(99));
      expect(s.toSet(), {99});
      expect(callCount, 1);
    });

    test('update with direct rawValue mutation triggers single notification', () {
      final s = RxSet<int>({1, 2});
      var callCount = 0;
      s.listen((_) => callCount++);

      s.update((set) {
        set.remove(1);
        set.add(3);
      });
      expect(s.toSet(), {2, 3});
      expect(callCount, 1);
    });

    test('Set.obs extension creates RxSet', () {
      final rx = {1, 2, 3}.obs;
      expect(rx, isA<RxSet<int>>());
      expect(rx.toSet(), {1, 2, 3});
    });
  });

  // ============================================================
  // 集合 subscribe / listener 测试
  // ============================================================
  group('Collection listener notifications', () {
    test('RxList listeners fire on modification', () {
      final list = RxList<int>([1]);
      final received = <List<int>>[];
      list.listen((v) => received.add(List.from(v)));

      list.add(2);
      list.add(3);

      expect(received.length, 2);
      expect(received[0], [1, 2]);
      expect(received[1], [1, 2, 3]);
    });

    test('RxMap listeners fire on modification', () {
      final map = RxMap<String, int>({});
      final received = <Map<String, int>>[];
      map.listen((v) => received.add(Map.from(v)));

      map['a'] = 1;
      map['b'] = 2;

      expect(received.length, 2);
      expect(received[0], {'a': 1});
      expect(received[1], {'a': 1, 'b': 2});
    });

    test('RxSet listeners fire on modification', () {
      final s = RxSet<int>();
      final received = <Set<int>>[];
      s.listen((v) => received.add(Set.from(v)));

      s.add(1);
      s.add(2);

      expect(received.length, 2);
      expect(received[0], {1});
      expect(received[1], {1, 2});
    });
  });

  group('Collection unwrap without dependency', () {
    test('RxList.toList does not register proxy dependency', () {
      final observer = ObxObserver();
      final list = RxList<int>([1, 2]);

      RxInterface.testDependents(observer, () {
        expect(list.toList(), [1, 2]);
      });

      expect(observer.canUpdate, false);
    });

    test('RxMap.toMap does not register proxy dependency', () {
      final observer = ObxObserver();
      final map = RxMap<String, int>({'a': 1});

      RxInterface.testDependents(observer, () {
        expect(map.toMap(), {'a': 1});
      });

      expect(observer.canUpdate, false);
    });

    test('RxSet.toSet does not register proxy dependency', () {
      final observer = ObxObserver();
      final s = RxSet<int>({1, 2});

      RxInterface.testDependents(observer, () {
        expect(s.toSet(), {1, 2});
      });

      expect(observer.canUpdate, false);
    });

    test('RxMap.containsKey registers proxy dependency once', () {
      final observer = ObxObserver();
      final map = RxMap<String, int>({'a': 1, 'b': 2});

      RxInterface.notifyDependents(observer, () {
        expect(map.containsKey('a'), true);
        expect(map.containsKey('missing'), false);
      });

      expect(observer.canUpdate, true);
    });

    test('RxMap.containsValue registers proxy dependency once', () {
      final observer = ObxObserver();
      final map = RxMap<String, int>({'a': 1, 'b': 2});

      RxInterface.notifyDependents(observer, () {
        expect(map.containsValue(2), true);
        expect(map.containsValue(99), false);
      });

      expect(observer.canUpdate, true);
    });

    test('RxSet.contains registers proxy dependency once', () {
      final observer = ObxObserver();
      final s = RxSet<int>({1, 2});

      RxInterface.notifyDependents(observer, () {
        expect(s.contains(1), true);
        expect(s.contains(99), false);
      });

      expect(observer.canUpdate, true);
    });

    test('RxList iterator registers proxy dependency once', () {
      final observer = ObxObserver();
      final list = RxList<int>([1, 2, 3]);

      RxInterface.notifyDependents(observer, () {
        expect([for (final e in list) e], [1, 2, 3]);
      });

      expect(observer.canUpdate, true);
    });

    test('RxList.reversed registers proxy dependency once', () {
      final observer = ObxObserver();
      final list = RxList<int>([1, 2, 3]);

      RxInterface.notifyDependents(observer, () {
        expect(list.reversed.toList(), [3, 2, 1]);
      });

      expect(observer.canUpdate, true);
    });
  });
}
