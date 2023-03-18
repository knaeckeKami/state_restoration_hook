import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:state_restoration_hook/src/hook_restorable_properties.dart';
import 'package:state_restoration_hook/src/restorable_property_hook.dart';

/// Manages an object of type `T`, whose value a [HookWidget] wants to have
/// restored during state restoration.
///
/// The property wraps an object of type `T`. It knows how to store its value in
/// the restoration data and it knows how to re-instantiate that object from the
/// information it previously stored in the restoration data.
///
/// The knowledge of how to store the wrapped object in the restoration data is
/// encoded in the [toPrimitives] method and the knowledge of how to
/// re-instantiate the object from that data is encoded in the [fromPrimitives]
/// method. A call to [toPrimitives] must return a representation of the wrapped
/// object that can be serialized with the [StandardMessageCodec]. If any
/// collections (e.g. [List]s, [Map]s, etc.) are returned, they must not be
/// modified after they have been returned from [toPrimitives]. At a later point
/// in time (which may be after the application restarted), the data obtained
/// from [toPrimitives] may be handed back to the property's [fromPrimitives]
/// method to restore it to the previous state described by that data.
///
/// A [HookRestorableProperty] needs to be registered to a [RestorationMixin] using
/// a restoration ID that is unique within the mixin. The [RestorationMixin]
/// provides and manages the [RestorationBucket], in which the data returned by
/// [toPrimitives] is stored.
///
/// Whenever the value returned by [toPrimitives] (or the [enabled] getter)
/// changes, the [HookRestorableProperty] must call [notifyListeners]. This will
/// trigger the [RestorationMixin] to update the data it has stored for the
/// property in its [RestorationBucket] to the latest information returned by
/// [toPrimitives].
///
/// When the property is registered with the [RestorationMixin], the mixin
/// checks whether there is any restoration data available for the property. If
/// data is available, the mixin calls [fromPrimitives] on the property, which
/// must return an object that matches the object the property wrapped when the
/// provided restoration data was obtained from [toPrimitives]. If no
/// restoration data is available to restore the property's wrapped object from,
/// the mixin calls [createDefaultValue]. The value returned by either of those
/// methods is then handed to the property's [initWithValue] method.
///
/// Usually, subclasses of [HookRestorableProperty] hold on to the value provided to
/// them in [initWithValue] and make it accessible to the [State] object that
/// owns the property. This [HookRestorableProperty] base class, however, has no
/// opinion about what to do with the value provided to [initWithValue].
///
/// The [RestorationMixin] may call [fromPrimitives]/[createDefaultValue]
/// followed by [initWithValue] multiple times throughout the life of a
/// [RestorableProperty]: Whenever new restoration data is made available to the
/// [RestorationMixin] the property is registered with, the cycle of calling
/// [fromPrimitives] (if the new restoration data contains information to
/// restore the property from) or [createDefaultValue] (if no information for
/// the property is available in the new restoration data) followed by a call to
/// [initWithValue] repeats. Whenever [initWithValue] is called, the property
/// should forget the old value it was wrapping and re-initialize itself with
/// the newly provided value.
///
/// In a typical use case, a subclass of [HookRestorableProperty] is instantiated
/// using the [useRestorableProperty] hook. It is then registered using the [useStateRestoration] hook.
/// For less common use cases (e.g. if the value stored in a
/// [HookRestorableProperty] is only needed while the [State] object is in a certain
/// state), a [HookRestorableProperty] may be registered using the returned [registerForRestoration]
/// function from the [useStateRestoration] hook
/// any time after [useStateRestoration] hook has been called for the first
/// time. A [HookRestorableProperty] may also be unregistered from a
/// [RestorationMixin] before the owning [State] object is disposed by calling
/// [RestorationMixin.unregisterFromRestoration]. This is uncommon, though, and
/// will delete the information that the property contributed from the
/// restoration data (meaning the value of the property will no longer be
/// restored during a future state restoration).
///
/// See also:
///
///  * [HookRestorableValue], which is a [HookRestorableProperty] that makes the wrapped
///    value accessible to the owning [State] object via a `value`
///    getter and setter.
///  * [RestorationManager], which describes how state restoration works in
///    Flutter.
abstract class HookRestorableProperty<T> extends ChangeNotifier {
  /// Called by the [RestorationMixin] if no restoration data is available to
  /// restore the value of the property from to obtain the default value for the
  /// property.
  ///
  /// The method returns the default value that the property should wrap if no
  /// restoration data is available. After this is called, [initWithValue] will
  /// be called with this method's return value.
  ///
  /// The method may be called multiple times throughout the life of the
  /// [HookRestorableProperty]. Whenever new restoration data has been provided to
  /// the [RestorationMixin] the property is registered to, either this method
  /// or [fromPrimitives] is called before [initWithValue] is invoked.
  T createDefaultValue();

