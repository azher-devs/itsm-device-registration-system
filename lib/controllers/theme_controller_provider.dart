// Lightweight inherited provider for theme mode state access.

import 'package:flutter/widgets.dart';

import 'theme_controller.dart';

/// Makes the theme controller available to widgets without a package dependency.
class ThemeControllerProvider extends InheritedNotifier<ThemeController> {
  const ThemeControllerProvider({
    required ThemeController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// Reads the nearest theme controller from the widget tree.
  static ThemeController of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ThemeControllerProvider>();
    assert(provider != null, 'ThemeControllerProvider not found in context');
    return provider!.notifier!;
  }
}
