import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:state_restoration_hook/src/state_restoration_hook.dart';

/// A [Hook] that creates a [RestorableProperty].
/// changes to the [RestorableProperty] will trigger a rebuild.
T useRestorableProperty<T extends HookRestorableProperty<Object?>>(T Function() create) {
  return use(HookRestorablePropertyHook<T>(create));
}

class HookRestorablePropertyHook<T extends HookRestorableProperty<Object?>>
    extends Hook<T> {
  final T Function() create;

  const HookRestorablePropertyHook(this.create);

  @override
  HookRestorablePropertyHookState<T> createState() {
    return HookRestorablePropertyHookState<T>();
  }
}

class HookRestorablePropertyHookState<T extends HookRestorableProperty<Object?>>
    extends HookState<T, HookRestorablePropertyHook<T>> {
  late T value;

  @override
  initHook() {
    value = hook.create();
    value.addListener(onUpdate);
  }

  void onUpdate() {
    setState(() {});
  }

  @override
  void dispose() {
    value.removeListener(onUpdate);
    value.dispose();
  }

  @override
  T build(BuildContext context) {
    return value;
  }
}
