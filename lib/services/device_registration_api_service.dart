// Dio service for device, employee, and assignment API requests.

import 'package:dio/dio.dart';

/// Performs the HTTP calls required by the device assignment workflow.
class DeviceRegistrationApiService {
  const DeviceRegistrationApiService(this._dio);

  final Dio _dio;

  /// Fetches a device using either a typed tag or scanned barcode.
  Future<Object?> getDevice(String barcode) async {
    final response = await _dio.get<Object?>(
      '/api/device',
      queryParameters: {'barcode': barcode},
    );
    return response.data;
  }

  /// Fetches complete employee information by employee number.
  Future<Object?> getEmployee(String employeeNumber) async {
    final response = await _dio.get<Object?>(
      '/api/employee/${Uri.encodeComponent(employeeNumber)}',
    );
    return response.data;
  }

  /// Creates a device-to-employee assignment.
  Future<void> addAssignment({
    required String serialNumber,
    required String employeeNumber,
  }) async {
    await _dio.post<void>(
      '/api/link',
      queryParameters: {
        'serial_number': serialNumber,
        'employee_number': employeeNumber,
      },
    );
  }

  /// Removes a device-to-employee assignment.
  Future<void> removeAssignment({
    required String serialNumber,
    required String employeeNumber,
  }) async {
    await _dio.delete<void>(
      '/api/link',
      queryParameters: {
        'serial_number': serialNumber,
        'employee_number': employeeNumber,
      },
    );
  }
}
