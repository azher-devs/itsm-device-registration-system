// Riverpod state and controller for device assignment workflows.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/device.dart';
import '../models/employee.dart';
import '../repositories/device_registration_repository.dart';
import '../services/device_registration_api_service.dart';

/// Current asynchronous operation shown by the registration screen.
enum RegistrationOperation {
  idle,
  loadingDevice,
  loadingEmployee,
  addingAssignment,
  removingAssignment,
}

/// One-time result communicated to the UI through a localized snackbar.
enum RegistrationNotice {
  assignmentAdded,
  assignmentRemoved,
  assignmentAddFailed,
  assignmentRemoveFailed,
}

/// Immutable state for device, employee, validation, and assignment actions.
class DeviceRegistrationState {
  const DeviceRegistrationState({
    this.device,
    this.employee,
    this.operation = RegistrationOperation.idle,
    this.tagError = false,
    this.tagTimedOut = false,
    this.employeeError = false,
    this.notice,
    this.noticeVersion = 0,
  });

  final Device? device;
  final Employee? employee;
  final RegistrationOperation operation;
  final bool tagError;
  final bool tagTimedOut;
  final bool employeeError;
  final RegistrationNotice? notice;

  /// Increments for every notice so repeated failures still reach listeners.
  final int noticeVersion;

  bool get isBusy => operation != RegistrationOperation.idle;

  bool get canAdd =>
      device != null &&
      !device!.isAssigned &&
      employee?.isValid == true &&
      !isBusy;

  bool get canRemove =>
      device?.isAssigned == true &&
      device!.serialNumber.isNotEmpty &&
      device!.assignedEmployeeNumber != null &&
      !isBusy;

  DeviceRegistrationState copyWith({
    Device? device,
    Employee? employee,
    RegistrationOperation? operation,
    bool? tagError,
    bool? tagTimedOut,
    bool? employeeError,
    RegistrationNotice? notice,
    int? noticeVersion,
    bool clearDevice = false,
    bool clearEmployee = false,
    bool clearNotice = false,
  }) {
    return DeviceRegistrationState(
      device: clearDevice ? null : device ?? this.device,
      employee: clearEmployee ? null : employee ?? this.employee,
      operation: operation ?? this.operation,
      tagError: tagError ?? this.tagError,
      tagTimedOut: tagTimedOut ?? this.tagTimedOut,
      employeeError: employeeError ?? this.employeeError,
      notice: clearNotice ? null : notice ?? this.notice,
      noticeVersion: noticeVersion ?? this.noticeVersion,
    );
  }
}

/// Configures Dio without embedding transport concerns in the UI.
final registrationDioProvider = Provider<Dio>((ref) {
  const baseUrl = String.fromEnvironment(
    'ITSM_API_BASE_URL',
    defaultValue: 'http://localhost',
  );

  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ),
  );
});

/// Provides the replaceable repository used by the registration controller.
final deviceRegistrationRepositoryProvider =
    Provider<DeviceRegistrationRepository>((ref) {
      final service = DeviceRegistrationApiService(
        ref.watch(registrationDioProvider),
      );
      return DioDeviceRegistrationRepository(service);
    });

/// Provides one controller instance for each registration screen lifecycle.
final deviceRegistrationControllerProvider =
    StateNotifierProvider.autoDispose<
      DeviceRegistrationController,
      DeviceRegistrationState
    >((ref) {
      return DeviceRegistrationController(
        ref.watch(deviceRegistrationRepositoryProvider),
      );
    });

