import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:state_restoration_hook/src/state_restoration_hook.dart';

/// A [HookRestorableValue] that makes the wrapped value accessible to the owning
/// [State] object via the [value] getter and setter.
///
/// Whenever a new [value] is set, [didUpdateValue] is called. Subclasses should
/// call [notifyListeners] from this method if the new value changes what
/// [toPrimitives] returns.
///
///
/// See also:
///
///  * [HookRestorableProperty], which is the super class of this class.
///  * [RestorationManager], which provides an overview of how state restoration
///    works in Flutter.
abstract class HookRestorableValue<T> extends HookRestorableProperty<T> {
  /// The current value stored in this property.
  ///
  /// A representation of the current value is stored in the restoration data.
  /// During state restoration, the property will restore the value to what it
  /// was when the restoration data it is getting restored from was collected.
  ///
  /// The [value] can only be accessed after the property has been registered
  /// with a [RestorationMixin] by calling
  /// [registerForRestoration].
  T get value {
    assert(isRegistered);
    return _value as T;
  }

  T? _value;
  set value(T newValue) {
    assert(isRegistered);
    if (newValue != _value) {
      final T? oldValue = _value;
      _value = newValue;
      didUpdateValue(oldValue);
    }
  }

  @mustCallSuper
  @override
  void initWithValue(T value) {
    _value = value;
  }

  /// Called whenever a new value is assigned to [value].
  ///
  /// The new value can be accessed via the regular [value] getter and the
  /// previous value is provided as `oldValue`.
  ///
  /// Subclasses should call [notifyListeners] from this method, if the new
  /// value changes what [toPrimitives] returns.
  @protected
  void didUpdateValue(T? oldValue);
}

// _RestorablePrimitiveValueN and its subclasses allows for null values.
// See [_RestorablePrimitiveValue] for the non-nullable version of this class.
class _HookRestorablePrimitiveValueN<T extends Object?>
    extends HookRestorableValue<T> {
  _HookRestorablePrimitiveValueN(this._defaultValue)
      : assert(debugIsSerializableForRestoration(_defaultValue)),
        super();

  final T _defaultValue;

  @override
  T createDefaultValue() => _defaultValue;

  @override
  void didUpdateValue(T? oldValue) {
    assert(debugIsSerializableForRestoration(value));
    notifyListeners();
  }

  @override
  T fromPrimitives(Object? serialized) => serialized as T;

  @override
  Object? toPrimitives() => value;
}

// _RestorablePrimitiveValue and its subclasses are non-nullable.
// See [_RestorablePrimitiveValueN] for the nullable version of this class.
class _HookRestorablePrimitiveValue<T extends Object>
    extends _HookRestorablePrimitiveValueN<T> {
  _HookRestorablePrimitiveValue(super.defaultValue)
      : assert(debugIsSerializableForRestoration(defaultValue));

  @override
  set value(T value) {
    super.value = value;
  }

  @override
  T fromPrimitives(Object? serialized) {
    assert(serialized != null);
    return super.fromPrimitives(serialized);
  }

  @override
  Object toPrimitives() {
    return super.toPrimitives()!;
  }
}

/// A [HookRestorableProperty] that knows how to store and restore a [num].
///
/// See also:
///
///  * [HookRestorableNumN] for the nullable version of this class.
class HookRestorableNum<T extends num>
    extends _HookRestorablePrimitiveValue<T> {
  /// Creates a [RestorableNum].
  ///
  /// {@template flutter.widgets.RestorableNum.constructor}
  /// If no restoration data is available to restore the value in this property
  /// from, the property will be initialized with the provided `defaultValue`.
  /// {@endtemplate}
  HookRestorableNum(super.defaultValue);
}

/// A [HookRestorableProperty] that knows how to store and restore a [double].
///
/// {@macro flutter.widgets.RestorableNum}
///
/// See also:
///
///  * [HookRestorableDoubleN] for the nullable version of this class.
class HookRestorableDouble extends HookRestorableNum<double> {
  /// Creates a [RestorableDouble].
  ///
  /// {@macro flutter.widgets.RestorableNum.constructor}
  HookRestorableDouble(super.defaultValue);
}

/// A [HookRestorableProperty] that knows how to store and restore an [int].
///
/// {@macro flutter.widgets.RestorableNum}
///
/// See also:
///
///  * [HookRestorableIntN] for the nullable version of this class.
class HookRestorableInt extends HookRestorableNum<int> {
  /// Creates a [RestorableInt].
  ///
  /// {@macro flutter.widgets.RestorableNum.constructor}
  HookRestorableInt(super.defaultValue);
}

