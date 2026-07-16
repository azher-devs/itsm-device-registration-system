// Widget and controller tests for device assignment actions.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itsm_device_registration_system/controllers/device_registration_controller.dart';
import 'package:itsm_device_registration_system/core/constants/app_routes.dart';
import 'package:itsm_device_registration_system/l10n/app_localizations.dart';
import 'package:itsm_device_registration_system/models/device.dart';
import 'package:itsm_device_registration_system/models/employee.dart';
import 'package:itsm_device_registration_system/repositories/device_registration_repository.dart';
import 'package:itsm_device_registration_system/views/registration/device_registration_screen.dart';

const employee = Employee(
  itopKey: '10064',
  employeeNumber: 'EMP-10045',
  fullName: 'Ahmed Al Balushi',
  email: 'ahmed@example.com',
  organization: 'Information Technology',
  phone: '+968 1234 5678',
  status: 'Active',
  jobTitle: 'Support Engineer',
);

const unassignedDevice = Device(
  itopKey: '1603',
  itopClass: 'PC',
  tagNumber: 'TAG-UNASSIGNED',
  brand: 'Dell',
  deviceType: 'Laptop',
  serialNumber: 'SN-UNASSIGNED',
  status: 'In Service',
  contacts: [],
);

const assignedDevice = Device(
  itopKey: '1604',
  itopClass: 'PC',
  tagNumber: 'TAG-ASSIGNED',
  brand: 'HP',
  deviceType: 'Desktop',
  serialNumber: 'SN-ASSIGNED',
  status: 'In Service',
  contacts: [DeviceContact(contactId: '10064', employeeNumber: 'EMP-10045')],
);

const secondDevice = Device(
  itopKey: '1605',
  itopClass: 'Tablet',
  tagNumber: 'TAG-SECOND',
  brand: 'Lenovo',
  deviceType: 'Tablet',
  serialNumber: 'SN-SECOND',
  status: 'Available',
  contacts: [],
);

/// Predictable repository used to verify requests without network access.
class FakeRegistrationRepository implements DeviceRegistrationRepository {
  final devices = <String, Device>{
    unassignedDevice.tagNumber: unassignedDevice,
    assignedDevice.tagNumber: assignedDevice,
    secondDevice.tagNumber: secondDevice,
  };
  final employees = <String, Employee>{employee.employeeNumber: employee};

  int addCalls = 0;
  int removeCalls = 0;
  bool failAdd = false;
  bool failRemove = false;

  @override
  Future<Device> getDevice(String barcode) async {
    final device = devices[barcode];
    if (device == null) {
      throw const RegistrationDataException('Device not found');
    }
    return device;
  }

  @override
  Future<Employee> getEmployee(String employeeNumber) async {
    final result = employees[employeeNumber];
    if (result == null) {
      throw const RegistrationDataException('Employee not found');
    }
    return result;
  }

  @override
  Future<String> addAssignment({
    required Device device,
    required Employee employee,
  }) async {
    addCalls++;
    if (failAdd) {
      throw const RegistrationDataException('API add failed');
    }
    return 'Object created';
  }

  @override
  Future<String> removeAssignment({
    required Device device,
    required Employee employee,
  }) async {
    removeCalls++;
    if (failRemove) {
      throw const RegistrationDataException('API remove failed');
    }
    return 'Objects deleted';
  }

  @override
  Future<String> renameDevice({
    required Device device,
    required String newName,
  }) async {
    return 'Object updated';
  }
}

