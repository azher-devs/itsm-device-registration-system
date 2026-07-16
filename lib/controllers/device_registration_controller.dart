// Riverpod state and controller for device assignment workflows.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/itop_configuration.dart';
import '../models/device.dart';
import '../models/employee.dart';
import '../repositories/device_registration_repository.dart';
import '../services/device_registration_api_service.dart';
import '../services/itop_api_client.dart';

/// Current asynchronous operation shown by the registration screen.
enum RegistrationOperation {
  idle,
  loadingDevice,
  loadingEmployee,
  addingAssignment,
  removingAssignment,
}

/// One-time result communicated to the UI through a snackbar.
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
    this.tagErrorMessage,
    this.employeeError = false,
    this.employeeErrorMessage,
    this.notice,
    this.noticeMessage,
    this.noticeVersion = 0,
  });

  final Device? device;
  final Employee? employee;
  final RegistrationOperation operation;
  final bool tagError;
  final bool tagTimedOut;
  final String? tagErrorMessage;
  final bool employeeError;
  final String? employeeErrorMessage;
  final RegistrationNotice? notice;
  final String? noticeMessage;

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
      employee?.isValid == true &&
      !isBusy;

  DeviceRegistrationState copyWith({
    Device? device,
    Employee? employee,
    RegistrationOperation? operation,
    bool? tagError,
    bool? tagTimedOut,
    String? tagErrorMessage,
    bool? employeeError,
    String? employeeErrorMessage,
    RegistrationNotice? notice,
    String? noticeMessage,
    int? noticeVersion,
    bool clearDevice = false,
    bool clearEmployee = false,
    bool clearNotice = false,
    bool clearTagErrorMessage = false,
    bool clearEmployeeErrorMessage = false,
  }) {
    return DeviceRegistrationState(
      device: clearDevice ? null : device ?? this.device,
      employee: clearEmployee ? null : employee ?? this.employee,
      operation: operation ?? this.operation,
      tagError: tagError ?? this.tagError,
      tagTimedOut: tagTimedOut ?? this.tagTimedOut,
      tagErrorMessage: clearTagErrorMessage
          ? null
          : tagErrorMessage ?? this.tagErrorMessage,
      employeeError: employeeError ?? this.employeeError,
      employeeErrorMessage: clearEmployeeErrorMessage
          ? null
          : employeeErrorMessage ?? this.employeeErrorMessage,
      notice: clearNotice ? null : notice ?? this.notice,
      noticeMessage: clearNotice ? null : noticeMessage ?? this.noticeMessage,
      noticeVersion: noticeVersion ?? this.noticeVersion,
    );
  }
}

/// Configures Dio without embedding transport concerns in the UI.
final itopConfigurationProvider = Provider<ItopConfiguration>((ref) {
  return ItopConfiguration.placeholder;
});

final registrationDioProvider = Provider<Dio>((ref) {
  final config = ref.watch(itopConfigurationProvider);
  return Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ),
  );
});

/// Provides the replaceable repository used by the registration controller.
final deviceRegistrationRepositoryProvider =
    Provider<DeviceRegistrationRepository>((ref) {
      final config = ref.watch(itopConfigurationProvider);
      final client = ItopApiClient(
        dio: ref.watch(registrationDioProvider),
        config: config,
      );
      final service = DeviceRegistrationApiService(client);
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
      clearTagErrorMessage: true,
      clearEmployeeErrorMessage: true,
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
    } on RegistrationTimeoutException catch (error) {
      state = state.copyWith(
        operation: RegistrationOperation.idle,
        tagError: true,
        tagTimedOut: true,
        tagErrorMessage: error.message,
        clearDevice: true,
        clearEmployee: true,
      );
      return false;
    } on RegistrationDataException catch (error) {
      state = state.copyWith(
        operation: RegistrationOperation.idle,
        tagError: true,
        tagTimedOut: false,
        tagErrorMessage: error.message,
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
      clearEmployeeErrorMessage: true,
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
    } on RegistrationDataException catch (error) {
      state = state.copyWith(
        operation: RegistrationOperation.idle,
        employeeError: true,
        employeeErrorMessage: error.message,
        clearEmployee: true,
      );
      return false;
    } on RegistrationTimeoutException catch (error) {
      state = state.copyWith(
        operation: RegistrationOperation.idle,
        employeeError: true,
        employeeErrorMessage: error.message,
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
      await _repository.addAssignment(device: device, employee: employee);
      state = state.copyWith(
        device: device.copyWith(
          status: 'Assigned',
          contacts: [
            DeviceContact(
              contactId: employee.itopKey,
              employeeNumber: employee.employeeNumber,
            ),
          ],
        ),
        operation: RegistrationOperation.idle,
      );
      _publishNotice(RegistrationNotice.assignmentAdded);
      return true;
    } on RegistrationDataException catch (error) {
      state = state.copyWith(operation: RegistrationOperation.idle);
      _publishNotice(
        RegistrationNotice.assignmentAddFailed,
        message: error.message,
      );
      return false;
    } on RegistrationTimeoutException catch (error) {
      state = state.copyWith(operation: RegistrationOperation.idle);
      _publishNotice(
        RegistrationNotice.assignmentAddFailed,
        message: error.message,
      );
      return false;
    }
  }

  /// Removes the current assignment while preserving the selected device.
  Future<bool> removeAssignment() async {
    if (!state.canRemove) {
      return false;
    }

    final device = state.device!;
    final employee = state.employee!;
    state = state.copyWith(operation: RegistrationOperation.removingAssignment);

    try {
      await _repository.removeAssignment(device: device, employee: employee);
      state = state.copyWith(
        device: device.copyWith(status: 'Not Assigned', contacts: const []),
        operation: RegistrationOperation.idle,
        employeeError: false,
        clearEmployee: true,
      );
      _publishNotice(RegistrationNotice.assignmentRemoved);
      return true;
    } on RegistrationDataException catch (error) {
      state = state.copyWith(operation: RegistrationOperation.idle);
      _publishNotice(
        RegistrationNotice.assignmentRemoveFailed,
        message: error.message,
      );
      return false;
    } on RegistrationTimeoutException catch (error) {
      state = state.copyWith(operation: RegistrationOperation.idle);
      _publishNotice(
        RegistrationNotice.assignmentRemoveFailed,
        message: error.message,
      );
      return false;
    }
  }

  /// Clears tag validation feedback while users correct the input.
  void clearTagError() {
    if (state.tagError) {
      state = state.copyWith(
        tagError: false,
        tagTimedOut: false,
        clearTagErrorMessage: true,
      );
    }
  }

  /// Clears stale employee details and validation when editable input changes.
  void employeeInputChanged() {
    if (!state.isBusy && state.device?.isAssigned != true) {
      state = state.copyWith(
        employeeError: false,
        clearEmployee: true,
        clearEmployeeErrorMessage: true,
      );
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
    } on RegistrationDataException catch (error) {
      state = state.copyWith(
        operation: RegistrationOperation.idle,
        employeeError: true,
        employeeErrorMessage: error.message,
      );
    } on RegistrationTimeoutException catch (error) {
      state = state.copyWith(
        operation: RegistrationOperation.idle,
        employeeError: true,
        employeeErrorMessage: error.message,
      );
    }
  }

  /// Publishes a one-time notice and preserves any API-provided error message.
  void _publishNotice(RegistrationNotice notice, {String? message}) {
    state = state.copyWith(
      notice: notice,
      noticeMessage: message,
      noticeVersion: state.noticeVersion + 1,
    );
  }
}
