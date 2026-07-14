// Repository boundary for device registration data and assignment operations.

import '../models/device.dart';
import '../models/employee.dart';
import '../services/device_registration_api_service.dart';

/// Signals that a successful response did not contain a usable object.
class RegistrationDataException implements Exception {
  const RegistrationDataException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Contract consumed by Riverpod and replaced by fakes in widget tests.
abstract class DeviceRegistrationRepository {
  Future<Device> getDevice(String barcode);

  Future<Employee> getEmployee(String employeeNumber);

  Future<void> addAssignment({
    required String serialNumber,
    required String employeeNumber,
  });

  Future<void> removeAssignment({
    required String serialNumber,
    required String employeeNumber,
  });
}

/// Dio-backed repository that maps API payloads into application models.
class DioDeviceRegistrationRepository implements DeviceRegistrationRepository {
  const DioDeviceRegistrationRepository(this._service);

  final DeviceRegistrationApiService _service;

  @override
  Future<Device> getDevice(String barcode) async {
    final json = _extractObject(await _service.getDevice(barcode));
    if (json == null) {
      throw const RegistrationDataException('Device response was empty.');
    }

    final device = Device.fromJson(json);
    if (!device.isValid) {
      throw const RegistrationDataException('Device response was invalid.');
    }
    return device;
  }

  @override
  Future<Employee> getEmployee(String employeeNumber) async {
    final json = _extractObject(await _service.getEmployee(employeeNumber));
    if (json == null) {
      throw const RegistrationDataException('Employee response was empty.');
    }

    final employee = Employee.fromJson(json);
    if (!employee.isValid) {
      throw const RegistrationDataException('Employee response was invalid.');
    }
    return employee;
  }

  @override
  Future<void> addAssignment({
    required String serialNumber,
    required String employeeNumber,
  }) {
    return _service.addAssignment(
      serialNumber: serialNumber,
      employeeNumber: employeeNumber,
    );
  }

  @override
  Future<void> removeAssignment({
    required String serialNumber,
    required String employeeNumber,
  }) {
    return _service.removeAssignment(
      serialNumber: serialNumber,
      employeeNumber: employeeNumber,
    );
  }
}

/// Unwraps direct, nested, and list-shaped API responses into one object.
Map<String, dynamic>? _extractObject(Object? payload) {
  if (payload is List) {
    return payload.isEmpty ? null : _extractObject(payload.first);
  }

  if (payload is! Map) {
    return null;
  }

  final json = Map<String, dynamic>.from(payload);
  for (final key in const [
    'data',
    'object',
    'device',
    'employee',
    'items',
    'fields',
    'attributes',
  ]) {
    final nested = json[key];
    if (nested != null) {
      final extracted = _extractObject(nested);
      if (extracted != null) {
        return extracted;
      }
    }
  }

  return json.isEmpty ? null : json;
}
