// Standalone entry point for backend-free Device Registration UI review.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/itsm_app.dart';
import 'controllers/device_registration_controller.dart';
import 'controllers/locale_controller.dart';
import 'controllers/theme_controller.dart';
import 'repositories/demo_device_registration_repository.dart';

/// Starts the normal application with an in-memory registration repository.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeController = await LocaleController.load();
  final themeController = await ThemeController.load();

  runApp(
    DemoItsmApp(
      localeController: localeController,
      themeController: themeController,
    ),
  );
}

/// Injects demo data while reusing production routes, screens, and themes.
class DemoItsmApp extends StatelessWidget {
  DemoItsmApp({
    required this.localeController,
    required this.themeController,
    super.key,
    DemoDeviceRegistrationRepository? repository,
  }) : repository = repository ?? DemoDeviceRegistrationRepository();

  final LocaleController localeController;
  final ThemeController themeController;
  final DemoDeviceRegistrationRepository repository;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        demoDioLoggingEnabledProvider.overrideWithValue(true),
        deviceRegistrationRepositoryProvider.overrideWithValue(repository),
      ],
      child: ItsmApp(
        localeController: localeController,
        themeController: themeController,
      ),
    );
  }
}
