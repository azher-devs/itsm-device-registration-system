// Tests for the backend-free Device Registration demo entry point and data.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itsm_device_registration_system/app/itsm_app.dart';
import 'package:itsm_device_registration_system/controllers/device_registration_controller.dart';
import 'package:itsm_device_registration_system/controllers/locale_controller.dart';
import 'package:itsm_device_registration_system/controllers/theme_controller.dart';
import 'package:itsm_device_registration_system/l10n/app_localizations.dart';
import 'package:itsm_device_registration_system/main_demo.dart';
import 'package:itsm_device_registration_system/repositories/demo_device_registration_repository.dart';
import 'package:itsm_device_registration_system/repositories/device_registration_repository.dart';
import 'package:itsm_device_registration_system/views/registration/device_registration_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DemoDeviceRegistrationRepository repository;

  setUp(() {
    repository = DemoDeviceRegistrationRepository(
      delays: const DemoRegistrationDelays.none(),
    );
  });

  testWidgets('demo entry point injects DemoDeviceRegistrationRepository', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      DemoItsmApp(
        localeController: LocaleController(),
        themeController: ThemeController(),
        repository: repository,
      ),
    );

    final appContext = tester.element(find.byType(ItsmApp));
    final container = ProviderScope.containerOf(appContext);
    expect(
      container.read(deviceRegistrationRepositoryProvider),
      same(repository),
    );
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();
  });

  test('demo controller flow never creates the Dio provider', () async {
    final container = ProviderContainer(
      overrides: [
        deviceRegistrationRepositoryProvider.overrideWithValue(repository),
        registrationDioProvider.overrideWith(
          (ref) => throw StateError('Dio must not be created in Demo Mode.'),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(deviceRegistrationControllerProvider, (previous, next) {});

    final controller = container.read(
      deviceRegistrationControllerProvider.notifier,
    );
    expect(await controller.searchDevice('TAG-UNASSIGNED'), isTrue);
    expect(
      container.read(deviceRegistrationControllerProvider).device,
      isNotNull,
    );
  });

  test('demo repository returns all searchable device states', () async {
    final unassigned = await repository.getDevice('TAG-UNASSIGNED');
    final assigned = await repository.getDevice('TAG-ASSIGNED');
    final second = await repository.getDevice('TAG-SECOND');

    expect(unassigned.isAssigned, isFalse);
    expect(unassigned.serialNumber, 'SN-UNASSIGNED');
    expect(assigned.isAssigned, isTrue);
    expect(assigned.assignedEmployeeNumber, 'EMP-10045');
    expect(second.brand, 'Lenovo');
  });

  test('demo repository returns EMP-10045 employee details', () async {
    final employee = await repository.getEmployee('EMP-10045');

    expect(employee.fullName, 'Ahmed Al Balushi');
    expect(employee.email, 'ahmed@example.com');
    expect(employee.organization, 'Information Technology');
  });

  test('demo assignment state persists until repository restart', () async {
    final device = await repository.getDevice('TAG-UNASSIGNED');
    final employee = await repository.getEmployee('EMP-10045');
    await repository.addAssignment(device: device, employee: employee);
    expect((await repository.getDevice('TAG-UNASSIGNED')).isAssigned, isTrue);

    await repository.removeAssignment(
      device: await repository.getDevice('TAG-UNASSIGNED'),
      employee: employee,
    );
    expect((await repository.getDevice('TAG-UNASSIGNED')).isAssigned, isFalse);
  });

  test('demo failure devices preserve their assignment states', () async {
    final employee = await repository.getEmployee('EMP-10045');
    await expectLater(
      repository.addAssignment(
        device: await repository.getDevice('TAG-ADD-FAIL'),
        employee: employee,
      ),
      throwsA(
        isA<RegistrationDataException>().having(
          (error) => error.message,
          'message',
          DemoDeviceRegistrationRepository.addFailureMessage,
        ),
      ),
    );
    await expectLater(
      repository.removeAssignment(
        device: await repository.getDevice('TAG-REMOVE-FAIL'),
        employee: employee,
      ),
      throwsA(
        isA<RegistrationDataException>().having(
          (error) => error.message,
          'message',
          DemoDeviceRegistrationRepository.removeFailureMessage,
        ),
      ),
    );

    expect((await repository.getDevice('TAG-ADD-FAIL')).isAssigned, isFalse);
    expect((await repository.getDevice('TAG-REMOVE-FAIL')).isAssigned, isTrue);
  });

  test('demo rename changes the searchable iTop name field', () async {
    final device = await repository.getDevice('TAG-SECOND');

    expect(
      await repository.renameDevice(device: device, newName: 'TAG-RENAMED'),
      'Object updated',
    );
    expect(
      (await repository.getDevice('TAG-RENAMED')).tagNumber,
      'TAG-RENAMED',
    );
    await expectLater(
      repository.getDevice('TAG-SECOND'),
      throwsA(isA<RegistrationDataException>()),
    );
  });

  test(
    'controller exposes rename through a guarded Riverpod state flow',
    () async {
      final controller = DeviceRegistrationController(repository);
      addTearDown(controller.dispose);

      expect(await controller.searchDevice('TAG-SECOND'), isTrue);
      expect(await controller.renameDevice('TAG-RENAMED'), isTrue);
      expect(controller.state.operation, RegistrationOperation.idle);
      expect(controller.state.device?.tagNumber, 'TAG-RENAMED');
    },
  );

  test('demo not-found and timeout scenarios return handled errors', () async {
    await expectLater(
      repository.getDevice('TAG-NOT-FOUND'),
      throwsA(isA<RegistrationDataException>()),
    );
    await expectLater(
      repository.getEmployee('EMP-NOT-FOUND'),
      throwsA(isA<RegistrationDataException>()),
    );
    await expectLater(
      repository.getDevice('TAG-TIMEOUT'),
      throwsA(isA<RegistrationTimeoutException>()),
    );
  });

  group('demo screen errors', () {
    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deviceRegistrationRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: DeviceRegistrationScreen(args: RegistrationScreenArgs()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder field(String key) => find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byType(TextField),
    );

    Future<void> searchDevice(WidgetTester tester, String tag) async {
      await tester.enterText(field('tag_number_field'), tag);
      await tester.tap(find.byIcon(Icons.search).first);
      await tester.pumpAndSettle();
    }

    testWidgets('TAG-NOT-FOUND clears stale state and displays an error', (
      tester,
    ) async {
      await pumpScreen(tester);
      await searchDevice(tester, 'TAG-UNASSIGNED');
      expect(find.text('SN-UNASSIGNED'), findsWidgets);

      await searchDevice(tester, 'TAG-NOT-FOUND');
      expect(
        find.text(DemoDeviceRegistrationRepository.notFoundMessage),
        findsOneWidget,
      );
      expect(find.text('SN-UNASSIGNED'), findsNothing);
      expect(find.byKey(const Key('add_assignment_button')), findsNothing);
      expect(find.byKey(const Key('remove_assignment_button')), findsNothing);
    });

    testWidgets('EMP-NOT-FOUND keeps device and hides Add', (tester) async {
      await pumpScreen(tester);
      await searchDevice(tester, 'TAG-UNASSIGNED');
      await tester.ensureVisible(field('employee_id_field'));
      await tester.enterText(field('employee_id_field'), 'EMP-NOT-FOUND');
      await tester.tap(
        find.descendant(
          of: find.byKey(const Key('employee_id_field')),
          matching: find.byIcon(Icons.search),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(DemoDeviceRegistrationRepository.notFoundMessage),
        findsOneWidget,
      );
      expect(find.text('SN-UNASSIGNED'), findsWidgets);
      expect(find.byKey(const Key('add_assignment_button')), findsNothing);
    });

    testWidgets('TAG-TIMEOUT displays the Fake API timeout error', (
      tester,
    ) async {
      await pumpScreen(tester);
      await searchDevice(tester, 'TAG-TIMEOUT');

      expect(
        find.text(DemoDeviceRegistrationRepository.timeoutMessage),
        findsOneWidget,
      );
      expect(find.byKey(const Key('add_assignment_button')), findsNothing);
      expect(find.byKey(const Key('remove_assignment_button')), findsNothing);
    });
  });
}
