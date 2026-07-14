// Unit tests for resilient device and employee API payload mapping.

import 'package:flutter_test/flutter_test.dart';
import 'package:itsm_device_registration_system/models/device.dart';
import 'package:itsm_device_registration_system/models/employee.dart';

void main() {
  test('empty or malformed contacts are treated as unassigned', () {
    final missing = Device.fromJson({
      'barcode': 'TAG-1',
      'serial_number': 'SN-1',
    });
    final malformed = Device.fromJson({
      'barcode': 'TAG-2',
      'serial_number': 'SN-2',
      'contacts_list': {'unexpected': true},
    });

    expect(missing.isAssigned, isFalse);
    expect(malformed.isAssigned, isFalse);
  });

  test('contacts list employee number marks a device assigned', () {
    final device = Device.fromJson({
      'tag_number': 'TAG-ASSIGNED',
      'serial_number': 'SN-ASSIGNED',
      'contacts_list': [
        {'employee_number': 'EMP-10045'},
      ],
    });

    expect(device.isAssigned, isTrue);
    expect(device.assignedEmployeeNumber, 'EMP-10045');
  });

  test('employee mapper accepts API field variants and missing optionals', () {
    final employee = Employee.fromJson({
      'employee_id': 'EMP-10045',
      'friendlyname': 'Ahmed Al Balushi',
      'department': 'IT',
    });

    expect(employee.isValid, isTrue);
    expect(employee.fullName, 'Ahmed Al Balushi');
    expect(employee.organization, 'IT');
    expect(employee.phone, isEmpty);
  });
}
