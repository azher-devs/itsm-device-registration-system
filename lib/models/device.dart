// Device data returned by the ITSM device lookup endpoint.

/// Employee reference attached to a device through `contacts_list`.
class DeviceContact {
  const DeviceContact({required this.employeeNumber});

  /// Employee identifier used by the employee and assignment endpoints.
  final String employeeNumber;

  /// Safely maps common iTop contact shapes to a usable employee reference.
  factory DeviceContact.fromDynamic(Object? value) {
    if (value is String || value is num) {
      return DeviceContact(employeeNumber: value.toString().trim());
    }

    if (value is Map) {
      final json = Map<String, dynamic>.from(value);
      return DeviceContact(
        employeeNumber: _stringValue(json, const [
          'employee_number',
          'employeeNumber',
          'employee_id',
          'employeeId',
          'number',
          'id',
        ]),
      );
    }

    return const DeviceContact(employeeNumber: '');
  }
}

/// Device details and current assignment references returned by the API.
class Device {
  const Device({
    required this.tagNumber,
    required this.brand,
    required this.deviceType,
    required this.serialNumber,
    required this.status,
    required this.contacts,
  });

  /// Asset tag used for manual lookup and barcode scanning.
  final String tagNumber;

  /// Manufacturer or brand returned by iTop.
  final String brand;

  /// Device category, such as laptop or desktop.
  final String deviceType;

  /// Hardware serial number required by assignment endpoints.
  final String serialNumber;

  /// Current device lifecycle status.
  final String status;

  /// Contacts linked to this device.
  final List<DeviceContact> contacts;

  /// A device is assigned only when `contacts_list` has a usable employee.
  bool get isAssigned => assignedEmployeeNumber != null;

  /// Returns the first valid employee identifier from the contact list.
  String? get assignedEmployeeNumber {
    for (final contact in contacts) {
      final value = contact.employeeNumber.trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  /// Parses API fields while accepting common snake_case and camelCase names.
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      tagNumber: _stringValue(json, const [
        'tag_number',
        'tagNumber',
        'barcode',
        'asset_tag',
        'assetTag',
      ]),
      brand: _stringValue(json, const ['brand', 'manufacturer', 'vendor']),
      deviceType: _stringValue(json, const [
        'device_type',
        'deviceType',
        'type',
        'class',
      ]),
      serialNumber: _stringValue(json, const [
        'serial_number',
        'serialNumber',
        'serial',
      ]),
      status: _stringValue(json, const ['status', 'status_name', 'state']),
      contacts: _parseContacts(
        json['contacts_list'] ?? json['contactsList'] ?? json['contacts'],
      ),
    );
  }

  /// Returns an updated device after assignment state changes locally.
  Device copyWith({String? status, List<DeviceContact>? contacts}) {
    return Device(
      tagNumber: tagNumber,
      brand: brand,
      deviceType: deviceType,
      serialNumber: serialNumber,
      status: status ?? this.status,
      contacts: contacts ?? this.contacts,
    );
  }

  /// A valid device must provide the identifiers needed by assignment calls.
  bool get isValid =>
      tagNumber.trim().isNotEmpty && serialNumber.trim().isNotEmpty;
}

/// Converts nullable or malformed contact payloads into a safe list.
List<DeviceContact> _parseContacts(Object? value) {
  Object? contacts = value;
  if (contacts is Map) {
    contacts = contacts['items'] ?? contacts['values'] ?? contacts['data'];
  }

  if (contacts is! List) {
    return const [];
  }

  return contacts
      .map(DeviceContact.fromDynamic)
      .where((contact) => contact.employeeNumber.isNotEmpty)
      .toList(growable: false);
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
