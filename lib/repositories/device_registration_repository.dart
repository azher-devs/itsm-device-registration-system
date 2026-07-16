// Repository boundary for documented iTop device registration operations.

import '../models/device.dart';
import '../models/employee.dart';
import '../models/itop_response.dart';
import '../services/device_registration_api_service.dart';
import '../services/itop_api_client.dart';

/// Carries an API-provided failure message unchanged to the controller.
class RegistrationDataException implements Exception {
  const RegistrationDataException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Carries a transport timeout message to the UI error state.
class RegistrationTimeoutException implements Exception {
  const RegistrationTimeoutException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Source-independent contract consumed by the Riverpod controller.
abstract class DeviceRegistrationRepository {
  Future<Device> getDevice(String tagNumber);

  Future<Employee> getEmployee(String employeeNumber);

  Future<String> addAssignment({
    required Device device,
    required Employee employee,
  });

  Future<String> removeAssignment({
    required Device device,
    required Employee employee,
  });

  Future<String> renameDevice({
    required Device device,
    required String newName,
  });
}

/// Dio-backed implementation prepared for the final iTop configuration.
class DioDeviceRegistrationRepository implements DeviceRegistrationRepository {
  const DioDeviceRegistrationRepository(this._service);

  final DeviceRegistrationApiService _service;

  @override
  Future<Device> getDevice(String tagNumber) async {
    return _guard(() async {
      final response = await _service.getDeviceByName(tagNumber);
      final object = _requireObject(response);
      final unresolvedDevice = Device.fromItopObject(object);
      final contacts = <DeviceContact>[];

      for (final contact in unresolvedDevice.contacts) {
        final personResponse = await _service.getEmployeeByContactId(
          contact.contactId,
        );
        final employee = Employee.fromItopObject(
          _requireObject(personResponse),
        );
        contacts.add(contact.copyWith(employeeNumber: employee.employeeNumber));
      }

      final device = Device.fromItopObject(object, contacts: contacts);
      if (!device.isValid) {
        throw RegistrationDataException(response.message);
      }
      return device;
    });
  }

  @override
  Future<Employee> getEmployee(String employeeNumber) {
    return _guard(() async {
      final response = await _service.getEmployeeByNumber(employeeNumber);
      final employee = Employee.fromItopObject(_requireObject(response));
      if (!employee.isValid) {
        throw RegistrationDataException(response.message);
      }
      return employee;
    });
  }

  @override
  Future<String> addAssignment({
    required Device device,
    required Employee employee,
  }) {
    return _guard(() async {
      final response = await _service.addAssignment(
        device: device,
        employee: employee,
      );
      _requireSuccess(response);
      return response.message;
    });
  }

  @override
  Future<String> removeAssignment({
    required Device device,
    required Employee employee,
  }) {
    return _guard(() async {
      final response = await _service.removeAssignment(
        device: device,
        employee: employee,
      );
      _requireSuccess(response);
      return response.message;
    });
  }

  @override
  Future<String> renameDevice({
    required Device device,
    required String newName,
  }) {
    return _guard(() async {
      final response = await _service.renameDevice(
        device: device,
        newName: newName,
      );
      _requireSuccess(response);
      return response.message;
    });
  }
}

/// Rejects both non-zero responses and successful searches with no objects.
ItopObject _requireObject(ItopResponse response) {
  _requireSuccess(response);
  final object = response.firstObject;
  if (object == null) {
    throw RegistrationDataException(response.message);
  }
  if (object.code != 0) {
    throw RegistrationDataException(object.message);
  }
  return object;
}

void _requireSuccess(ItopResponse response) {
  if (!response.isSuccess) {
    throw RegistrationDataException(response.message);
  }

  for (final object in response.objects.values) {
    if (object.code != 0) {
      throw RegistrationDataException(
        object.message.isNotEmpty ? object.message : response.message,
      );
    }
  }
}

/// Converts transport failures while preserving exact iTop messages.
Future<T> _guard<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on ItopClientException catch (error) {
    if (error.isTimeout) {
      throw RegistrationTimeoutException(error.message);
    }
    throw RegistrationDataException(error.message);
  }
}
