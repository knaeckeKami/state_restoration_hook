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
    restoreState: (oldBucket, initial, registerForRestoration) {
       registerForRestoration(counter, "counter");
     }
  );


```

Only after the state has been registered, the value can be accessed.

When the app is restored, the state will be restored after the registerForRestoration call.

