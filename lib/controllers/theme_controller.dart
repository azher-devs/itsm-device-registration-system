// Theme mode state controller backed by Shared Preferences.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores and persists the selected application appearance mode.
class ThemeController extends ChangeNotifier {
  ThemeController({ThemeMode initialThemeMode = ThemeMode.light})
    : _themeMode = initialThemeMode;

  // Keep this key stable so appearance preference survives app updates.
  static const _preferenceKey = 'selected_theme_mode';

  /// Current theme mode used by MaterialApp.
  ThemeMode _themeMode;

  /// Exposes the active theme mode to the app shell and drawer.
  ThemeMode get themeMode => _themeMode;

  /// Convenience flag used by menu check marks.
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Loads the saved appearance before the first rendered app frame.
  static Future<ThemeController> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedMode = preferences.getString(_preferenceKey);
    final themeMode = savedMode == 'dark' ? ThemeMode.dark : ThemeMode.light;

    return ThemeController(initialThemeMode: themeMode);
  }

  /// Updates the app appearance and saves the selected mode for restart.
  Future<void> setThemeMode(ThemeMode themeMode) async {
    // Avoid unnecessary rebuilds when the selected mode is already active.
    if (_themeMode == themeMode) {
      return;
    }

    _themeMode = themeMode;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _preferenceKey,
      themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}
