import 'package:flutter_test/flutter_test.dart';
import 'package:ns_obx/ns_obx.dart';

void main() {
  // ============================================================
  // RxnInt - 可空 int 响应式变量
  // ============================================================
  group('RxnInt', () {
    test('initial value null', () {
      final rx = RxnInt();
      expect(rx.value, isNull);
    });

    test('initial value non-null', () {
      final rx = RxnInt(42);
      expect(rx.value, 42);
    });

    test('assign null', () {
      final rx = RxnInt(10);
      rx.value = null;
      expect(rx.value, isNull);
    });

    test('assign non-null', () {
      final rx = RxnInt();
      rx.value = 99;
      expect(rx.value, 99);
    });

    test('operator + with non-null value returns this', () {
      final rx = RxnInt(10);
      final result = rx + 5;
      expect(result, same(rx));
      expect(rx.value, 15);
    });

    test('operator + with null value returns null', () {
      final rx = RxnInt();
      final result = rx + 5;
      expect(result, isNull);
      expect(rx.value, isNull);
    });

    test('operator - with non-null value returns this', () {
      final rx = RxnInt(10);
      final result = rx - 3;
      expect(result, same(rx));
      expect(rx.value, 7);
    });

    test('operator - with null value returns null', () {
      final rx = RxnInt();
      final result = rx - 3;
      expect(result, isNull);
      expect(rx.value, isNull);
    });

    test('operator & with null returns null', () {
      final rx = RxnInt();
      expect(rx & 0xFF, isNull);
    });

    test('operator & with non-null returns result', () {
      final rx = RxnInt(0xFF);
      expect(rx & 0x0F, 0x0F);
    });

    test('operator | with null returns null', () {
      final rx = RxnInt();
      expect(rx | 0x0F, isNull);
    });

    test('operator | with non-null returns result', () {
      final rx = RxnInt(0xF0);
      expect(rx | 0x0F, 0xFF);
    });

    test('operator ^ with null returns null', () {
      final rx = RxnInt();
      expect(rx ^ 0xFF, isNull);
    });

    test('unary operator - with null returns null', () {
      final rx = RxnInt();
      expect(-rx, isNull);
    });

    test('unary operator - with non-null returns negated', () {
      final rx = RxnInt(5);
      expect(-rx, -5);
    });

    test('unary operator ~ with null returns null', () {
      final rx = RxnInt();
      expect(~rx, isNull);
    });

    test('unary operator ~ with non-null returns bit-wise not', () {
      final rx = RxnInt(0);
      expect(~rx, -1);
    });

    test('operator << with null returns null', () {
      final rx = RxnInt();
      expect(rx << 2, isNull);
    });

    test('operator << with non-null returns shifted', () {
      final rx = RxnInt(1);
      expect(rx << 3, 8);
    });

    test('operator >> with null returns null', () {
      final rx = RxnInt();
      expect(rx >> 2, isNull);
    });

    test('operator >> with non-null returns shifted', () {
      final rx = RxnInt(8);
      expect(rx >> 2, 2);
    });

    test('modPow with null returns null', () {
      final rx = RxnInt();
      expect(rx.modPow(2, 10), isNull);
    });

    test('modPow with non-null returns result', () {
      final rx = RxnInt(3);
      expect(rx.modPow(2, 7), 2); // 3^2 % 7 = 9 % 7 = 2
    });

    test('modInverse with null returns null', () {
      final rx = RxnInt();
      expect(rx.modInverse(7), isNull);
    });

    test('gcd with null returns null', () {
      final rx = RxnInt();
      expect(rx.gcd(6), isNull);
    });

    test('gcd with non-null returns result', () {
      final rx = RxnInt(12);
      expect(rx.gcd(8), 4);
    });
  });

  // ============================================================
  // RxnDouble - 可空 double 响应式变量
  // ============================================================
  group('RxnDouble', () {
    test('initial value null', () {
      final rx = RxDoubleNullable();
      expect(rx.value, isNull);
    });

    test('initial value non-null', () {
      final rx = RxDoubleNullable(3.14);
      expect(rx.value, closeTo(3.14, 0.0001));
    });

    test('assign null', () {
      final rx = RxDoubleNullable(2.5);
      rx.value = null;
      expect(rx.value, isNull);
    });

    test('assign non-null', () {
      final rx = RxDoubleNullable();
      rx.value = 1.5;
      expect(rx.value, closeTo(1.5, 0.0001));
    });

    test('operator + with non-null returns this', () {
      final rx = RxDoubleNullable(3.0);
      final result = rx + 2.0;
      expect(result, same(rx));
      expect(rx.value, closeTo(5.0, 0.0001));
    });

    test('operator + with null returns null', () {
      final rx = RxDoubleNullable();
      final result = rx + 2.0;
      expect(result, isNull);
      expect(rx.value, isNull);
    });

    test('operator - with non-null returns this', () {
      final rx = RxDoubleNullable(5.0);
      final result = rx - 2.0;
      expect(result, same(rx));
      expect(rx.value, closeTo(3.0, 0.0001));
    });

    test('operator - with null returns null', () {
      final rx = RxDoubleNullable();
      final result = rx - 2.0;
      expect(result, isNull);
    });
  });

  // ============================================================
  // RxnBool - 可空 bool 响应式变量
  // ============================================================
  group('RxnBool', () {
    test('initial value null', () {
      final rx = RxBoolNullable();
      expect(rx.value, isNull);
    });

    test('initial value non-null', () {
      final rx = RxBoolNullable(true);
      expect(rx.value, true);
    });

    test('assign null', () {
      final rx = RxBoolNullable(true);
      rx.value = null;
      expect(rx.value, isNull);
    });

    test('assign non-null', () {
      final rx = RxBoolNullable();
      rx.value = false;
      expect(rx.value, false);
    });

    test('isTrue with null returns null', () {
      final rx = RxBoolNullable();
      expect(rx.isTrue, isNull);
    });

    test('isTrue with true value', () {
      final rx = RxBoolNullable(true);
      expect(rx.isTrue, true);
    });

    test('isFalse with null returns null', () {
      final rx = RxBoolNullable();
      expect(rx.isFalse, isNull);
    });

    test('isFalse with false value', () {
      final rx = RxBoolNullable(false);
      expect(rx.isFalse, true);
    });

    test('operator & with null returns null', () {
      final rx = RxBoolNullable();
      expect(rx & true, isNull);
    });

    test('operator & with non-null', () {
      final rx = RxBoolNullable(true);
      expect(rx & true, true);
      expect(rx & false, false);
    });

    test('operator | with null returns null', () {
      final rx = RxBoolNullable();
      expect(rx | true, isNull);
    });

    test('operator | with non-null', () {
      final rx = RxBoolNullable(false);
      expect(rx | true, true);
      expect(rx | false, false);
    });

    test('operator ^ with null', () {
      final rx = RxBoolNullable();
      final result = rx ^ true;
      expect(result, false); // !true == null? → false
    });

    test('operator ^ with non-null matching', () {
      final rx = RxBoolNullable(true);
      expect(rx ^ true, false);
    });

    test('operator ^ with non-null different', () {
      final rx = RxBoolNullable(true);
      expect(rx ^ false, true);
    });

    test('toggle with non-null value', () {
      final rx = RxBoolNullable(true);
      final result = rx.toggle();
      expect(result, same(rx));
      expect(rx.value, false);
    });

    test('toggle with null returns null', () {
      final rx = RxBoolNullable();
      final result = rx.toggle();
      expect(result, isNull);
      expect(rx.value, isNull);
    });

    test('toString with null', () {
      final rx = RxBoolNullable();
      expect(rx.toString(), 'null');
    });
  });

  // ============================================================
  // RxnString - 可空 String 响应式变量
  // ============================================================
  group('RxnString', () {
    test('initial value null', () {
      final rx = RxStringNullable();
      expect(rx.value, isNull);
    });

    test('initial value non-null', () {
      final rx = RxStringNullable('hello');
      expect(rx.value, 'hello');
    });

    test('assign null', () {
      final rx = RxStringNullable('test');
      rx.value = null;
      expect(rx.value, isNull);
    });

    test('assign non-null', () {
      final rx = RxStringNullable();
      rx.value = 'world';
      expect(rx.value, 'world');
    });

    test('allMatches with null returns empty list', () {
      final rx = RxStringNullable();
      final matches = rx.allMatches('abc');
      expect(matches, isEmpty);
    });

    test('allMatches with non-null matches pattern', () {
      // RxStringNullable implements Pattern: rx.value is the pattern,
      // allMatches(string) searches for this pattern inside string.
      // 'hello' as a literal pattern in 'hello world hello' → 2 matches
      final rx = RxStringNullable('hello');
      final matches = rx.allMatches('hello world hello');
      expect(matches.length, 2);
    });

    test('matchAsPrefix with null returns null', () {
      final rx = RxStringNullable();
      final match = rx.matchAsPrefix('abc');
      expect(match, isNull);
    });

    test('matchAsPrefix with non-null matches prefix', () {
      // Pattern.matchAsPrefix(string): checks if string starts with this pattern.
      // 'hel' as pattern → 'hello world' starts with 'hel' → match
      final rx = RxStringNullable('hel');
      final match = rx.matchAsPrefix('hello world');
      expect(match, isNotNull);
      expect(match!.start, 0);
    });

    test('matchAsPrefix with non-null no match returns null', () {
      // 'xyz' as pattern → does not match prefix of 'hello world' → null
      final rx = RxStringNullable('xyz');
      final match = rx.matchAsPrefix('hello world');
      expect(match, isNull);
    });

    test('compareTo null vs null returns 0', () {
      final rx = RxStringNullable();
      expect(rx.compareTo(null), 0);
    });

    test('compareTo null vs non-null returns -1', () {
      final rx = RxStringNullable();
      expect(rx.compareTo('a'), -1);
    });

    test('compareTo non-null vs null returns 1', () {
      final rx = RxStringNullable('a');
      expect(rx.compareTo(null), 1);
    });

    test('compareTo both non-null uses String.compareTo', () {
      final rx = RxStringNullable('abc');
      expect(rx.compareTo('abd'), -1);
      expect(rx.compareTo('abc'), 0);
      expect(rx.compareTo('abb'), 1);
    });
  });

  // ============================================================
  // 可空类型 listener 通知
  // ============================================================
  group('Nullable type listener notifications', () {
    test('RxnInt notifies listener on value change', () {
      final rx = RxnInt(0);
      final values = <int?>[];
      rx.listen((v) => values.add(v));

      rx.value = 5;
      rx.value = null;
      rx.value = 10;

      expect(values, [5, null, 10]);
    });

    test('RxnDouble notifies listener on value change', () {
      final rx = RxDoubleNullable(1.0);
      final values = <double?>[];
      rx.listen((v) => values.add(v));

      rx.value = 2.5;
      rx.value = null;

      expect(values.length, 2);
      expect(values[0], closeTo(2.5, 0.0001));
      expect(values[1], isNull);
    });

    test('RxnBool notifies listener on value change', () {
      final rx = RxBoolNullable(false);
      final values = <bool?>[];
      rx.listen((v) => values.add(v));

      rx.value = true;
      rx.value = null;

      expect(values, [true, null]);
    });

    test('RxnString notifies listener on value change', () {
      final rx = RxStringNullable('a');
      final values = <String?>[];
      rx.listen((v) => values.add(v));

      rx.value = 'b';
      rx.value = null;

      expect(values, ['b', null]);
    });
  });
}
