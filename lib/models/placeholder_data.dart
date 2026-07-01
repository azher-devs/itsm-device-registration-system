// Placeholder data used while backend integration is out of scope.

/// Placeholder device data used until the fake API layer is connected.
class PlaceholderDeviceData {
  const PlaceholderDeviceData._();

  /// Primary device identifier shown in the registration workflow.
  static const tagNumber = 'TAG-2024-000123';

  /// Serial number shown after a scan populates the registration form.
  static const serialNumber = 'SN-VR84-9922-ABCD';

  /// Example device brand displayed in UI cards.
  static const brand = 'Dell';

  /// Example device category displayed in UI cards.
  static const type = 'Laptop';
}

/// Placeholder employee data used until employee lookup is implemented.
class PlaceholderEmployeeData {
  const PlaceholderEmployeeData._();

  /// Primary employee identifier used in the registration form.
  static const id = 'EMP-10045';

  /// Example employee name shown after validation.
  static const name = 'Ahmed Al Balushi';

  /// Example department shown in employee details.
  static const department = 'Information Technology';

  /// Example location shown in employee details.
  static const location = 'Sultan Qaboos University';
}
