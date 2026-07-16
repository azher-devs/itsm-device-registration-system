// iTop instructions for device, employee, assignment, and rename operations.

import '../models/device.dart';
import '../models/employee.dart';
import '../models/itop_response.dart';
import 'itop_api_client.dart';

/// Builds only the REST/JSON operations defined in the supplied iTop specification.
class DeviceRegistrationApiService {
  const DeviceRegistrationApiService(this._client);

  final ItopApiClient _client;

  /// Searches PhysicalDevice.name, which is the application's Tag Number.
  Future<ItopResponse> getDeviceByName(String name) {
    return _client.execute({
      'operation': 'core/get',
      'class': 'PhysicalDevice',
      'key': "SELECT PhysicalDevice WHERE name = '${_oql(name)}'",
      'output_fields':
          'name, serialnumber, asset_number, status, '
          'brand_id_friendlyname, model_id_friendlyname, description, '
          'contacts_list',
      'limit': 100,
      'page': 1,
    });
  }

  /// Resolves a device contact ID to the Person employee number and profile.
  Future<ItopResponse> getEmployeeByContactId(String contactId) {
    return _client.execute({
      'operation': 'core/get',
      'class': 'Person',
      'key': contactId,
      'output_fields': _personOutputFields,
    });
  }

  /// Searches Person.employee_number for manual employee lookup.
  Future<ItopResponse> getEmployeeByNumber(String employeeNumber) {
    return _client.execute({
      'operation': 'core/get',
      'class': 'Person',
      'key': "SELECT Person WHERE employee_number = '${_oql(employeeNumber)}'",
      'output_fields': _personOutputFields,
    });
  }

  /// Creates the documented lnkContactToFunctionalCI relationship.
  Future<ItopResponse> addAssignment({
    required Device device,
    required Employee employee,
  }) {
    return _client.execute({
      'operation': 'core/create',
      'class': 'lnkContactToFunctionalCI',
      'comment': 'Linked via Mobile App Portal',
      'fields': {
        'functionalci_id': _numericKey(device.itopKey),
        'contact_id': _numericKey(employee.itopKey),
      },
    });
  }

  /// Deletes the documented link between a device and Person contact.
  Future<ItopResponse> removeAssignment({
    required Device device,
    required Employee employee,
  }) {
    return _client.execute({
      'operation': 'core/delete',
      'class': 'lnkContactToFunctionalCI',
      'key':
          'SELECT lnkContactToFunctionalCI WHERE functionalci_id = '
          '${_oql(device.itopKey)} AND contact_id = ${_oql(employee.itopKey)}',
      'comment': 'Unlinked via Mobile App Interface',
    });
  }

  /// Updates the iTop `name` field used as Tag Number.
  Future<ItopResponse> renameDevice({
    required Device device,
    required String newName,
  }) {
    return _client.execute({
      'operation': 'core/update',
      'class': device.itopClass,
      'key': _numericKey(device.itopKey),
      'comment': 'Name tag modified via Mobile App Portal',
      'fields': {'name': newName},
    });
  }
}

const _personOutputFields =
    'first_name, name, email, org_id_friendlyname, phone, status, '
    'function, employee_number';

/// Escapes quoted values embedded in documented OQL selectors.
String _oql(String value) => value.replaceAll("'", "\\'");

/// Preserves numeric iTop keys as numbers in create and update payloads.
Object _numericKey(String value) => int.tryParse(value) ?? value;
