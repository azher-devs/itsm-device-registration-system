// Lightweight inherited provider for locale state access.

import 'package:flutter/widgets.dart';

import 'locale_controller.dart';

/// Makes the locale controller available to widgets without a package dependency.
class LocaleControllerProvider extends InheritedNotifier<LocaleController> {
  const LocaleControllerProvider({
    required LocaleController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// Reads the nearest locale controller from the widget tree.
  static LocaleController of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<LocaleControllerProvider>();
    assert(provider != null, 'LocaleControllerProvider not found in context');
    return provider!.notifier!;
  }
}
