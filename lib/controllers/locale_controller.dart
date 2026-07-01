// Locale state controller backed by Shared Preferences.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores and persists the selected application language.
class LocaleController extends ChangeNotifier {
  LocaleController({Locale initialLocale = const Locale('en')})
    : _locale = initialLocale;

  // Keep the preference key stable so saved language survives app updates.
  static const _preferenceKey = 'selected_locale_code';

  /// Current locale used by MaterialApp.
  Locale _locale;

  /// Exposes the active locale to the app shell.
  Locale get locale => _locale;

  /// Convenience flag used by UI controls that show the current language.
  bool get isArabic => _locale.languageCode == 'ar';

  // Load the saved locale before the first frame to avoid a visible language jump.
  static Future<LocaleController> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedCode = preferences.getString(_preferenceKey);
    final locale = savedCode == 'ar' ? const Locale('ar') : const Locale('en');

    return LocaleController(initialLocale: locale);
  }

  /// Updates the active locale and saves it for the next app launch.
  Future<void> setLocale(Locale locale) async {
    // Avoid unnecessary rebuilds when the selected language is already active.
    if (_locale.languageCode == locale.languageCode) {
      return;
    }

    _locale = locale;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, locale.languageCode);
  }
}