  /// Called by the [RestorationMixin] to convert the `data` previously
  /// retrieved from [toPrimitives] back into an object of type `T` that this
  /// property should wrap.
  ///
  /// The object returned by this method is passed to [initWithValue] to restore
  /// the value that this property is wrapping to the value described by the
  /// provided `data`.
  ///
  /// The method may be called multiple times throughout the life of the
  /// [HookRestorableProperty]. Whenever new restoration data has been provided to
  /// the [RestorationMixin] the property is registered to, either this method
  /// or [createDefaultValue] is called before [initWithValue] is invoked.
  T fromPrimitives(Object? data);

  /// Called by the [RestorationMixin] with the `value` returned by either
  /// [createDefaultValue] or [fromPrimitives] to set the value that this
  /// property currently wraps.
  ///
  /// The [initWithValue] method may be called multiple times throughout the
  /// life of the [HookRestorableProperty] whenever new restoration data has been
  /// provided to the [RestorationMixin] the property is registered to. When
  /// [initWithValue] is called, the property should forget its previous value
  /// and re-initialize itself to the newly provided `value`.
  void initWithValue(T value);

  /// Called by the [RestorationMixin] to retrieve the information that this
  /// property wants to store in the restoration data.
  ///
  /// The returned object must be serializable with the [StandardMessageCodec]
  /// and if it includes any collections, those should not be modified after
  /// they have been returned by this method.
  ///
  /// The information returned by this method may be handed back to the property
  /// in a call to [fromPrimitives] at a later point in time (possibly after the
  /// application restarted) to restore the value that the property is currently
  /// wrapping.
  ///
  /// When the value returned by this method changes, the property must call
  /// [notifyListeners]. The [RestorationMixin] will invoke this method whenever
  /// the property's listeners are notified.
  Object? toPrimitives();

  /// Whether the object currently returned by [toPrimitives] should be included
  /// in the restoration state.
  ///
  /// When this returns false, no information is included in the restoration
  /// data for this property and the property will be initialized to its default
  /// value (obtained from [createDefaultValue]) the next time that restoration
  /// data is used for state restoration.
  ///
  /// Whenever the value returned by this getter changes, [notifyListeners] must
  /// be called. When the value changes from true to false, the information last
  /// retrieved from [toPrimitives] is removed from the restoration data. When
  /// it changes from false to true, [toPrimitives] is invoked to add the latest
  /// restoration information provided by this property to the restoration data.
  bool get enabled => true;

  bool _disposed = false;

  @override
  void dispose() {
    assert(ChangeNotifier.debugAssertNotDisposed(
        this)); // FYI, This uses ChangeNotifier's _debugDisposed, not _disposed.
    _owner?._unregister(this);
    super.dispose();
    _disposed = true;
  }

  // ID under which the property has been registered with the RestorationMixin.
  String? _restorationId;
  StateRestorationHookState? _owner;

  void _register(String restorationId, StateRestorationHookState owner) {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    _restorationId = restorationId;
    _owner = owner;
  }

  void _unregister() {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    assert(_restorationId != null);
    assert(_owner != null);
    _restorationId = null;
    _owner = null;
  }

  /// The [State] object that this property is registered with.
  ///
  /// Must only be called when [isRegistered] is true.
  @protected
  StateRestorationHookState get state {
    assert(isRegistered);
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    return _owner!;
  }

  /// Whether this property is currently registered with a [RestorationMixin].
  @protected
  bool get isRegistered {
    assert(ChangeNotifier.debugAssertNotDisposed(this));
    return _restorationId != null;
  }
}

typedef RegisterForRestoration = void Function(
    HookRestorableProperty<Object?> property, String restorationId);

typedef RestoreState = void Function(
  RestorationBucket? oldBucket,
  bool initialRestore,
  HookRestoration restoration,
);



HookRestoration useStateRestoration(
    {required String restorationId, required RestoreState restoreState}) {
  return use(StateRestorationHook(
      restoreState: restoreState, restorationId: restorationId));
}

class StateRestorationHook extends Hook<HookRestoration> {
  final void Function(
    RestorationBucket? oldBucket,
    bool initialRestore,
      HookRestoration registerForRestoration,
  ) restoreState;