/// A [HookRestorableProperty] that knows how to store and restore a [String].
///
/// {@macro flutter.widgets.RestorableNum}
///
/// See also:
///
///  * [HookRestorableStringN] for the nullable version of this class.
class HookRestorableString extends _HookRestorablePrimitiveValue<String> {
  /// Creates a [RestorableString].
  ///
  /// {@macro flutter.widgets.RestorableNum.constructor}
  HookRestorableString(super.defaultValue);
}

/// A [HookRestorableProperty] that knows how to store and restore a [bool].
///
/// {@macro flutter.widgets.RestorableNum}
///
/// See also:
///
///  * [HookRestorableBoolN] for the nullable version of this class.
class HookRestorableBool extends _HookRestorablePrimitiveValue<bool> {
  /// Creates a [RestorableBool].
  ///
  /// {@macro flutter.widgets.RestorableNum.constructor}
  HookRestorableBool(super.defaultValue);
}


/// A [RestorableProperty] that knows how to store and restore a [bool] that is
/// nullable.
///
/// {@macro flutter.widgets.RestorableNum}
///
/// See also:
///
///  * [RestorableBool] for the non-nullable version of this class.
class HookRestorableBoolN extends _HookRestorablePrimitiveValueN<bool?> {
  /// Creates a [RestorableBoolN].
  ///
  /// {@macro flutter.widgets.RestorableNum.constructor}
  HookRestorableBoolN(super.defaultValue);
}

/// A [RestorableProperty] that knows how to store and restore a [num]
/// that is nullable.
///
/// {@macro flutter.widgets.RestorableNum}
///
/// Instead of using the more generic [RestorableNumN] directly, consider using
/// one of the more specific subclasses (e.g. [RestorableDoubleN] to store a
/// [double] and [RestorableIntN] to store an [int]).
///
/// See also:
///
///  * [RestorableNum] for the non-nullable version of this class.
class HookRestorableNumN<T extends num?> extends _HookRestorablePrimitiveValueN<T> {
  /// Creates a [RestorableNumN].
  ///
  /// {@macro flutter.widgets.RestorableNum.constructor}
  HookRestorableNumN(super.defaultValue);
}

/// A [RestorableProperty] that knows how to store and restore a [double]
/// that is nullable.
///
/// {@macro flutter.widgets.RestorableNum}
///
/// See also:
///
///  * [RestorableDouble] for the non-nullable version of this class.
class HookRestorableDoubleN extends HookRestorableNumN<double?> {
  /// Creates a [RestorableDoubleN].
  ///
  /// {@macro flutter.widgets.RestorableNum.constructor}
  HookRestorableDoubleN(super.defaultValue);
}

/// A [RestorableProperty] that knows how to store and restore an [int]
/// that is nullable.
///
/// {@macro flutter.widgets.RestorableNum}
///
/// See also:
///
///  * [RestorableInt] for the non-nullable version of this class.
class HookRestorableIntN extends HookRestorableNumN<int?> {
  /// Creates a [RestorableIntN].
  ///
  /// {@macro flutter.widgets.RestorableNum.constructor}
  HookRestorableIntN(super.defaultValue);
}

/// A [RestorableProperty] that knows how to store and restore a [String]
/// that is nullable.
///
/// {@macro flutter.widgets.RestorableNum}
///
/// See also:
///
///  * [RestorableString] for the non-nullable version of this class.
class HookRestorableStringN extends _HookRestorablePrimitiveValueN<String?> {

  HookRestorableStringN(super.defaultValue);
}

/// A [RestorableValue] that knows how to save and restore [DateTime].
///
/// {@macro flutter.widgets.RestorableNum}.
class HookRestorableDateTime extends HookRestorableValue<DateTime> {

  HookRestorableDateTime(DateTime defaultValue) : _defaultValue = defaultValue;

  final DateTime _defaultValue;

  @override
  DateTime createDefaultValue() => _defaultValue;

  @override
  void didUpdateValue(DateTime? oldValue) {
    assert(debugIsSerializableForRestoration(value.millisecondsSinceEpoch));
    notifyListeners();
  }

  @override
  DateTime fromPrimitives(Object? data) => DateTime.fromMillisecondsSinceEpoch(data! as int);

  @override
  Object? toPrimitives() => value.millisecondsSinceEpoch;
}

/// A [RestorableValue] that knows how to save and restore [DateTime] that is
/// nullable.
///
/// {@macro flutter.widgets.RestorableNum}.
class HookRestorableDateTimeN extends HookRestorableValue<DateTime?> {
  /// Creates a [RestorableDateTime].
  ///
  /// {@macro flutter.widgets.RestorableNum.constructor}
  HookRestorableDateTimeN(DateTime? defaultValue) : _defaultValue = defaultValue;

  final DateTime? _defaultValue;

