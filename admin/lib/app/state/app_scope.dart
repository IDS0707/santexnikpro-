import 'package:flutter/widgets.dart';

import 'app_store.dart';

class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({super.key, required AppStore notifier, required super.child})
    : super(notifier: notifier);

  static AppStore read(BuildContext context) {
    final scope =
        context.getElementForInheritedWidgetOfExactType<AppScope>()?.widget
            as AppScope?;
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }

  static AppStore watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }
}
