/// The JSON currency this package trades in.
///
/// Deliberately the same spelling administratum uses, so a value encoded here
/// drops into a `CollectionSpec` without a cast or an adapter.
library;

import '../errors.dart';

/// A decoded JSON object.
typedef Json = Map<String, Object?>;

/// Reads a required [Uri] field, failing with the path rather than a cast error.
Uri requireUri(Json json, String field, String path) {
  final Object? value = json[field];
  if (value is! String) {
    throw LexicanumFormatException(
      '$path.$field',
      '$path.$field: expected a URI string, found ${value.runtimeType}.',
    );
  }
  final Uri? parsed = Uri.tryParse(value);
  if (parsed == null) {
    throw LexicanumFormatException(
      '$path.$field',
      '$path.$field: "$value" is not a URI.',
    );
  }
  return parsed;
}

/// Reads an optional int field.
int? optionalInt(Json json, String field, String path) {
  final Object? value = json[field];
  if (value == null) {
    return null;
  }
  if (value is! num) {
    throw LexicanumFormatException(
      '$path.$field',
      '$path.$field: expected a number, found ${value.runtimeType}.',
    );
  }
  return value.toInt();
}

/// Reads an optional string field.
String? optionalString(Json json, String field, String path) {
  final Object? value = json[field];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw LexicanumFormatException(
      '$path.$field',
      '$path.$field: expected a string, found ${value.runtimeType}.',
    );
  }
  return value;
}

/// Reads an optional duration, stored as whole milliseconds.
Duration? optionalDuration(Json json, String field, String path) {
  final int? millis = optionalInt(json, field, path);
  return millis == null ? null : Duration(milliseconds: millis);
}

/// Requires [value] to be a JSON object, naming [path] when it is not.
Json requireObject(Object? value, String path) {
  if (value is! Json) {
    throw LexicanumFormatException(
      path,
      '$path: expected an object, found ${value.runtimeType}.',
    );
  }
  return value;
}

/// Drops null-valued entries, so optional fields do not litter the output.
Json compact(Json json) => <String, Object?>{
  for (final MapEntry<String, Object?> e in json.entries)
    if (e.value != null) e.key: e.value,
};

/// Requires [value] to be a JSON list, naming [path] when it is not.
List<Object?> requireList(Object? value, String path) {
  if (value is! List<Object?>) {
    throw LexicanumFormatException(
      path,
      '$path: expected a list, found ${value.runtimeType}.',
    );
  }
  return value;
}
