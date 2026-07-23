// Unit tests for documented iTop response and domain model mapping.

import 'package:flutter_test/flutter_test.dart';
import 'package:itsm_device_registration_system/models/device.dart';
import 'package:itsm_device_registration_system/models/employee.dart';
import 'package:itsm_device_registration_system/models/itop_response.dart';

void main() {
  test('iTop response maps its common code message and objects envelope', () {
    final response = ItopResponse.fromJson({
      'code': 0,
      'message': 'Found: 1',
      'objects': {
        'PC::1603': {
          'code': 0,
          'message': '',
          'class': 'PC',
          'key': '1603',
          'fields': {'name': '2015020005'},
        },
      },
    });

    expect(response.isSuccess, isTrue);
    expect(response.message, 'Found: 1');
    expect(response.firstObject?.className, 'PC');
    expect(response.firstObject?.key, '1603');
  });

  test('Tag Number maps from name and never from asset_number', () {
    const object = ItopObject(
      code: 0,
      message: '',
      className: 'PC',
      key: '1603',
      fields: {
        'name': '2015020005',
        'asset_number': 'AST-104',
        'serialnumber': 'SN-FG9942',
        'brand_id_friendlyname': 'Fujitsu',
        'model_id_friendlyname': 'Esprimo',
        'status': 'production',
      },
    );

    final device = Device.fromItopObject(object);

    expect(device.tagNumber, '2015020005');
    expect(device.assetNumber, 'AST-104');
    expect(device.tagNumber, isNot(device.assetNumber));
  });

  test(
    'contacts_list presence determines assignment before profile lookup',
    () {
      const object = ItopObject(
        code: 0,
        message: '',
        className: 'PC',
        key: '1603',
        fields: {
          'name': '2015020005',
          'contacts_list': [
            {'contact_id': '10064'},
          ],
        },
      );

      final unresolved = Device.fromItopObject(object);
      final resolved = Device.fromItopObject(
        object,
        contacts: const [
          DeviceContact(contactId: '10064', employeeNumber: 'EMP8842'),
        ],
      );

      expect(unresolved.isAssigned, isTrue);
      expect(unresolved.assignedContactId, '10064');
      expect(resolved.isAssigned, isTrue);
      expect(resolved.assignedEmployeeNumber, 'EMP8842');
    },
  );

  test('Person fields map to employee profile', () {
    const object = ItopObject(
      code: 0,
      message: '',
      className: 'Person',
      key: '10064',
      fields: {
        'first_name': 'Olaa',
        'name': 'Al',
        'email': 'o.al@company.com',
        'org_id_friendlyname': 'IT Department',
        'phone': '+9681234567',
        'status': 'active',
        'function': 'Systems Analyst',
        'employee_number': 'EMP8842',
      },
    );

    final employee = Employee.fromItopObject(object);

    expect(employee.isValid, isTrue);
    expect(employee.itopKey, '10064');
    expect(employee.fullName, 'Olaa Al');
    expect(employee.organization, 'IT Department');
    expect(employee.employeeNumber, 'EMP8842');
  });

  test('missing and null optional fields map without throwing', () {
    final response = ItopResponse.fromJson({
      'code': 0,
      'message': 'Found: 1',
      'objects': {
        'PC::1603': {
          'code': 0,
          'message': null,
          'class': 'PC',
          'key': 1603,
          'fields': {
            'name': '2015020005',
            'serialnumber': null,
            'contacts_list': null,
          },
        },
      },
    });

    final device = Device.fromItopObject(response.firstObject!);

    expect(device.isValid, isTrue);
    expect(device.serialNumber, isEmpty);
    expect(device.contacts, isEmpty);
  });
}
