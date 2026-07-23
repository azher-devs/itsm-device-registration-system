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
  static const String notFoundMessage = 'Found: 0';
  static const String addFailureMessage = 'Unable to create assignment';
  static const String removeFailureMessage = 'Unable to delete assignment';
  static const String timeoutMessage = 'Connection timed out';

  static const Employee _employee = Employee(
    itopKey: '10064',
    employeeNumber: validEmployeeNumber,
    firstName: 'Ahmed',
    lastName: 'Al Balushi',
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
      throw const RegistrationTimeoutException(timeoutMessage);
    }

    await Future<void>.delayed(delays.deviceSearch);
    final device = _devices[tag];
    if (device == null) {
      throw const RegistrationDataException(notFoundMessage);
    }
    return device;
  }

  @override
  Future<Employee> getEmployee(String employeeNumber) async {
    await Future<void>.delayed(delays.employeeSearch);
    if (employeeNumber.trim().toUpperCase() != validEmployeeNumber) {
      throw const RegistrationDataException(notFoundMessage);
    }
    return _employee;
  }

  @override
  Future<Employee> getEmployeeByContactId(String contactId) async {
    await Future<void>.delayed(delays.employeeSearch);
    if (contactId.trim() != _employee.itopKey) {
      throw const RegistrationDataException(notFoundMessage);
    }
    return _employee;
  }

  @override
  Future<String> addAssignment({
    required Device device,
    required Employee employee,
  }) async {
    await Future<void>.delayed(delays.addAssignment);
    final entry = _findByItopKey(device.itopKey);
    if (entry == null || employee.itopKey != _employee.itopKey) {
      throw const RegistrationDataException('Invalid assignment data');
    }
    if (entry.value.tagNumber == 'TAG-ADD-FAIL') {
      throw const RegistrationDataException(addFailureMessage);
    }

    _devices[entry.key] = entry.value.copyWith(
      status: 'Assigned',
      contacts: const [
        DeviceContact(contactId: '10064', employeeNumber: validEmployeeNumber),
      ],
    );
    return 'Object created';
  }

  @override
  Future<String> removeAssignment({
    required Device device,
    required Employee employee,
  }) async {
    await Future<void>.delayed(delays.removeAssignment);
    final entry = _findByItopKey(device.itopKey);
    if (entry == null || employee.itopKey != _employee.itopKey) {
      throw const RegistrationDataException('Invalid assignment data');
    }
    if (entry.value.tagNumber == 'TAG-REMOVE-FAIL') {
      throw const RegistrationDataException(removeFailureMessage);
    }

    _devices[entry.key] = entry.value.copyWith(
      status: 'Not Assigned',
      contacts: const [],
    );
    return 'Objects deleted';
  }

  @override
  Future<String> renameDevice({
    required Device device,
    required String newName,
  }) async {
    await Future<void>.delayed(delays.deviceSearch);
    final entry = _findByItopKey(device.itopKey);
    if (entry == null) {
      throw const RegistrationDataException(notFoundMessage);
    }
    final renamed = _devices.remove(entry.key)!.copyWith(tagNumber: newName);
    _devices[newName.toUpperCase()] = renamed;
    return 'Object updated';
  }

  /// Finds a mutable demo device using the iTop object key.
  MapEntry<String, Device>? _findByItopKey(String itopKey) {
    for (final entry in _devices.entries) {
      if (entry.value.itopKey == itopKey) {
        return entry;
      }
    }
    return null;
  }

  /// Creates fresh demo state each time the demo application starts.
  static Map<String, Device> _createDevices() {
    return {
      'TAG-UNASSIGNED': const Device(
        itopKey: '1603',
        itopClass: 'PC',
        tagNumber: 'TAG-UNASSIGNED',
        brand: 'Dell',
        deviceType: 'Laptop',
        serialNumber: 'SN-UNASSIGNED',
        status: 'Not Assigned',
        contacts: [],
      ),
      'TAG-ASSIGNED': const Device(
        itopKey: '1604',
        itopClass: 'PC',
        tagNumber: 'TAG-ASSIGNED',
        brand: 'HP',
        deviceType: 'Desktop',
        serialNumber: 'SN-ASSIGNED',
        status: 'Assigned',
        contacts: [
          DeviceContact(
            contactId: '10064',
            employeeNumber: validEmployeeNumber,
          ),
        ],
      ),
      'TAG-SECOND': const Device(
        itopKey: '1605',
        itopClass: 'Tablet',
        tagNumber: 'TAG-SECOND',
        brand: 'Lenovo',
        deviceType: 'Tablet',
        serialNumber: 'SN-SECOND',
        status: 'Not Assigned',
        contacts: [],
      ),
      'TAG-ADD-FAIL': const Device(
        itopKey: '1606',
        itopClass: 'PC',
        tagNumber: 'TAG-ADD-FAIL',
        brand: 'Acer',
        deviceType: 'Laptop',
        serialNumber: 'SN-ADD-FAIL',
        status: 'Not Assigned',
        contacts: [],
      ),
      'TAG-REMOVE-FAIL': const Device(
        itopKey: '1607',
        itopClass: 'PC',
        tagNumber: 'TAG-REMOVE-FAIL',
        brand: 'Apple',
        deviceType: 'Desktop',
        serialNumber: 'SN-REMOVE-FAIL',
        status: 'Assigned',
        contacts: [
          DeviceContact(
            contactId: '10064',
            employeeNumber: validEmployeeNumber,
          ),
        ],
      ),
    };
  }
}
