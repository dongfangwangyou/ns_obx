import 'rx_base.dart';

extension RxObjectExtension<T> on T {
  Rx<T> get obs => Rx<T>(this);
}

/// bool 类型的响应式扩展
/// 使用示例：`true.obs` 或 `false.obs`
extension RxBoolExtension on bool {
  RxBool get obs => RxBool(this);
}

class RxBool extends Rx<bool> {
  RxBool(super.initial);

  @override
  String toString() => value ? 'true' : 'false';

  bool get isTrue => value;

  bool get isFalse => !isTrue;

  bool operator &(bool other) => other && value;

  bool operator |(bool other) => other || value;

  bool operator ^(bool other) => !other == value;

  Rx<bool> toggle() {
    value = !value;
    return this;
  }
}

class RxBoolNullable extends Rx<bool?> {
  RxBoolNullable([super.initial]);

  @override
  String toString() => '$value';

  bool? get isTrue => value;

  bool? get isFalse => value != null ? !isTrue! : null;

  bool? operator &(bool other) => value != null ? other && value! : null;

  bool? operator |(bool other) => value != null ? other || value! : null;

  bool? operator ^(bool other) => !other == value;

  Rx<bool?>? toggle() {
    if (value != null) {
      value = !value!;
      return this;
    }
    return null;
  }
}

/// double 类型的响应式扩展
/// 使用示例：`3.14.obs`
extension RxDoubleExtension on double {
  RxDouble get obs => RxDouble(this);
}

class RxDouble extends Rx<double> {
  RxDouble(super.initial);

  Rx<double> operator +(num other) {
    value = value + other;
    return this;
  }

  Rx<double> operator -(num other) {
    value = value - other;
    return this;
  }
}

class RxDoubleNullable extends Rx<double?> {
  RxDoubleNullable([super.initial]);

  Rx<double?>? operator +(num other) {
    if (value != null) {
      value = value! + other;
      return this;
    }
    return null;
  }

  Rx<double?>? operator -(num other) {
    if (value != null) {
      value = value! - other;
      return this;
    }
    return null;
  }
}

/// int 类型的响应式扩展
/// 使用示例：`42.obs`
extension RxIntExtension on int {
  RxInt get obs => RxInt(this);
}

class RxInt extends Rx<int> {
  RxInt(super.initial);

  RxInt operator +(int other) {
    value = value + other;
    return this;
  }

  RxInt operator -(int other) {
    value = value - other;
    return this;
  }

  num operator *(num other) => value * other;

  num operator %(num other) => value % other;

  double operator /(num other) => value / other;

  int operator ~/(num other) => value ~/ other;

  int operator &(int other) => value & other;

  int operator |(int other) => value | other;

  int operator ^(int other) => value ^ other;

  int operator ~() => ~value;

  int operator <<(int shiftAmount) => value << shiftAmount;

  int operator >>(int shiftAmount) => value >> shiftAmount;

  int modPow(int exponent, int modulus) => value.modPow(exponent, modulus);

  int modInverse(int modulus) => value.modInverse(modulus);

  int gcd(int other) => value.gcd(other);

  int operator -() => -value;
}

class RxnInt extends Rx<int?> {
  RxnInt([super.initial]);

  RxnInt? operator +(int other) {
    if (value != null) {
      value = value! + other;
      return this;
    }
    return null;
  }

  RxnInt? operator -(int other) {
    if (value != null) {
      value = value! - other;
      return this;
    }
    return null;
  }

  int? operator &(int other) => value != null ? value! & other : null;

  int? operator |(int other) => value != null ? value! | other : null;

  int? operator ^(int other) => value != null ? value! ^ other : null;

  int? operator ~() => value != null ? ~value! : null;

  int? operator <<(int shiftAmount) =>
      value != null ? value! << shiftAmount : null;

  int? operator >>(int shiftAmount) =>
      value != null ? value! >> shiftAmount : null;

  int? modPow(int exponent, int modulus) =>
      value?.modPow(exponent, modulus);

  int? modInverse(int modulus) =>
      value?.modInverse(modulus);

  int? gcd(int other) => value?.gcd(other);

  int? operator -() => value != null ? -value! : null;
}

extension RxStringExtension on String {
  RxString get obs => RxString(this);
}

class RxString extends Rx<String> implements Comparable<String>, Pattern {
  RxString(super.initial);

  @override
  Iterable<Match> allMatches(String string, [int start = 0]) =>
      rawValue.allMatches(string, start);

  @override
  Match? matchAsPrefix(String string, [int start = 0]) =>
      rawValue.matchAsPrefix(string, start);

  @override
  int compareTo(String other) => rawValue.compareTo(other);
}

class RxStringNullable extends Rx<String?> implements Comparable<String?>, Pattern {
  RxStringNullable([super.initial]);

  @override
  Iterable<Match> allMatches(String string, [int start = 0]) =>
      rawValue?.allMatches(string, start) ?? <Match>[];

  @override
  Match? matchAsPrefix(String string, [int start = 0]) =>
      rawValue?.matchAsPrefix(string, start);

  @override
  int compareTo(String? other) {
    if (rawValue == null && other == null) return 0;
    if (rawValue == null) return -1;
    if (other == null) return 1;
    return rawValue!.compareTo(other);
  }
}