  /// Called when [bucket] switches between null and non-null values.
  ///
  /// [State] objects that wish to directly interact with the bucket may
  /// override this method to store additional values in the bucket when one
  /// becomes available or to save values stored in a bucket elsewhere when the
  /// bucket goes away. This is uncommon and storing those values in
  /// [HookRestorableProperty]s should be considered instead.
  ///
  /// The `oldBucket` is provided to the method when the [bucket] getter changes
  /// from non-null to null. The `oldBucket` argument is null when the [bucket]
  /// changes from null to non-null.
  ///
  /// See also:
  ///
  ///  * [restoreState], which is called when the [bucket] changes from one
  ///    non-null value to another non-null value.
  final void Function(RestorationBucket? oldBucket)? didToggleBucket;

  final String? restorationId;

  const StateRestorationHook(
      {required this.restoreState,
      required this.restorationId,
      this.didToggleBucket});

  @override
  HookState<HookRestoration, StateRestorationHook> createState() =>
      StateRestorationHookState();
}

class StateRestorationHookState
    extends HookState<HookRestoration, StateRestorationHook> implements HookRestoration {
  /// The [RestorationBucket] used for the restoration data of the
  /// [HookRestorableProperty]s registered to this mixin.
  ///
  /// The bucket has been claimed from the surrounding [RestorationScope] using
  /// [restorationId].
  ///
  /// The getter returns null if state restoration is turned off. When state
  /// restoration is turned on or off during the lifetime of this mixin (and
  /// hence the return value of this getter switches between null and non-null)
  /// [didToggleBucket] is called.
  ///
  /// Interacting directly with this bucket is uncommon. However, the bucket may
  /// be injected into the widget tree in the [State]'s `build` method using an
  /// [UnmanagedRestorationScope]. That allows descendants to claim child
  /// buckets from this bucket for their own restoration needs.
  RestorationBucket? get bucket => _bucket;
  RestorationBucket? _bucket;

  String? get restorationId => hook.restorationId;

  // Maps properties to their listeners.
  final Map<HookRestorableProperty<Object?>, VoidCallback> _properties =
      <HookRestorableProperty<Object?>, VoidCallback>{};

  /// Registers a [HookRestorableProperty] for state restoration.
  ///
  /// The registration associates the provided `property` with the provided
  /// `restorationId`. If restoration data is available for the provided
  /// `restorationId`, the property's value is restored to the value described
  /// by the restoration data. If no restoration data is available, the property
  /// will be initialized to a property-specific default value.
  ///
  /// Each property within a [State] object must be registered under a unique
  /// ID. Only registered properties will have their values restored during
  /// state restoration.
  ///
  /// Typically, this method is called from within [restoreState] to register
  /// all restorable properties of the owning [State] object. However, if a
  /// given [HookRestorableProperty] is only needed when certain conditions are met
  /// within the [State], [registerForRestoration] may also be called at any
  /// time after [restoreState] has been invoked for the first time.
  ///
  /// A property that has been registered outside of [restoreState] must be
  /// re-registered within [restoreState] the next time that method is called
  /// unless it has been unregistered with [unregisterFromRestoration].
  @protected
  void registerForRestoration(
      HookRestorableProperty<Object?> property, String restorationId) {
    assert(
      property._restorationId == null ||
          (_debugDoingRestore && property._restorationId == restorationId),
      'Property is already registered under ${property._restorationId}.',
    );
    assert(
      _debugDoingRestore ||
          !_properties.keys
              .map((HookRestorableProperty<Object?> r) => r._restorationId)
              .contains(restorationId),
      '"$restorationId" is already registered to another property.',
    );

    final bool hasSerializedValue = bucket?.contains(restorationId) ?? false;
    final Object? initialValue = hasSerializedValue
        ? property.fromPrimitives(bucket!.read<Object>(restorationId))
        : property.createDefaultValue();

    if (!property.isRegistered) {
      property._register(restorationId, this);
      void listener() {
        if (bucket == null) {
          return;
        }
        _updateProperty(property);
      }

      property.addListener(listener);
      _properties[property] = listener;
    }
    assert(
      property._restorationId == restorationId &&
          property._owner == this &&
          _properties.containsKey(property),
    );

    property.initWithValue(initialValue);
    if (!hasSerializedValue && property.enabled && bucket != null) {
      _updateProperty(property);
    }
  }

  /// Whether [restoreState] will be called at the beginning of the next build
  /// phase.
  ///
  /// Returns true when new restoration data has been provided to the mixin, but
  /// the registered [HookRestorableProperty]s have not been restored to their new
  /// values (as described by the new restoration data) yet. The properties will
  /// get the values restored when [restoreState] is invoked at the beginning of
  /// the next build cycle.
  ///
  /// While this is true, [bucket] will also still return the old bucket with
  /// the old restoration data. It will update to the new bucket with the new
  /// data just before [restoreState] is invoked.
  bool get restorePending {
    if (_firstRestorePending) {
      return true;
    }
    if (restorationId == null) {
      return false;
    }
    final RestorationBucket? potentialNewParent =
        RestorationScope.maybeOf(context);
    return potentialNewParent != _currentParent &&
        (potentialNewParent?.isReplacing ?? false);
  }

  List<HookRestorableProperty<Object?>>?
      _debugPropertiesWaitingForReregistration;

  bool get _debugDoingRestore =>
      _debugPropertiesWaitingForReregistration != null;

  bool _firstRestorePending = true;
  RestorationBucket? _currentParent;

  @override
  void didUpdateHook(StateRestorationHook oldHook) {
    super.didUpdateHook(oldHook);

    didUpdateRestorationId();

    final RestorationBucket? oldBucket = _bucket;
    final bool needsRestore = restorePending;
    _currentParent = RestorationScope.maybeOf(context);

    final bool didReplaceBucket = _updateBucketIfNecessary(
        parent: _currentParent, restorePending: needsRestore);

    if (needsRestore) {
      _doRestore(oldBucket);
    }
    if (didReplaceBucket) {
      assert(oldBucket != _bucket);
      oldBucket?.dispose();
    }
  }

  /// Must be called when the value returned by [restorationId] changes.
  ///
  /// This method is automatically called from [didUpdateHook]. Therefore,
  /// manually invoking this method may be omitted when the change in
  /// [restorationId] was caused by an updated widget.
  @protected
  void didUpdateRestorationId() {
    // There's nothing to do if:
    //  - We don't have a parent to claim a bucket from.
    //  - Our current bucket already uses the provided restoration ID.
    //  - There's a restore pending, which means that didChangeDependencies
    //    will be called and we handle the rename there.
    if (_currentParent == null ||
        _bucket?.restorationId == restorationId ||
        restorePending) {
      return;
    }

    final RestorationBucket? oldBucket = _bucket;
    assert(!restorePending);
    final bool didReplaceBucket =
        _updateBucketIfNecessary(parent: _currentParent, restorePending: false);
    if (didReplaceBucket) {
      assert(oldBucket != _bucket);
      assert(_bucket == null || oldBucket == null);
      oldBucket?.dispose();
    }
  }

  void _doRestore(RestorationBucket? oldBucket) {
    assert(() {
      _debugPropertiesWaitingForReregistration = _properties.keys.toList();
      return true;
    }());

    hook.restoreState(oldBucket, _firstRestorePending, this);
    _firstRestorePending = false;

    assert(() {
      if (_debugPropertiesWaitingForReregistration!.isNotEmpty) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'Previously registered RestorableProperties must be re-registered in "restoreState".',
          ),
          ErrorDescription(
            'The RestorableProperties with the following IDs were not re-registered to $this when '
            '"restoreState" was called:',
          ),
          ..._debugPropertiesWaitingForReregistration!.map(
              (HookRestorableProperty<Object?> property) => ErrorDescription(
                    ' * ${property._restorationId}',
                  )),
        ]);
      }
      _debugPropertiesWaitingForReregistration = null;
      return true;
    }());
  }

  // Returns true if `bucket` has been replaced with a new bucket. It's the
  // responsibility of the caller to dispose the old bucket when this returns true.
  bool _updateBucketIfNecessary({
    required RestorationBucket? parent,
    required bool restorePending,
  }) {
    if (restorationId == null || parent == null) {
      final bool didReplace = _setNewBucketIfNecessary(
          newBucket: null, restorePending: restorePending);
      assert(_bucket == null);
      return didReplace;
    }
    assert(restorationId != null);
    if (restorePending || _bucket == null) {
      final RestorationBucket newBucket =
          parent.claimChild(restorationId!, debugOwner: this);
      final bool didReplace = _setNewBucketIfNecessary(
          newBucket: newBucket, restorePending: restorePending);
      assert(_bucket == newBucket);
      return didReplace;
    }
    // We have an existing bucket, make sure it has the right parent and id.
    assert(_bucket != null);
    assert(!restorePending);
    _bucket!.rename(restorationId!);
    parent.adoptChild(_bucket!);
    return false;
  }

  // Returns true if `bucket` has been replaced with a new bucket. It's the
  // responsibility of the caller to dispose the old bucket when this returns true.
  bool _setNewBucketIfNecessary(
      {required RestorationBucket? newBucket, required bool restorePending}) {
    if (newBucket == _bucket) {
      return false;
    }
    final RestorationBucket? oldBucket = _bucket;
    _bucket = newBucket;
    if (!restorePending) {
      // Write the current property values into the new bucket to persist them.
      if (_bucket != null) {
        _properties.keys.forEach(_updateProperty);
      }
      hook.didToggleBucket?.call(oldBucket);
    }
    return true;
  }

  void _updateProperty(HookRestorableProperty<Object?> property) {
    if (property.enabled) {
      _bucket?.write(property._restorationId!, property.toPrimitives());
    } else {
      _bucket?.remove<Object>(property._restorationId!);
    }
  }

  void _unregister(HookRestorableProperty<Object?> property) {
    final VoidCallback listener = _properties.remove(property)!;
    assert(() {
      _debugPropertiesWaitingForReregistration?.remove(property);
      return true;
    }());
    property.removeListener(listener);
    property._unregister();
  }

  @override
  void dispose() {
    _properties.forEach(
        (HookRestorableProperty<Object?> property, VoidCallback listener) {
      if (!property._disposed) {
        property.removeListener(listener);
      }
    });
    _bucket?.dispose();
    _bucket = null;
    super.dispose();
  }

  @override
  void initHook() {}

  @override
  HookRestoration build(BuildContext context) {
    final RestorationBucket? oldBucket = _bucket;
    final bool needsRestore = restorePending;
    _currentParent = RestorationScope.maybeOf(context);

    final bool didReplaceBucket = _updateBucketIfNecessary(
        parent: _currentParent, restorePending: needsRestore);

    if (needsRestore) {
      _doRestore(oldBucket);
    }
    if (didReplaceBucket) {
      assert(oldBucket != _bucket);
      oldBucket?.dispose();
    }

    return this;
  }

  /// Unregisters a [HookRestorableProperty] from state restoration.
  ///
  /// The value of the `property` is removed from the restoration data and it
  /// will not be restored if that data is used in a future state restoration.
  ///
  /// Calling this method is uncommon, but may be necessary if the data of a
  /// [HookRestorableProperty] is only relevant when the [State] object is in a
  /// certain state. When the data of a property is no longer necessary to
  /// restore the internal state of a [State] object, it may be removed from the
  /// restoration data by calling this method.
  @protected
  void unregisterFromRestoration(HookRestorableProperty<Object?> property) {
    assert(property._owner == this);
    _bucket?.remove<Object?>(property._restorationId!);
    _unregister(property);
  }
}

