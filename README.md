# state_restoration_hook

Experimental hook for state restoration.

## Usage

Use the `useRestorableProperty` to create restorable state:

```dart
   final counter = useRestorableProperty(() => HookRestorableInt(0));
```

Register the state to be restored:

```dart

 useStateRestoration(
    restorationId: 'MyHomePage',
    restoreState: (oldBucket, initial, restore) {
        restore.registerForRestoration(counter, "counter");
     }
  );


```

Only after the state has been registered, the value can be accessed.

When the state is restored, the value of the HookRestorableProperties will be restored after the registerForRestoration call.

## HookRestorableProperty

The `HookRestorableProperty` is a generic class that can be used to create custom restorable properties.

The following `HookRestorableProperty` types are supported out of the box:

Primitive types:

  * `HookRestorableInt`
  * `HookRestorableDouble`
  * `HookRestorableNum`
  * `HookRestorableString`
  * `HookRestorableBool`

Nullable counterparts:

  * `HookRestorableIntN`
  * `HookRestorableDoubleN`
  * `HookRestorableNumN`
  * `HookRestorableStringN`
  * `HookRestorableBoolN`

Enums:

  * `HookRestorableEnum<T extends Enum>`
  * `HookRestorableEnumN<T extends Enum>` for nullable enums

DateTime:

  * `HookRestorableDateTime`
  * `HookRestorableDateTimeN` for nullable DateTimes

Flutter specific:

  * `HookRestorableTextEditingController` for restoring a `TextEditingController`, useful for forms


### Custom HookRestorableProperty

You can create your own `HookRestorableProperty` by extending the `HookRestorableProperty` class.

Consider subclassing `HookRestorableValue` if you want to restore a single value / data object.

If you want to restore a Listenable or ChangeNotifier, consider extending `HookRestorableListenable` or `HookRestorableChangeNotifier` respectively.


## Caveats

Please be aware the State Restoration is NOT meant to be used for storing large amounts of data and
not meant to be a replacement for persistence solutions like sqlite, Shared Preferences, Hive or Isar. It is meant to restore the state of the UI after
the app has been killed by the OS. You should only persist the minimal amount of data necessary (e.g. the ID of the currently displayed item, then 
re-fetch the data from the server or local database after state restoration).

If the user manually kills the app, the state restoration will not be able to restore the state.
If the app is updated, the state restoration will not be able to restore the state - This means
that you don't need to worry about migrations.

See documentation of the platform behavior for more details: 

- Android: https://developer.android.com/topic/libraries/architecture/saving-states
- iOS: https://developer.apple.com/documentation/uikit/uiscenedelegate/restoring_your_app_s_state