  @override
  DateTime? createDefaultValue() => _defaultValue;

  @override
  void didUpdateValue(DateTime? oldValue) {
    assert(debugIsSerializableForRestoration(value?.millisecondsSinceEpoch));
    notifyListeners();
  }

  @override
  DateTime? fromPrimitives(Object? data) => data != null ? DateTime.fromMillisecondsSinceEpoch(data as int) : null;

  @override
  Object? toPrimitives() => value?.millisecondsSinceEpoch;
}


// A base class for creating a [RestorableProperty] that stores and restores a
/// [Listenable].
///
/// This class may be used to implement a [RestorableProperty] for a
/// [Listenable], whose information it needs to store in the restoration data
/// change whenever the [Listenable] notifies its listeners.
///
/// The [RestorationMixin] this property is registered with will call
/// [toPrimitives] whenever the wrapped [Listenable] notifies its listeners to
/// update the information that this property has stored in the restoration
/// data.
abstract class HookRestorableListenable<T extends Listenable> extends HookRestorableProperty<T> {
  /// The [Listenable] stored in this property.
  ///
  /// A representation of the current value of the [Listenable] is stored in the
  /// restoration data. During state restoration, the [Listenable] returned by
  /// this getter will be restored to the state it had when the restoration data
  /// the property is getting restored from was collected.
  ///
  /// The [value] can only be accessed after the property has been registered
  /// with a [RestorationMixin] by calling
  /// [RestorationMixin.registerForRestoration].
  T get value {
    assert(isRegistered);
    return _value!;
  }
  T? _value;

  @override
  void initWithValue(T value) {
    _value?.removeListener(notifyListeners);
    _value = value;
    _value!.addListener(notifyListeners);
  }

  @override
  void dispose() {
    super.dispose();
    _value?.removeListener(notifyListeners);
  }
}

/// A base class for creating a [RestorableProperty] that stores and restores a
/// [ChangeNotifier].
///
/// This class may be used to implement a [RestorableProperty] for a
/// [ChangeNotifier], whose information it needs to store in the restoration
/// data change whenever the [ChangeNotifier] notifies its listeners.
///
/// The [RestorationMixin] this property is registered with will call
/// [toPrimitives] whenever the wrapped [ChangeNotifier] notifies its listeners
/// to update the information that this property has stored in the restoration
/// data.
///
/// Furthermore, the property will dispose the wrapped [ChangeNotifier] when
/// either the property itself is disposed or its value is replaced with another
/// [ChangeNotifier] instance.
abstract class HookRestorableChangeNotifier<T extends ChangeNotifier> extends HookRestorableListenable<T> {
  @override
  void initWithValue(T value) {
    _disposeOldValue();
    super.initWithValue(value);
  }

  @override
  void dispose() {
    _disposeOldValue();
    super.dispose();
  }

  void _disposeOldValue() {
    if (_value != null) {
      // Scheduling a microtask for dispose to give other entities a chance
      // to remove their listeners first.
      scheduleMicrotask(_value!.dispose);
    }
  }
}

/// A [HookRestorableProperty] that knows how to store and restore a
/// [TextEditingController].
///
/// The [TextEditingController] is accessible via the [value] getter. During
/// state restoration, the property will restore [TextEditingController.text] to
/// the value it had when the restoration data it is getting restored from was
/// collected.
class HookRestorableTextEditingController extends HookRestorableChangeNotifier<TextEditingController> {
  /// Creates a [RestorableTextEditingController].
  ///
  /// This constructor treats a null `text` argument as if it were the empty
  /// string.
  factory HookRestorableTextEditingController({String? text}) => HookRestorableTextEditingController.fromValue(
    text == null ? TextEditingValue.empty : TextEditingValue(text: text),
  );

  /// Creates a [RestorableTextEditingController] from an initial
  /// [TextEditingValue].
  ///
  /// This constructor treats a null `value` argument as if it were
  /// [TextEditingValue.empty].
  HookRestorableTextEditingController.fromValue(TextEditingValue value) : _initialValue = value;

  final TextEditingValue _initialValue;

  @override
  TextEditingController createDefaultValue() {
    return TextEditingController.fromValue(_initialValue);
  }

  @override
  TextEditingController fromPrimitives(Object? data) {
    return TextEditingController(text: data! as String);
  }

  @override
  Object toPrimitives() {
    return value.text;
  }
}

