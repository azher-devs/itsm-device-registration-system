// Root application shell for theme, routes, and localization.

import 'package:flutter/material.dart';

import '../controllers/locale_controller.dart';
import '../controllers/locale_controller_provider.dart';
import '../controllers/theme_controller.dart';
import '../controllers/theme_controller_provider.dart';
import '../core/constants/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../views/auth/login_screen.dart';
import '../views/home/home_screen.dart';
import '../views/registration/device_registration_screen.dart';
import '../views/scanner/barcode_scanner_screen.dart';
import '../views/splash/splash_screen.dart';
import '../views/success/success_screen.dart';

/// Root widget that wires theme, routing, and localization for the app.
class ItsmApp extends StatelessWidget {
  const ItsmApp({
    required this.localeController,
    required this.themeController,
    super.key,
  });

  /// Holds the active locale and notifies the app when it changes.
  final LocaleController localeController;

  /// Holds the active theme mode and notifies the app when it changes.
  final ThemeController themeController;

  /// Builds the Material app and rebuilds it when the selected locale changes.
  @override
  Widget build(BuildContext context) {
    return LocaleControllerProvider(
      controller: localeController,
      child: ThemeControllerProvider(
        controller: themeController,
        child: AnimatedBuilder(
          animation: Listenable.merge([localeController, themeController]),
          builder: (context, _) {
            // Rebuild MaterialApp when locale or appearance changes.
            return MaterialApp(
              title: 'ITSM Device Registration',
              onGenerateTitle: (context) =>
                  AppLocalizations.of(context).appTitle,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeController.themeMode,
              locale: localeController.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              initialRoute: AppRoutes.splash,
              onGenerateRoute: (settings) {
                // Centralized routing keeps navigation simple until a router package is needed.
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) {
                    switch (settings.name) {
                      case AppRoutes.login:
                        return const LoginScreen();
                      case AppRoutes.home:
                        return const HomeScreen();
                      case AppRoutes.registration:
                        // Registration can be opened empty or prefilled after scanning.
                        return DeviceRegistrationScreen(
                          args: settings.arguments is RegistrationScreenArgs
                              ? settings.arguments! as RegistrationScreenArgs
                              : const RegistrationScreenArgs(),
                        );
                      case AppRoutes.scanner:
                        return const BarcodeScannerScreen();
                      case AppRoutes.success:
                        return const SuccessScreen();
                      case AppRoutes.splash:
                      default:
                        return const SplashScreen();
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
