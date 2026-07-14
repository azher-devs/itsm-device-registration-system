// Employee data returned by the ITSM employee lookup endpoint.

/// Employee information displayed when searching or loading an assignment.
class Employee {
  const Employee({
    required this.employeeNumber,
    required this.fullName,
    required this.email,
    required this.organization,
    required this.phone,
    required this.status,
    required this.jobTitle,
  });

  /// Employee identifier used by assignment API requests.
  final String employeeNumber;

  /// Employee display name.
  final String fullName;

  /// Employee email address when supplied by the API.
  final String email;

  /// Organization or department name.
  final String organization;

  /// Employee contact number.
  final String phone;

  /// Current employee status.
  final String status;

  /// Function or job title.
  final String jobTitle;

  /// Parses common iTop field variants without assuming every field exists.
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      employeeNumber: _stringValue(json, const [
        'employee_number',
        'employeeNumber',
        'employee_id',
        'employeeId',
        'number',
      ]),
      fullName: _stringValue(json, const [
        'full_name',
        'fullName',
        'name',
        'friendlyname',
      ]),
      email: _stringValue(json, const ['email', 'email_address']),
      organization: _stringValue(json, const [
        'organization',
        'organisation',
        'department',
        'org_name',
      ]),
      phone: _stringValue(json, const ['phone', 'telephone', 'mobile']),
      status: _stringValue(json, const ['status', 'status_name', 'state']),
      jobTitle: _stringValue(json, const [
        'function',
        'job_title',
        'jobTitle',
        'title',
      ]),
    );
  }

  /// Employee searches are valid only when the API returns an identifier.
  bool get isValid => employeeNumber.trim().isNotEmpty;
}

/// Reads the first non-empty scalar value matching a known API key.
String _stringValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String || value is num) {
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
  }
  return '';
}
