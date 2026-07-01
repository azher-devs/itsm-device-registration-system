// Application entry point and startup preference restoration.

import 'package:flutter/material.dart';

import 'app/itsm_app.dart';
import 'controllers/locale_controller.dart';
import 'controllers/theme_controller.dart';

/// Starts the Flutter app after restoring persisted user preferences.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeController = await LocaleController.load();
  final themeController = await ThemeController.load();

  runApp(
    ItsmApp(
      localeController: localeController,
      themeController: themeController,
    ),
  );
}
