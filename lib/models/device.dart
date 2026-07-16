// Device domain model mapped from documented iTop PhysicalDevice fields.

import 'itop_response.dart';

/// Contact reference returned in a PhysicalDevice `contacts_list`.
class DeviceContact {
  const DeviceContact({this.contactId = '', this.employeeNumber = ''});

  /// iTop Person key used to create and delete assignment links.
  final String contactId;

  /// Employee number resolved through the required second Person lookup.
  final String employeeNumber;

  /// Maps the documented contact row, which contains a contact ID but no employee number.
  factory DeviceContact.fromJson(Map<String, dynamic> json) {
    return DeviceContact(
      contactId: _stringValue(json, const ['contact_id', 'contactId', 'id']),
      employeeNumber: _stringValue(json, const [
        'employee_number',
        'employeeNumber',
      ]),
    );
  }

  DeviceContact copyWith({String? employeeNumber}) {
    return DeviceContact(
      contactId: contactId,
      employeeNumber: employeeNumber ?? this.employeeNumber,
    );
  }
}

/// Physical device details used by registration and assignment workflows.
class Device {
  const Device({
    required this.tagNumber,
    required this.brand,
    required this.deviceType,
    required this.serialNumber,
    required this.status,
    required this.contacts,
    this.itopKey = '',
    this.itopClass = 'PhysicalDevice',
    this.assetNumber = '',
    this.model = '',
    this.description = '',
  });

  /// iTop object key used by create, delete, and rename operations.
  final String itopKey;

  /// Concrete iTop class returned by search, such as `PC`.
  final String itopClass;

  /// Application Tag Number mapped exclusively from the iTop `name` field.
  final String tagNumber;

  /// Optional inventory number retained separately from Tag Number.
  final String assetNumber;

  /// Brand friendly name returned by iTop.
  final String brand;

  /// Concrete device class used by the existing Device Type UI.
  final String deviceType;

  /// Model friendly name returned by iTop.
  final String model;

  final String serialNumber;
  final String status;
  final String description;
  final List<DeviceContact> contacts;

  bool get isAssigned => assignedEmployeeNumber != null;

  String? get assignedEmployeeNumber {
    for (final contact in contacts) {
      if (contact.employeeNumber.trim().isNotEmpty) {
        return contact.employeeNumber.trim();
      }
    }
    return null;
  }

  String? get assignedContactId {
    for (final contact in contacts) {
      if (contact.contactId.trim().isNotEmpty) {
        return contact.contactId.trim();
      }
    }
    return null;
  }

  /// Maps a documented iTop object and optionally resolved contacts.
  factory Device.fromItopObject(
    ItopObject object, {
    List<DeviceContact>? contacts,
  }) {
    final fields = object.fields;
    return Device(
      itopKey: object.key,
      itopClass: object.className,
      tagNumber: _stringValue(fields, const ['name']),
      serialNumber: _stringValue(fields, const ['serialnumber']),
      assetNumber: _stringValue(fields, const ['asset_number']),
      status: _stringValue(fields, const ['status']),
      brand: _stringValue(fields, const ['brand_id_friendlyname']),
      model: _stringValue(fields, const ['model_id_friendlyname']),
      description: _stringValue(fields, const ['description']),
      deviceType: object.className,
      contacts: contacts ?? _parseContacts(fields['contacts_list']),
    );
  }

  /// Compatibility mapper that still gives `name` priority over legacy keys.
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      itopKey: _stringValue(json, const ['key', 'id']),
      itopClass: _stringValue(json, const ['class']),
      tagNumber: _stringValue(json, const ['name', 'tag_number', 'tagNumber']),
      serialNumber: _stringValue(json, const [
        'serialnumber',
        'serial_number',
        'serialNumber',
      ]),
      assetNumber: _stringValue(json, const ['asset_number']),
      status: _stringValue(json, const ['status']),
      brand: _stringValue(json, const ['brand_id_friendlyname', 'brand']),
      model: _stringValue(json, const ['model_id_friendlyname', 'model']),
      description: _stringValue(json, const ['description']),
      deviceType: _stringValue(json, const ['class', 'device_type', 'type']),
      contacts: _parseContacts(json['contacts_list']),
    );
  }

  Device copyWith({
    String? tagNumber,
    String? status,
    List<DeviceContact>? contacts,
  }) {
    return Device(
      itopKey: itopKey,
      itopClass: itopClass,
      tagNumber: tagNumber ?? this.tagNumber,
      assetNumber: assetNumber,
      brand: brand,
      deviceType: deviceType,
      model: model,
      serialNumber: serialNumber,
      status: status ?? this.status,
      description: description,
      contacts: contacts ?? this.contacts,
    );
  }

  bool get isValid => tagNumber.trim().isNotEmpty && itopKey.trim().isNotEmpty;
}

List<DeviceContact> _parseContacts(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value
      .whereType<Map>()
      .map((item) => DeviceContact.fromJson(Map<String, dynamic>.from(item)))
      .where((contact) => contact.contactId.isNotEmpty)
      .toList(growable: false);
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