void main() {
  late FakeRegistrationRepository repository;

  setUp(() {
    repository = FakeRegistrationRepository();
  });

  /// Builds registration with an injectable repository and optional scanner.
  Future<void> pumpRegistration(
    WidgetTester tester, {
    String? initialTag,
    String? scannedTag,
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          deviceRegistrationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            if (scannedTag != null)
              AppRoutes.scanner: (_) => Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(scannedTag),
                  child: const Text('Return Scan'),
                ),
              ),
          },
          home: DeviceRegistrationScreen(
            args: RegistrationScreenArgs(tagNumber: initialTag),
          ),
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

  Future<void> searchEmployee(WidgetTester tester) async {
    await tester.ensureVisible(field('employee_id_field'));
    await tester.pumpAndSettle();
    await tester.enterText(field('employee_id_field'), employee.employeeNumber);
    final employeeSearch = find.descendant(
      of: find.byKey(const Key('employee_id_field')),
      matching: find.byIcon(Icons.search),
    );
    await tester.tap(employeeSearch);
    await tester.pumpAndSettle();
  }

  testWidgets('no device selected shows no assignment action', (tester) async {
    await pumpRegistration(tester);

    expect(find.byKey(const Key('add_assignment_button')), findsNothing);
    expect(find.byKey(const Key('remove_assignment_button')), findsNothing);
  });

  testWidgets('unassigned device without employee shows no Add button', (
    tester,
  ) async {
    await pumpRegistration(tester);
    await searchDevice(tester, unassignedDevice.tagNumber);

    expect(find.text(unassignedDevice.serialNumber), findsWidgets);
    expect(find.byKey(const Key('add_assignment_button')), findsNothing);
  });

  testWidgets('valid employee shows Add and serial number is read-only', (
    tester,
  ) async {
    await pumpRegistration(tester);
    await searchDevice(tester, unassignedDevice.tagNumber);
    await searchEmployee(tester);

    expect(find.byKey(const Key('add_assignment_button')), findsOneWidget);
    expect(
      tester.widget<TextField>(field('serial_number_field')).readOnly,
      isTrue,
    );
    expect(find.text('Submit'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('Assign Device dialog shows identifiers and No cancels', (
    tester,
  ) async {
    await pumpRegistration(tester);
    await searchDevice(tester, unassignedDevice.tagNumber);
    await searchEmployee(tester);

    await tester.ensureVisible(find.byKey(const Key('add_assignment_button')));
    await tester.tap(find.byKey(const Key('add_assignment_button')));
    await tester.pumpAndSettle();
    final dialog = find.byKey(const Key('assignment_confirmation_dialog'));
    expect(find.text('Assign Device'), findsOneWidget);
    expect(
      find.text('Are you sure you want to assign this device?'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: dialog,
        matching: find.text(unassignedDevice.tagNumber),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text(employee.employeeNumber)),
      findsOneWidget,
    );
    expect(find.text('Yes'), findsOneWidget);

    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(repository.addCalls, 0);
    expect(
      find.text('The device has been assigned successfully.'),
      findsNothing,
    );
  });

  testWidgets('confirmed Add sends POST action and changes to Remove', (
    tester,
  ) async {
    await pumpRegistration(tester);
    await searchDevice(tester, unassignedDevice.tagNumber);
    await searchEmployee(tester);

    await tester.ensureVisible(find.byKey(const Key('add_assignment_button')));
    await tester.tap(find.byKey(const Key('add_assignment_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_assignment_action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.addCalls, 1);
    expect(find.byKey(const Key('remove_assignment_button')), findsOneWidget);
    expect(find.text(employee.fullName), findsOneWidget);
    expect(
      find.text('The device has been assigned successfully.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(
      find.text('The device has been assigned successfully.'),
      findsNothing,
    );
  });

  testWidgets('failed Add preserves employee and unassigned state', (
    tester,
  ) async {
    repository.failAdd = true;
    await pumpRegistration(tester);
    await searchDevice(tester, unassignedDevice.tagNumber);
    await searchEmployee(tester);

    await tester.ensureVisible(find.byKey(const Key('add_assignment_button')));
    await tester.tap(find.byKey(const Key('add_assignment_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_assignment_action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add_assignment_button')), findsOneWidget);
    expect(find.byKey(const Key('remove_assignment_button')), findsNothing);
    expect(find.text(employee.fullName), findsOneWidget);
    expect(find.text('API add failed'), findsOneWidget);
    expect(
      find.text('The device has been assigned successfully.'),
      findsNothing,
    );
  });

  testWidgets('assigned device loads employee and shows only Remove', (
    tester,
  ) async {
    await pumpRegistration(tester, initialTag: assignedDevice.tagNumber);

    expect(find.byKey(const Key('remove_assignment_button')), findsOneWidget);
    expect(find.byKey(const Key('add_assignment_button')), findsNothing);
    expect(find.text(employee.fullName), findsOneWidget);
    expect(
      tester.widget<TextField>(field('employee_id_field')).readOnly,
      isTrue,
    );
  });

  testWidgets('Remove Assignment dialog shows identifiers and No cancels', (
    tester,
  ) async {
    await pumpRegistration(tester, initialTag: assignedDevice.tagNumber);
    await tester.ensureVisible(
      find.byKey(const Key('remove_assignment_button')),
    );
    await tester.tap(find.byKey(const Key('remove_assignment_button')));
    await tester.pumpAndSettle();

    expect(find.text('Remove Assignment'), findsOneWidget);
    expect(
      find.text(
        'Are you sure you want to remove this employee from this device?',
      ),
      findsOneWidget,
    );
    final dialog = find.byKey(const Key('assignment_confirmation_dialog'));
    expect(
      find.descendant(
        of: dialog,
        matching: find.text(assignedDevice.tagNumber),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: dialog, matching: find.text(employee.employeeNumber)),
      findsOneWidget,
    );
    expect(find.text('Yes'), findsOneWidget);

    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(repository.removeCalls, 0);
    expect(
      find.text('Employee removed from the device successfully.'),
      findsNothing,
    );
  });

  testWidgets('confirmed Remove clears employee but preserves device', (
    tester,
  ) async {
    await pumpRegistration(tester, initialTag: assignedDevice.tagNumber);
    await tester.ensureVisible(
      find.byKey(const Key('remove_assignment_button')),
    );
    await tester.tap(find.byKey(const Key('remove_assignment_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_assignment_action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.removeCalls, 1);
    expect(find.byKey(const Key('remove_assignment_button')), findsNothing);
    expect(find.text(employee.fullName), findsNothing);
    expect(find.text(assignedDevice.tagNumber), findsWidgets);
    expect(find.text(assignedDevice.serialNumber), findsWidgets);
    expect(
      tester.widget<TextField>(field('employee_id_field')).controller?.text,
      isEmpty,
    );
    expect(
      find.text('Employee removed from the device successfully.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(
      find.text('Employee removed from the device successfully.'),
      findsNothing,
    );
  });

  testWidgets('failed Remove preserves assigned employee and action', (
    tester,
  ) async {
    repository.failRemove = true;
    await pumpRegistration(tester, initialTag: assignedDevice.tagNumber);
    await tester.ensureVisible(
      find.byKey(const Key('remove_assignment_button')),
    );
    await tester.tap(find.byKey(const Key('remove_assignment_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_assignment_action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('remove_assignment_button')), findsOneWidget);
    expect(find.text(employee.fullName), findsOneWidget);
    expect(find.text('API remove failed'), findsOneWidget);
    expect(
      find.text('Employee removed from the device successfully.'),
      findsNothing,
    );
  });

  testWidgets('scanning another device clears stale employee state', (
    tester,
  ) async {
    await pumpRegistration(
      tester,
      initialTag: assignedDevice.tagNumber,
      scannedTag: secondDevice.tagNumber,
    );
    expect(find.text(employee.fullName), findsOneWidget);

    await tester.ensureVisible(find.text('Scan Barcode'));
    await tester.tap(find.text('Scan Barcode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Return Scan'));
    await tester.pumpAndSettle();

    expect(find.text(secondDevice.tagNumber), findsWidgets);
    expect(find.text(employee.fullName), findsNothing);
    expect(find.byKey(const Key('remove_assignment_button')), findsNothing);
  });

  testWidgets('Arabic Add dialog uses localized assignment copy', (
    tester,
  ) async {
    await pumpRegistration(tester, locale: const Locale('ar'));
    await searchDevice(tester, unassignedDevice.tagNumber);
    await searchEmployee(tester);

    await tester.ensureVisible(find.byKey(const Key('add_assignment_button')));
    await tester.tap(find.byKey(const Key('add_assignment_button')));
    await tester.pumpAndSettle();

    expect(find.text('تخصيص الجهاز'), findsOneWidget);
    expect(
      find.text('هل أنت متأكد أنك تريد تخصيص هذا الجهاز؟'),
      findsOneWidget,
    );
    expect(find.text('لا'), findsOneWidget);
    expect(find.text('نعم'), findsOneWidget);
  });
}
