import 'rx_base.dart';

/// Provides `.obs` for any value, creating an [Rx] wrapper.
extension RxObjectExtension<T> on T {
  /// Returns an [Rx] that wraps this value.
  Rx<T> get obs => Rx<T>(this);
}

/// Extensions for creating a reactive [bool] via `.obs`.
extension RxBoolExtension on bool {
  /// Returns a reactive [bool] wrapping this value.
  RxBool get obs => RxBool(this);
}

/// A reactive wrapper around a non-nullable [bool].
class RxBool extends Rx<bool> {
  /// Creates a reactive [bool] with the given [initial] value.
  RxBool(super.initial);

  @override
  String toString() => value ? 'true' : 'false';

  /// Whether the current value is `true`.
  bool get isTrue => value;

  /// Whether the current value is `false`.
  bool get isFalse => !isTrue;

  /// Logical AND with [other].
  bool operator &(bool other) => other && value;

  /// Logical OR with [other].
  bool operator |(bool other) => other || value;

  /// Logical XOR with [other].
  bool operator ^(bool other) => !other == value;

  /// Toggles the current value and returns this [RxBool].
  Rx<bool> toggle() {
    value = !value;
    return this;
  }
}

/// A reactive wrapper around a nullable [bool].
class RxBoolNullable extends Rx<bool?> {
  /// Creates a reactive nullable [bool] with the given [initial] value.
  RxBoolNullable([super.initial]);

  @override
  String toString() => '$value';

  /// The current value when it is `true`, or `null`.
  bool? get isTrue => value;

  /// The negated current value, or `null` when the value is `null`.
  bool? get isFalse => value != null ? !isTrue! : null;

  /// Logical AND with [other], or `null` when the value is `null`.
  bool? operator &(bool other) => value != null ? other && value! : null;

  /// Logical OR with [other], or `null` when the value is `null`.
  bool? operator |(bool other) => value != null ? other || value! : null;

  /// Logical XOR with [other], or `null` when the value is `null`.
  bool? operator ^(bool other) => !other == value;

  /// Toggles the current value when it is not `null`.
  Rx<bool?>? toggle() {
    if (value != null) {
      value = !value!;
      return this;
    }
    return null;
  }
}

/// Extensions for creating a reactive [double] via `.obs`.
extension RxDoubleExtension on double {
  /// Returns a reactive [double] wrapping this value.
  RxDouble get obs => RxDouble(this);
}

/// A reactive wrapper around a non-nullable [double].
class RxDouble extends Rx<double> {
  /// Creates a reactive [double] with the given [initial] value.
  RxDouble(super.initial);

  /// Adds [other] to [value] and stores the result.
  Rx<double> operator +(num other) {
    value = value + other;
    return this;
  }

  /// Subtracts [other] from [value] and stores the result.
  Rx<double> operator -(num other) {
    value = value - other;
    return this;
  }
}

/// A reactive wrapper around a nullable [double].
class RxDoubleNullable extends Rx<double?> {
  /// Creates a reactive nullable [double] with the given [initial] value.
  RxDoubleNullable([super.initial]);

  /// Adds [other] to [value] when it is not `null`.
  Rx<double?>? operator +(num other) {
    if (value != null) {
      value = value! + other;
      return this;
    }
    return null;
  }

  /// Subtracts [other] from [value] when it is not `null`.
  Rx<double?>? operator -(num other) {
    if (value != null) {
      value = value! - other;
      return this;
    }
    return null;
  }
}

/// Extensions for creating a reactive [int] via `.obs`.
extension RxIntExtension on int {
  /// Returns a reactive [int] wrapping this value.
  RxInt get obs => RxInt(this);
}

/// A reactive wrapper around a non-nullable [int].
class RxInt extends Rx<int> {
  /// Creates a reactive [int] with the given [initial] value.
  RxInt(super.initial);

  /// Adds [other] to [value] and stores the result.
  RxInt operator +(int other) {
    value = value + other;
    return this;
  }

