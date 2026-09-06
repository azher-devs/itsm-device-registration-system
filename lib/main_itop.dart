// Authorized real-server entry point using the dedicated Dart configuration.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/itsm_app.dart';
import 'config/itop_config.dart';
import 'controllers/device_registration_controller.dart';
import 'controllers/locale_controller.dart';
import 'controllers/theme_controller.dart';

/// Starts the application with the configured Dio-backed repository provider.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeController = await LocaleController.load();
  final themeController = await ThemeController.load();

  runApp(
    ProviderScope(
      overrides: [
        itopConfigurationProvider.overrideWithValue(ITopConfig.configuration),
      ],
      child: ItsmApp(
        localeController: localeController,
        themeController: themeController,
      ),
    ),
  );
}
