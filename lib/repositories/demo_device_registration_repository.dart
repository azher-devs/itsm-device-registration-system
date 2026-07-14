// In-memory repository used by the standalone Device Registration UI demo.

import '../models/device.dart';
import '../models/employee.dart';
import 'device_registration_repository.dart';

/// Configurable local delays keep loading states visible during demonstrations.
class DemoRegistrationDelays {
  const DemoRegistrationDelays({
    this.deviceSearch = const Duration(milliseconds: 500),
    this.employeeSearch = const Duration(milliseconds: 500),
    this.addAssignment = const Duration(milliseconds: 700),
    this.removeAssignment = const Duration(milliseconds: 700),
    this.timeout = const Duration(seconds: 3),
  });

  /// Disables delays so automated tests remain fast and deterministic.
  const DemoRegistrationDelays.none()
    : deviceSearch = Duration.zero,
      employeeSearch = Duration.zero,
      addAssignment = Duration.zero,
      removeAssignment = Duration.zero,
      timeout = Duration.zero;

  final Duration deviceSearch;
  final Duration employeeSearch;
  final Duration addAssignment;
  final Duration removeAssignment;
  final Duration timeout;
}

/// Provides mutable demo data without Dio, HTTP, credentials, or a backend.
class DemoDeviceRegistrationRepository implements DeviceRegistrationRepository {
  DemoDeviceRegistrationRepository({
    this.delays = const DemoRegistrationDelays(),
  }) : _devices = _createDevices();

  final DemoRegistrationDelays delays;
  final Map<String, Device> _devices;

  static const String validEmployeeNumber = 'EMP-10045';
  static const String timeoutTag = 'TAG-TIMEOUT';
  static const String notFoundTag = 'TAG-NOT-FOUND';
  static const String invalidEmployeeNumber = 'EMP-NOT-FOUND';

  static const Employee _employee = Employee(
    employeeNumber: validEmployeeNumber,
    fullName: 'Ahmed Al Balushi',
    email: 'ahmed@example.com',
    organization: 'Information Technology',
    phone: '+968 1234 5678',
    status: 'Active',
    jobTitle: 'Support Engineer',
  );

  @override
  Future<Device> getDevice(String barcode) async {
    final tag = barcode.trim().toUpperCase();
    if (tag == timeoutTag) {
      await Future<void>.delayed(delays.timeout);
      throw const RegistrationTimeoutException();
    }

    await Future<void>.delayed(delays.deviceSearch);
    final device = _devices[tag];
    if (device == null) {
      throw const RegistrationDataException('Demo device not found.');
    }
    return device;
  }

  @override
  Future<Employee> getEmployee(String employeeNumber) async {
    await Future<void>.delayed(delays.employeeSearch);
    if (employeeNumber.trim().toUpperCase() != validEmployeeNumber) {
      throw const RegistrationDataException('Demo employee not found.');
    }
    return _employee;
  }

  @override
  Future<void> addAssignment({
    required String serialNumber,
    required String employeeNumber,
  }) async {
    await Future<void>.delayed(delays.addAssignment);
    final entry = _findBySerialNumber(serialNumber);
    if (entry == null || employeeNumber != validEmployeeNumber) {
      throw const RegistrationDataException('Invalid demo assignment.');
    }
    if (entry.value.tagNumber == 'TAG-ADD-FAIL') {
      throw const RegistrationDataException('Simulated add failure.');
    }

    _devices[entry.key] = entry.value.copyWith(
      status: 'Assigned',
      contacts: const [DeviceContact(employeeNumber: validEmployeeNumber)],
    );
  }

  @override
  Future<void> removeAssignment({
    required String serialNumber,
    required String employeeNumber,
  }) async {
    await Future<void>.delayed(delays.removeAssignment);
    final entry = _findBySerialNumber(serialNumber);
    if (entry == null || employeeNumber != validEmployeeNumber) {
      throw const RegistrationDataException('Invalid demo removal.');
    }
    if (entry.value.tagNumber == 'TAG-REMOVE-FAIL') {
      throw const RegistrationDataException('Simulated remove failure.');
    }

    _devices[entry.key] = entry.value.copyWith(
      status: 'Not Assigned',
      contacts: const [],
    );
  }

  /// Finds mutable device storage by the serial number used for assignments.
  MapEntry<String, Device>? _findBySerialNumber(String serialNumber) {
    for (final entry in _devices.entries) {
      if (entry.value.serialNumber == serialNumber) {
        return entry;
      }
    }
    return null;
  }

  /// Creates fresh demo state each time the demo application starts.
  static Map<String, Device> _createDevices() {
    return {
      'TAG-UNASSIGNED': const Device(
        tagNumber: 'TAG-UNASSIGNED',
        brand: 'Dell',
        deviceType: 'Laptop',
        serialNumber: 'SN-UNASSIGNED',
        status: 'Not Assigned',
        contacts: [],
      ),
      'TAG-ASSIGNED': const Device(
        tagNumber: 'TAG-ASSIGNED',
        brand: 'HP',
        deviceType: 'Desktop',
        serialNumber: 'SN-ASSIGNED',
        status: 'Assigned',
        contacts: [DeviceContact(employeeNumber: validEmployeeNumber)],
      ),
      'TAG-SECOND': const Device(
        tagNumber: 'TAG-SECOND',
        brand: 'Lenovo',
        deviceType: 'Tablet',
        serialNumber: 'SN-SECOND',
        status: 'Not Assigned',
        contacts: [],
      ),
      'TAG-ADD-FAIL': const Device(
        tagNumber: 'TAG-ADD-FAIL',
        brand: 'Acer',
        deviceType: 'Laptop',
        serialNumber: 'SN-ADD-FAIL',
        status: 'Not Assigned',
        contacts: [],
      ),
      'TAG-REMOVE-FAIL': const Device(
        tagNumber: 'TAG-REMOVE-FAIL',
        brand: 'Apple',
        deviceType: 'Desktop',
        serialNumber: 'SN-REMOVE-FAIL',
        status: 'Assigned',
        contacts: [DeviceContact(employeeNumber: validEmployeeNumber)],
      ),
    };
  }
}
