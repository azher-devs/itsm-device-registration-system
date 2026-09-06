// Employee domain model mapped from documented iTop Person fields.

import 'itop_response.dart';

/// Employee profile returned from the iTop `Person` class.
class Employee {
  const Employee({
    required this.employeeNumber,
    required this.fullName,
    required this.email,
    required this.organization,
    required this.phone,
    required this.status,
    required this.jobTitle,
    this.itopKey = '',
    this.firstName = '',
    this.lastName = '',
  });

  /// iTop Person key used by assignment linkage operations.
  final String itopKey;
  final String employeeNumber;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String organization;
  final String phone;
  final String status;
  final String jobTitle;

  /// Maps the exact fields returned by both documented Person searches.
  factory Employee.fromItopObject(ItopObject object) {
    final fields = object.fields;
    final firstName = _stringValue(fields, const ['first_name']);
    final lastName = _stringValue(fields, const ['name']);
    return Employee(
      itopKey: object.key,
      employeeNumber: _stringValue(fields, const ['employee_number']),
      firstName: firstName,
      lastName: lastName,
      fullName: [
        firstName,
        lastName,
      ].where((part) => part.isNotEmpty).join(' '),
      email: _stringValue(fields, const ['email']),
      organization: _stringValue(fields, const ['org_id_friendlyname']),
      phone: _stringValue(fields, const ['phone']),
      status: _stringValue(fields, const ['status']),
      jobTitle: _stringValue(fields, const ['function']),
    );
  }

  /// Compatibility mapper that recognizes documented iTop field names first.
  factory Employee.fromJson(Map<String, dynamic> json) {
    final firstName = _stringValue(json, const ['first_name', 'firstName']);
    final lastName = _stringValue(json, const ['name', 'lastName']);
    final explicitFullName = _stringValue(json, const [
      'full_name',
      'fullName',
      'friendlyname',
    ]);
    return Employee(
      itopKey: _stringValue(json, const ['key', 'id', 'contact_id']),
      employeeNumber: _stringValue(json, const [
        'employee_number',
        'employeeNumber',
        'employee_id',
      ]),
      firstName: firstName,
      lastName: lastName,
      fullName: explicitFullName.isNotEmpty
          ? explicitFullName
          : [firstName, lastName].where((part) => part.isNotEmpty).join(' '),
      email: _stringValue(json, const ['email']),
      organization: _stringValue(json, const [
        'org_id_friendlyname',
        'organization',
        'department',
      ]),
      phone: _stringValue(json, const ['phone']),
      status: _stringValue(json, const ['status']),
      jobTitle: _stringValue(json, const ['function', 'job_title', 'jobTitle']),
    );
  }

  bool get isValid =>
      employeeNumber.trim().isNotEmpty && itopKey.trim().isNotEmpty;
}

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