/// A [HookRestorableProperty] that knows how to store and restore a nullable [Enum]
/// type.
///
/// {@macro flutter.widgets.RestorableNum}
///
/// The values are serialized using the name of the enum, obtained using the
/// [EnumName.name] extension accessor.
///
/// The represented value is accessible via the [value] getter. The set of
/// values in the enum are accessible via the [values] getter. Since
/// [HookRestorableEnumN] allows null, this set will include null.
///
/// See also:
///
/// * [HookRestorableEnum], a class similar to this one that knows how to store and
///   restore non-nullable [Enum] types.
class HookRestorableEnumN<T extends Enum> extends HookRestorableValue<T?> {
  /// Creates a [RestorableEnumN].
  ///
  /// {@macro flutter.widgets.RestorableNum.constructor}
  HookRestorableEnumN(T? defaultValue, { required Iterable<T> values })
      : assert(defaultValue == null || values.contains(defaultValue),
  'Default value $defaultValue not found in $T values: $values'),
        _defaultValue = defaultValue,
        values = values.toSet();

  @override
  T? createDefaultValue() => _defaultValue;
  final T? _defaultValue;

  @override
  set value(T? newValue) {
    assert(newValue == null || values.contains(newValue),
    'Attempted to set an unknown enum value "$newValue" that is not null, or '
        'in the valid set of enum values for the $T type: '
        '${values.map<String>((T value) => value.name).toSet()}');
    super.value = newValue;
  }

  /// The set of non-null values that this [RestorableEnumN] may represent.
  ///
  /// This is a required field that supplies the enum values that are serialized
  /// and restored.
  ///
  /// If a value is encountered that is not null or a value in this set,
  /// [fromPrimitives] will assert when restoring.
  ///
  /// It is typically set to the `values` list of the enum type.
  ///
  /// In addition to this set, because [RestorableEnumN] allows nullable values,
  /// null is also a valid value, even though it doesn't appear in this set.
  ///
  /// {@tool snippet} For example, to create a [RestorableEnumN] with an
  /// [AxisDirection] enum value, with a default value of null, you would build
  /// it like the code below:
  ///
  /// ```dart
  /// RestorableEnumN<AxisDirection> axis = RestorableEnumN<AxisDirection>(null, values: AxisDirection.values);
  /// ```
  /// {@end-tool}
  Set<T> values;

  @override
  void didUpdateValue(T? oldValue) {
    notifyListeners();
  }

  @override
  T? fromPrimitives(Object? data) {
    if (data == null) {
      return null;
    }
    if (data is String) {
      for (final T allowed in values) {
        if (allowed.name == data) {
          return allowed;
        }
      }
      assert(false,
      'Attempted to set an unknown enum value "$data" that is not null, or '
          'in the valid set of enum values for the $T type: '
          '${values.map<String>((T value) => value.name).toSet()}');
    }
    return _defaultValue;
  }

  @override
  Object? toPrimitives() => value?.name;
}


/// A [HookRestorableProperty] that knows how to store and restore an [Enum]
/// type.
///
/// {@macro flutter.widgets.RestorableNum}
///
/// The values are serialized using the name of the enum, obtained using the
/// [EnumName.name] extension accessor.
///
/// The represented value is accessible via the [value] getter.
///
/// See also:
///
/// * [HookRestorableEnumN], a class similar to this one that knows how to store and
///   restore nullable [Enum] types.
class HookRestorableEnum<T extends Enum> extends HookRestorableValue<T> {
  /// Creates a [RestorableEnum].
  HookRestorableEnum(T defaultValue, { required Iterable<T> values })
      : assert(values.contains(defaultValue),
  'Default value $defaultValue not found in $T values: $values'),
        _defaultValue = defaultValue,
        values = values.toSet();

  @override
  T createDefaultValue() => _defaultValue;
  final T _defaultValue;

  @override
  set value(T newValue) {
    assert(values.contains(newValue),
    'Attempted to set an unknown enum value "$newValue" that is not in the '
        'valid set of enum values for the $T type: '
        '${values.map<String>((T value) => value.name).toSet()}');

    super.value = newValue;
  }

  /// The set of values that this [HookRestorableEnum] may represent.
  ///
  /// This is a required field that supplies the possible enum values that can
  /// be serialized and restored.
  ///
  /// If a value is encountered that is not in this set, [fromPrimitives] will
  /// assert when restoring.
  ///
  /// It is typically set to the `values` list of the enum type.
  Set<T> values;

  @override
  void didUpdateValue(T? oldValue) {
    notifyListeners();
  }

  @override
  T fromPrimitives(Object? data) {
    if (data != null && data is String) {
      for (final T allowed in values) {
        if (allowed.name == data) {
          return allowed;
        }
      }
      assert(false,
      'Attempted to restore an unknown enum value "$data" that is not in the '
          'valid set of enum values for the $T type: '
          '${values.map<String>((T value) => value.name).toSet()}');
    }
    return _defaultValue;
  }

  @override
  Object toPrimitives() => value.name;
}
