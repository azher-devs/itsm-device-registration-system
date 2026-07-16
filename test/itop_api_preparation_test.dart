// Contract tests for documented iTop instructions without network access.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itsm_device_registration_system/core/config/itop_configuration.dart';
import 'package:itsm_device_registration_system/models/device.dart';
import 'package:itsm_device_registration_system/models/employee.dart';
import 'package:itsm_device_registration_system/models/itop_response.dart';
import 'package:itsm_device_registration_system/repositories/device_registration_repository.dart';
import 'package:itsm_device_registration_system/services/device_registration_api_service.dart';
import 'package:itsm_device_registration_system/services/itop_api_client.dart';

/// Captures JSON instructions and returns queued iTop envelopes.
class FakeItopApiClient extends ItopApiClient {
  FakeItopApiClient(this.responses)
    : super(dio: Dio(), config: ItopConfiguration.placeholder);

  final List<ItopResponse> responses;
  final List<Map<String, dynamic>> instructions = [];

  @override
  Future<ItopResponse> execute(Map<String, dynamic> instruction) async {
    instructions.add(instruction);
    return responses.removeAt(0);
  }
}

void main() {
  test(
    'device search uses PhysicalDevice name and documented fields',
    () async {
      final client = FakeItopApiClient([_response(message: 'Found: 0')]);
      final service = DeviceRegistrationApiService(client);

      await service.getDeviceByName('2015020005');

      expect(client.instructions.single, {
        'operation': 'core/get',
        'class': 'PhysicalDevice',
        'key': "SELECT PhysicalDevice WHERE name = '2015020005'",
        'output_fields':
            'name, serialnumber, asset_number, status, '
            'brand_id_friendlyname, model_id_friendlyname, description, '
            'contacts_list',
        'limit': 100,
        'page': 1,
      });
    },
  );

  test(
    'repository resolves contacts_list through a second Person request',
    () async {
      final client = FakeItopApiClient([
        _response(
          message: 'Found: 1',
          object: const ItopObject(
            code: 0,
            message: '',
            className: 'PC',
            key: '1603',
            fields: {
              'name': '2015020005',
              'serialnumber': 'SN-FG9942',
              'contacts_list': [
                {'contact_id': '10064'},
              ],
            },
          ),
        ),
        _response(
          message: 'Found: 1',
          object: const ItopObject(
            code: 0,
            message: '',
            className: 'Person',
            key: '10064',
            fields: {
              'first_name': 'Olaa',
              'name': 'Al',
              'employee_number': 'EMP8842',
            },
          ),
        ),
      ]);
      final repository = DioDeviceRegistrationRepository(
        DeviceRegistrationApiService(client),
      );

      final device = await repository.getDevice('2015020005');

      expect(device.tagNumber, '2015020005');
      expect(device.assignedEmployeeNumber, 'EMP8842');
      expect(client.instructions[1]['class'], 'Person');
      expect(client.instructions[1]['key'], '10064');
    },
  );

  test('employee search uses Person employee_number OQL', () async {
    final client = FakeItopApiClient([_response(message: 'Found: 0')]);
    final service = DeviceRegistrationApiService(client);

    await service.getEmployeeByNumber('EMP8842');

    expect(client.instructions.single['operation'], 'core/get');
    expect(client.instructions.single['class'], 'Person');
    expect(
      client.instructions.single['key'],
      "SELECT Person WHERE employee_number = 'EMP8842'",
    );
  });

  test(
    'assignment and rename operations match documented iTop payloads',
    () async {
      final client = FakeItopApiClient([
        _response(message: 'Object created'),
        _response(message: 'Objects deleted'),
        _response(message: 'Object updated'),
      ]);
      final service = DeviceRegistrationApiService(client);
      const device = Device(
        itopKey: '1603',
        itopClass: 'PC',
        tagNumber: '2015020005',
        brand: 'Fujitsu',
        deviceType: 'PC',
        serialNumber: 'SN-FG9942',
        status: 'production',
        contacts: [],
      );
      const employee = Employee(
        itopKey: '10064',
        employeeNumber: 'EMP8842',
        fullName: 'Olaa Al',
        email: '',
        organization: '',
        phone: '',
        status: '',
        jobTitle: '',
      );

      await service.addAssignment(device: device, employee: employee);
      await service.removeAssignment(device: device, employee: employee);
      await service.renameDevice(device: device, newName: 'IT-LAPTOP-05');

      expect(client.instructions[0], {
        'operation': 'core/create',
        'class': 'lnkContactToFunctionalCI',
        'comment': 'Linked via Mobile App Portal',
        'fields': {'functionalci_id': 1603, 'contact_id': 10064},
      });
      expect(client.instructions[1]['operation'], 'core/delete');
      expect(client.instructions[1]['class'], 'lnkContactToFunctionalCI');
      expect(
        client.instructions[1]['key'],
        'SELECT lnkContactToFunctionalCI WHERE functionalci_id = 1603 '
        'AND contact_id = 10064',
      );
      expect(client.instructions[2], {
        'operation': 'core/update',
        'class': 'PC',
        'key': 1603,
        'comment': 'Name tag modified via Mobile App Portal',
        'fields': {'name': 'IT-LAPTOP-05'},
      });
    },
  );

  test('repository preserves a failed iTop response message exactly', () async {
    final client = FakeItopApiClient([
      _response(code: 100, message: 'Permission denied by iTop'),
    ]);
    final repository = DioDeviceRegistrationRepository(
      DeviceRegistrationApiService(client),
    );

    await expectLater(
      repository.getEmployee('EMP8842'),
      throwsA(
        isA<RegistrationDataException>().having(
          (error) => error.message,
          'message',
          'Permission denied by iTop',
        ),
      ),
    );
  });

  test('repository preserves an object-level error message exactly', () async {
    final client = FakeItopApiClient([
      _response(
        message: 'Operation completed with errors',
        object: const ItopObject(
          code: 104,
          message: 'Assignment link already exists',
          className: 'lnkContactToFunctionalCI',
          key: '',
          fields: {},
        ),
      ),
    ]);
    final repository = DioDeviceRegistrationRepository(
      DeviceRegistrationApiService(client),
    );
    const device = Device(
      itopKey: '1603',
      itopClass: 'PC',
      tagNumber: '2015020005',
      brand: 'Fujitsu',
      deviceType: 'PC',
      serialNumber: 'SN-FG9942',
      status: 'production',
      contacts: [],
    );
    const employee = Employee(
      itopKey: '10064',
      employeeNumber: 'EMP8842',
      fullName: 'Olaa Al',
      email: '',
      organization: '',
      phone: '',
      status: '',
      jobTitle: '',
    );

    await expectLater(
      repository.addAssignment(device: device, employee: employee),
      throwsA(
        isA<RegistrationDataException>().having(
          (error) => error.message,
          'message',
          'Assignment link already exists',
        ),
      ),
    );
  });
}

ItopResponse _response({
  int code = 0,
  required String message,
  ItopObject? object,
}) {
  return ItopResponse(
    code: code,
    message: message,
    objects: object == null ? const {} : {'object': object},
  );
}
