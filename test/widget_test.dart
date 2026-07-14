// Widget tests for navigation, preferences, localization, and appearance.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itsm_device_registration_system/app/itsm_app.dart';
import 'package:itsm_device_registration_system/controllers/locale_controller.dart';
import 'package:itsm_device_registration_system/controllers/locale_controller_provider.dart';
import 'package:itsm_device_registration_system/controllers/theme_controller.dart';
import 'package:itsm_device_registration_system/controllers/theme_controller_provider.dart';
import 'package:itsm_device_registration_system/l10n/app_localizations.dart';
import 'package:itsm_device_registration_system/models/placeholder_data.dart';
import 'package:itsm_device_registration_system/views/home/home_screen.dart';
import 'package:itsm_device_registration_system/views/success/success_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  /// Builds the complete app inside the Riverpod root used in production.
  Widget buildApp() {
    return ProviderScope(
      child: ItsmApp(
        localeController: LocaleController(),
        themeController: ThemeController(),
      ),
    );
  }

  testWidgets('shows splash then navigates to username login', (tester) async {
    await tester.pumpWidget(buildApp());

    expect(find.text('INITIALIZING WORKSPACE...'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Email'), findsNothing);
  });

  testWidgets('login dismisses keyboard focus when tapping outside fields', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    await tester.showKeyboard(find.byType(TextField).first);
    await tester.pump();
    final editableText = tester.state<EditableTextState>(
      find.byType(EditableText).first,
    );
    expect(editableText.widget.focusNode.hasFocus, isTrue);

    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    expect(editableText.widget.focusNode.hasFocus, isFalse);
  });

  testWidgets('success summary displays brand instead of device name', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SuccessScreen(),
      ),
    );

    expect(find.text('Brand'), findsOneWidget);
    expect(find.text(PlaceholderDeviceData.brand), findsOneWidget);
    expect(find.text('Device Name'), findsNothing);
  });

  test('locale controller saves selected language', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = LocaleController();

    await controller.setLocale(const Locale('ar'));
    final restoredController = await LocaleController.load();

    expect(restoredController.locale.languageCode, 'ar');
  });

  test('theme controller saves selected appearance', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = ThemeController();

    await controller.setThemeMode(ThemeMode.dark);
    final restoredController = await ThemeController.load();

    expect(restoredController.themeMode, ThemeMode.dark);
  });

  testWidgets('language row opens dialog before changing language', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final localeController = LocaleController();
    final themeController = ThemeController();

    await tester.pumpWidget(
      LocaleControllerProvider(
        controller: localeController,
        child: ThemeControllerProvider(
          controller: themeController,
          child: AnimatedBuilder(
            animation: Listenable.merge([localeController, themeController]),
            builder: (context, _) => MaterialApp(
              locale: localeController.locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const HomeScreen(),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();

    expect(localeController.locale.languageCode, 'en');
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();

    expect(localeController.locale.languageCode, 'ar');
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('appearance section switches to dark mode', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final localeController = LocaleController();
    final themeController = ThemeController();

    await tester.pumpWidget(
      LocaleControllerProvider(
        controller: localeController,
        child: ThemeControllerProvider(
          controller: themeController,
          child: AnimatedBuilder(
            animation: Listenable.merge([localeController, themeController]),
            builder: (context, _) => MaterialApp(
              themeMode: themeController.themeMode,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const HomeScreen(),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark Mode'));
    await tester.pumpAndSettle();

    expect(themeController.themeMode, ThemeMode.dark);
  });
}
