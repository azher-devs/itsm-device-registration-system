// Models for the shared iTop REST/JSON response envelope.

/// One object inside the top-level iTop `objects` map.
class ItopObject {
  const ItopObject({
    required this.code,
    required this.message,
    required this.className,
    required this.key,
    required this.fields,
  });

  final int code;
  final String message;
  final String className;
  final String key;
  final Map<String, dynamic> fields;

  /// Maps the documented object wrapper without depending on its map key.
  factory ItopObject.fromJson(Map<String, dynamic> json) {
    return ItopObject(
      code: _intValue(json['code']),
      message: _textValue(json['message']),
      className: _textValue(json['class']),
      key: _textValue(json['key']),
      fields: json['fields'] is Map
          ? Map<String, dynamic>.from(json['fields'] as Map)
          : const {},
    );
  }
}

/// Top-level response returned by every documented iTop operation.
class ItopResponse {
  const ItopResponse({
    required this.code,
    required this.message,
    required this.objects,
  });

  final int code;
  final String message;
  final Map<String, ItopObject> objects;

  bool get isSuccess => code == 0;

  ItopObject? get firstObject => objects.isEmpty ? null : objects.values.first;

  /// Parses the common `code`, `message`, and `objects` response structure.
  factory ItopResponse.fromJson(Map<String, dynamic> json) {
    final rawObjects = json['objects'];
    final objects = <String, ItopObject>{};
    if (rawObjects is Map) {
      for (final entry in rawObjects.entries) {
        if (entry.value is Map) {
          objects[entry.key.toString()] = ItopObject.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }
    }

    return ItopResponse(
      code: _intValue(json['code']),
      message: _textValue(json['message']),
      objects: objects,
    );
  }
}

int _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? -1;
}

String _textValue(Object? value) => value?.toString().trim() ?? '';