abstract class HookRestoration {

  /// Unregisters a [HookRestorableProperty] from state restoration.
  ///
  /// The value of the `property` is removed from the restoration data and it
  /// will not be restored if that data is used in a future state restoration.
  ///
  /// Calling this method is uncommon, but may be necessary if the data of a
  /// [HookRestorableProperty] is only relevant when the [State] object is in a
  /// certain state. When the data of a property is no longer necessary to
  /// restore the internal state of a [State] object, it may be removed from the
  /// restoration data by calling this method.
  void unregisterFromRestoration(HookRestorableProperty<Object?> property);

  /// Registers a [HookRestorableProperty] for state restoration.
  ///
  /// The registration associates the provided `property` with the provided
  /// `restorationId`. If restoration data is available for the provided
  /// `restorationId`, the property's value is restored to the value described
  /// by the restoration data. If no restoration data is available, the property
  /// will be initialized to a property-specific default value.
  ///
  /// Each property within a [State] object must be registered under a unique
  /// ID. Only registered properties will have their values restored during
  /// state restoration.
  ///
  /// Typically, this method is called from within [restoreState] to register
  /// all restorable properties of the owning [State] object. However, if a
  /// given [HookRestorableProperty] is only needed when certain conditions are met
  /// within the [State], [registerForRestoration] may also be called at any
  /// time after [restoreState] has been invoked for the first time.
  ///
  /// A property that has been registered outside of [restoreState] must be
  /// re-registered within [restoreState] the next time that method is called
  /// unless it has been unregistered with [unregisterFromRestoration].
  void registerForRestoration(
      HookRestorableProperty<Object?> property, String restorationId);

  /// Must be called when the value returned by [restorationId] changes.
  ///
  /// This method is automatically called from [didUpdateHook]. Therefore,
  /// manually invoking this method may be omitted when the change in
  /// [restorationId] was caused by an updated widget.
  void didUpdateRestorationId();


}
