// Widget tests for core navigation, registration, and localization behavior.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itsm_device_registration_system/app/itsm_app.dart';
import 'package:itsm_device_registration_system/controllers/locale_controller.dart';
import 'package:itsm_device_registration_system/controllers/locale_controller_provider.dart';
import 'package:itsm_device_registration_system/controllers/theme_controller.dart';
import 'package:itsm_device_registration_system/controllers/theme_controller_provider.dart';
import 'package:itsm_device_registration_system/core/constants/app_routes.dart';
import 'package:itsm_device_registration_system/l10n/app_localizations.dart';
import 'package:itsm_device_registration_system/models/placeholder_data.dart';
import 'package:itsm_device_registration_system/views/home/home_screen.dart';
import 'package:itsm_device_registration_system/views/registration/device_registration_screen.dart';
import 'package:itsm_device_registration_system/views/success/success_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Pumps a widget at a specific logical viewport size for responsive checks.
  Future<void> pumpResponsiveWidget(
    WidgetTester tester, {
    required Size size,
    required Widget child,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(child);
    await tester.pumpAndSettle();
  }

  // Verifies the initial timed navigation from Splash to Login.
  testWidgets('shows splash then navigates to login', (tester) async {
    await tester.pumpWidget(
      ItsmApp(
        localeController: LocaleController(),
        themeController: ThemeController(),
      ),
    );

    expect(find.text('INITIALIZING WORKSPACE...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Email'), findsNothing);
    expect(find.text('Login'), findsOneWidget);
  });

  // Ensures tapping outside an active login input dismisses keyboard focus.
  testWidgets('login dismisses keyboard focus when tapping outside fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      ItsmApp(
        localeController: LocaleController(),
        themeController: ThemeController(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    await tester.showKeyboard(find.byType(TextField).first);
    await tester.pump();

    final editableTextState = tester.state<EditableTextState>(
      find.byType(EditableText).first,
    );

    expect(editableTextState.widget.focusNode.hasFocus, isTrue);

    await tester.tapAt(const Offset(10, 10));
    await tester.pump();

    expect(editableTextState.widget.focusNode.hasFocus, isFalse);
  });

  // Ensures the base registration form includes the required serial field.
  testWidgets('registration screen includes serial number field', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DeviceRegistrationScreen(args: RegistrationScreenArgs()),
      ),
    );

    expect(find.text('Serial Number'), findsOneWidget);
    expect(find.text('Enter serial number'), findsOneWidget);
  });

  // Guards key screens against layout overflows on compact phones.
  testWidgets('key screens fit on a small phone viewport', (tester) async {
    await pumpResponsiveWidget(
      tester,
      size: const Size(320, 568),
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DeviceRegistrationScreen(args: RegistrationScreenArgs()),
      ),
    );

    expect(find.text('Device Registration'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // Guards key screens against over-stretched layouts on tablet-sized screens.
  testWidgets('key screens stay constrained on a tablet viewport', (
    tester,
  ) async {
    await pumpResponsiveWidget(
      tester,
      size: const Size(834, 1112),
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SuccessScreen(),
      ),
    );

    expect(find.text('Success!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // Ensures the after-scan form shows the scanned serial number.
  testWidgets('after scan registration includes populated serial number', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DeviceRegistrationScreen(
          args: RegistrationScreenArgs(
            tagNumber: PlaceholderDeviceData.tagNumber,
            serialNumber: PlaceholderDeviceData.serialNumber,
            showValidatedData: true,
          ),
        ),
      ),
    );

    expect(find.text('Serial Number'), findsOneWidget);
    expect(find.text(PlaceholderDeviceData.serialNumber), findsOneWidget);
    expect(find.text('Brand'), findsOneWidget);
    expect(find.text(PlaceholderDeviceData.brand), findsOneWidget);
    expect(find.byIcon(Icons.search), findsNWidgets(2));
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    expect(find.text('Scan Barcode'), findsOneWidget);
    expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
  });

  // Verifies the AppBar scanner action and bottom scan button use scanner navigation.
  testWidgets('registration scanner actions navigate to scanner route', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {AppRoutes.scanner: (_) => const Text('Scanner Route')},
        home: const DeviceRegistrationScreen(args: RegistrationScreenArgs()),
      ),
    );

    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();

    expect(find.text('Scanner Route'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {AppRoutes.scanner: (_) => const Text('Scanner Route')},
        home: const DeviceRegistrationScreen(args: RegistrationScreenArgs()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Scan Barcode'));
    await tester.tap(find.text('Scan Barcode'));
    await tester.pumpAndSettle();

    expect(find.text('Scanner Route'), findsOneWidget);
  });

  // Verifies scanned tags are accepted after lookup even when not hard-coded.
  testWidgets('scanned tag value fills form and can be submitted', (
    tester,
  ) async {
    const scannedTag = 'SQU-ASSET-98765';

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          AppRoutes.scanner: (_) => Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => Navigator.of(context).pop(scannedTag),
                child: const Text('Return Scan'),
              );
            },
          ),
          AppRoutes.success: (_) => const SuccessScreen(),
        },
        home: const DeviceRegistrationScreen(args: RegistrationScreenArgs()),
      ),
    );

    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Return Scan'));
    await tester.pumpAndSettle();

    expect(find.text(scannedTag), findsOneWidget);
    expect(find.text(PlaceholderDeviceData.brand), findsOneWidget);

    await tester.ensureVisible(find.byIcon(Icons.search).last);
    await tester.tap(find.byIcon(Icons.search).last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Submit'));
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid tag number.'), findsNothing);
    expect(find.text('Confirm Submission'), findsOneWidget);

    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('Submit')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Success!'), findsOneWidget);
  });

  // Ensures empty or incorrect placeholder data shows clear form errors.
  testWidgets('registration validates all visible input fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DeviceRegistrationScreen(args: RegistrationScreenArgs()),
      ),
    );

    await tester.ensureVisible(find.text('Submit'));
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid tag number.'), findsOneWidget);
    expect(find.text('Enter a valid serial number.'), findsOneWidget);
    expect(find.text('Enter a valid employee ID.'), findsOneWidget);
  });

  // Verifies the employee search action fills placeholder employee data.
  testWidgets('employee ID search fills placeholder employee details', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DeviceRegistrationScreen(args: RegistrationScreenArgs()),
      ),
    );

    await tester.tap(find.byIcon(Icons.search).last);
    await tester.pumpAndSettle();

    expect(find.text(PlaceholderEmployeeData.id), findsOneWidget);
    expect(find.text(PlaceholderEmployeeData.name), findsOneWidget);
  });

  // Verifies valid registration data requires confirmation before navigation.
  testWidgets('submit opens confirmation dialog before success navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {AppRoutes.success: (_) => const SuccessScreen()},
        home: const DeviceRegistrationScreen(
          args: RegistrationScreenArgs(
            tagNumber: PlaceholderDeviceData.tagNumber,
            serialNumber: PlaceholderDeviceData.serialNumber,
            employeeId: PlaceholderEmployeeData.id,
            showValidatedData: true,
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Submit'));
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Confirm Submission'), findsOneWidget);
    expect(
      find.text('Are you sure you want to submit the registration?'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
    expect(
      find.descendant(of: find.byType(Dialog), matching: find.text('Cancel')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(Dialog), matching: find.text('Submit')),
      findsOneWidget,
    );
    expect(find.text('Success!'), findsNothing);

    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('Cancel')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(find.text('Success!'), findsNothing);

    await tester.ensureVisible(find.text('Submit'));
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('Submit')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Success!'), findsOneWidget);
  });

  // Confirms the submit confirmation message is localized for Arabic.
  testWidgets('submit confirmation dialog supports Arabic text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {AppRoutes.success: (_) => const SuccessScreen()},
        home: const DeviceRegistrationScreen(
          args: RegistrationScreenArgs(
            tagNumber: PlaceholderDeviceData.tagNumber,
            serialNumber: PlaceholderDeviceData.serialNumber,
            employeeId: PlaceholderEmployeeData.id,
            showValidatedData: true,
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('إرسال'));
    await tester.tap(find.text('إرسال'));
    await tester.pumpAndSettle();

    expect(find.text('تأكيد الإرسال'), findsOneWidget);
    expect(find.text('هل أنت متأكد أنك تريد إرسال التسجيل؟'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(Dialog), matching: find.text('إلغاء')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(Dialog), matching: find.text('إرسال')),
      findsOneWidget,
    );
  });

  // Confirms the success summary uses the supervisor-facing Brand label.
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

  // Confirms language selection survives app restart through Shared Preferences.
  test('locale controller saves selected language', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = LocaleController();

    await controller.setLocale(const Locale('ar'));
    final restoredController = await LocaleController.load();

    expect(restoredController.locale.languageCode, 'ar');
  });

  // Confirms theme selection survives app restart through Shared Preferences.
  test('theme controller saves selected appearance', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = ThemeController();

    await controller.setThemeMode(ThemeMode.dark);
    final restoredController = await ThemeController.load();

    expect(restoredController.themeMode, ThemeMode.dark);
  });

  // Verifies the drawer opens a selector before applying a new language.
  testWidgets('language row opens dialog before changing language', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = LocaleController();
    final themeController = ThemeController();

    await tester.pumpWidget(
      LocaleControllerProvider(
        controller: controller,
        child: ThemeControllerProvider(
          controller: themeController,
          child: AnimatedBuilder(
            animation: Listenable.merge([controller, themeController]),
            builder: (context, _) {
              return MaterialApp(
                locale: controller.locale,
                themeMode: themeController.themeMode,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const HomeScreen(),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();

    expect(controller.locale.languageCode, 'en');
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('English'), findsWidgets);
    expect(find.text('EN'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('AR'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();

    expect(controller.locale.languageCode, 'ar');
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('اللغة'), findsOneWidget);
  });

  // Verifies selecting Dark Mode from the drawer updates the theme immediately.
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
            builder: (context, _) {
              return MaterialApp(
                themeMode: themeController.themeMode,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const HomeScreen(),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Light Mode'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.text('Dark Mode'));
    await tester.pumpAndSettle();

    expect(themeController.themeMode, ThemeMode.dark);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