  /// Subtracts [other] from [value] and stores the result.
  RxInt operator -(int other) {
    value = value - other;
    return this;
  }

  /// Multiplies [value] by [other].
  num operator *(num other) => value * other;

  /// Returns the remainder of dividing [value] by [other].
  num operator %(num other) => value % other;

  /// Divides [value] by [other].
  double operator /(num other) => value / other;

  /// Divides [value] by [other] and truncates to an [int].
  int operator ~/(num other) => value ~/ other;

  /// Bitwise AND with [other].
  int operator &(int other) => value & other;

  /// Bitwise OR with [other].
  int operator |(int other) => value | other;

  /// Bitwise XOR with [other].
  int operator ^(int other) => value ^ other;

  /// Bitwise complement of [value].
  int operator ~() => ~value;

  /// Bitwise left shift of [value] by [shiftAmount].
  int operator <<(int shiftAmount) => value << shiftAmount;

  /// Bitwise right shift of [value] by [shiftAmount].
  int operator >>(int shiftAmount) => value >> shiftAmount;

  /// See [int.modPow].
  int modPow(int exponent, int modulus) => value.modPow(exponent, modulus);

  /// See [int.modInverse].
  int modInverse(int modulus) => value.modInverse(modulus);

  /// See [int.gcd].
  int gcd(int other) => value.gcd(other);

  /// Negates [value].
  int operator -() => -value;
}

/// A reactive wrapper around a nullable [int].
class RxnInt extends Rx<int?> {
  /// Creates a reactive nullable [int] with the given [initial] value.
  RxnInt([super.initial]);

  /// Adds [other] to [value] when it is not `null`.
  RxnInt? operator +(int other) {
    if (value != null) {
      value = value! + other;
      return this;
    }
    return null;
  }

  /// Subtracts [other] from [value] when it is not `null`.
  RxnInt? operator -(int other) {
    if (value != null) {
      value = value! - other;
      return this;
    }
    return null;
  }

  /// Bitwise AND with [other], or `null` when the value is `null`.
  int? operator &(int other) => value != null ? value! & other : null;

  /// Bitwise OR with [other], or `null` when the value is `null`.
  int? operator |(int other) => value != null ? value! | other : null;

  /// Bitwise XOR with [other], or `null` when the value is `null`.
  int? operator ^(int other) => value != null ? value! ^ other : null;

  /// Bitwise complement of [value], or `null` when the value is `null`.
  int? operator ~() => value != null ? ~value! : null;

  /// Bitwise left shift of [value] by [shiftAmount], or `null` when the value is `null`.
  int? operator <<(int shiftAmount) =>
      value != null ? value! << shiftAmount : null;

  /// Bitwise right shift of [value] by [shiftAmount], or `null` when the value is `null`.
  int? operator >>(int shiftAmount) =>
      value != null ? value! >> shiftAmount : null;

  /// See [int.modPow], returning `null` when the value is `null`.
  int? modPow(int exponent, int modulus) =>
      value?.modPow(exponent, modulus);

  /// See [int.modInverse], returning `null` when the value is `null`.
  int? modInverse(int modulus) =>
      value?.modInverse(modulus);

  /// See [int.gcd], returning `null` when the value is `null`.
  int? gcd(int other) => value?.gcd(other);

  /// Negates [value], or returns `null` when the value is `null`.
  int? operator -() => value != null ? -value! : null;
}

/// Extensions for creating a reactive [String] via `.obs`.
extension RxStringExtension on String {
  /// Returns a reactive [String] wrapping this value.
  RxString get obs => RxString(this);
}

/// A reactive wrapper around a non-nullable [String].
class RxString extends Rx<String> implements Comparable<String>, Pattern {
  /// Creates a reactive [String] with the given [initial] value.
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

/// A reactive wrapper around a nullable [String].
class RxStringNullable extends Rx<String?> implements Comparable<String?>, Pattern {
  /// Creates a reactive nullable [String] with the given [initial] value.
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