/// Coordinates UI state with repository calls and guards duplicate actions.
class DeviceRegistrationController
    extends StateNotifier<DeviceRegistrationState> {
  DeviceRegistrationController(this._repository)
    : super(const DeviceRegistrationState());

  final DeviceRegistrationRepository _repository;

  /// Loads a device and its assigned employee, clearing all stale employee data.
  Future<bool> searchDevice(String rawTag) async {
    final tag = rawTag.trim();
    if (tag.isEmpty || state.isBusy) {
      state = state.copyWith(tagError: true);
      return false;
    }

    state = state.copyWith(
      operation: RegistrationOperation.loadingDevice,
      tagError: false,
      tagTimedOut: false,
      employeeError: false,
      clearDevice: true,
      clearEmployee: true,
      clearNotice: true,
    );

    try {
      final device = await _repository.getDevice(tag);
      state = state.copyWith(
        device: device,
        operation: RegistrationOperation.idle,
      );

      final assignedEmployee = device.assignedEmployeeNumber;
      if (assignedEmployee != null) {
        await _loadAssignedEmployee(assignedEmployee);
      }
      return true;
    } on RegistrationTimeoutException {
      state = state.copyWith(
        operation: RegistrationOperation.idle,
        tagError: true,
        tagTimedOut: true,
        clearDevice: true,
        clearEmployee: true,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        operation: RegistrationOperation.idle,
        tagError: true,
        tagTimedOut: false,
        clearDevice: true,
        clearEmployee: true,
      );
      return false;
    }
  }

  /// Searches for an employee only while the selected device is unassigned.
  Future<bool> searchEmployee(String rawEmployeeNumber) async {
    final employeeNumber = rawEmployeeNumber.trim();
    final device = state.device;
    if (employeeNumber.isEmpty ||
        device == null ||
        device.isAssigned ||
        state.isBusy) {
      state = state.copyWith(employeeError: true, clearEmployee: true);
      return false;
    }

    state = state.copyWith(
      operation: RegistrationOperation.loadingEmployee,
      employeeError: false,
      clearEmployee: true,
      clearNotice: true,
    );

    try {
      final employee = await _repository.getEmployee(employeeNumber);
      state = state.copyWith(
        employee: employee,
        operation: RegistrationOperation.idle,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        operation: RegistrationOperation.idle,
        employeeError: true,
        clearEmployee: true,
      );
      return false;
    }
  }

  /// Creates the assignment after the UI confirmation dialog is accepted.
  Future<bool> addAssignment() async {
    if (!state.canAdd) {
      return false;
    }

    final device = state.device!;
    final employee = state.employee!;
    state = state.copyWith(operation: RegistrationOperation.addingAssignment);

    try {
      await _repository.addAssignment(
        serialNumber: device.serialNumber,
        employeeNumber: employee.employeeNumber,
      );
      state = state.copyWith(
        device: device.copyWith(
          status: 'Assigned',
          contacts: [DeviceContact(employeeNumber: employee.employeeNumber)],
        ),
        operation: RegistrationOperation.idle,
      );
      _publishNotice(RegistrationNotice.assignmentAdded);
      return true;
    } catch (_) {
      state = state.copyWith(operation: RegistrationOperation.idle);
      _publishNotice(RegistrationNotice.assignmentAddFailed);
      return false;
    }
  }

  /// Removes the current assignment while preserving the selected device.
  Future<bool> removeAssignment() async {
    if (!state.canRemove) {
      return false;
    }

    final device = state.device!;
    final employeeNumber = device.assignedEmployeeNumber!;
    state = state.copyWith(operation: RegistrationOperation.removingAssignment);

    try {
      await _repository.removeAssignment(
        serialNumber: device.serialNumber,
        employeeNumber: employeeNumber,
      );
      state = state.copyWith(
        device: device.copyWith(status: 'Not Assigned', contacts: const []),
        operation: RegistrationOperation.idle,
        employeeError: false,
        clearEmployee: true,
      );
      _publishNotice(RegistrationNotice.assignmentRemoved);
      return true;
    } catch (_) {
      state = state.copyWith(operation: RegistrationOperation.idle);
      _publishNotice(RegistrationNotice.assignmentRemoveFailed);
      return false;
    }
  }

  /// Clears tag validation feedback while users correct the input.
  void clearTagError() {
    if (state.tagError) {
      state = state.copyWith(tagError: false, tagTimedOut: false);
    }
  }

  /// Clears stale employee details and validation when editable input changes.
  void employeeInputChanged() {
    if (!state.isBusy && state.device?.isAssigned != true) {
      state = state.copyWith(employeeError: false, clearEmployee: true);
    }
  }

  /// Fetches full details for the employee referenced by `contacts_list`.
  Future<void> _loadAssignedEmployee(String employeeNumber) async {
    state = state.copyWith(operation: RegistrationOperation.loadingEmployee);
    try {
      final employee = await _repository.getEmployee(employeeNumber);
      state = state.copyWith(
        employee: employee,
        operation: RegistrationOperation.idle,
      );
    } catch (_) {
      // Assignment remains visible even if its optional employee detail call fails.
      state = state.copyWith(operation: RegistrationOperation.idle);
    }
  }

  /// Publishes a one-time localized UI notice without storing visible strings.
  void _publishNotice(RegistrationNotice notice) {
    state = state.copyWith(
      notice: notice,
      noticeVersion: state.noticeVersion + 1,
    );
  }
}
