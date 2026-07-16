// Application entry point and startup preference restoration.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/itsm_app.dart';
import 'controllers/device_registration_controller.dart';
import 'controllers/locale_controller.dart';
import 'controllers/theme_controller.dart';
import 'repositories/demo_device_registration_repository.dart';

/// Starts the Flutter app with Fake API data until server access is available.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeController = await LocaleController.load();
  final themeController = await ThemeController.load();

  runApp(
    ProviderScope(
      overrides: [
        deviceRegistrationRepositoryProvider.overrideWithValue(
          DemoDeviceRegistrationRepository(),
        ),
      ],
      child: ItsmApp(
        localeController: localeController,
        themeController: themeController,
      ),
    ),
  );
}
