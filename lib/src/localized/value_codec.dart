/// How a value type crosses the JSON boundary.
library;

import 'package:meta/meta.dart';

/// Reads and writes one value type inside a [Localized] container.
///
/// A bundle of functions rather than an interface, following administratum's
/// `CollectionSpec`: a host adds support for its own type by passing two
/// function references, not by declaring a class. Pass static methods or
/// top-level functions and the whole codec is a constant expression, which is
/// what lets a container built from it stay `const`; a closure is not.
@immutable
final class LocalizedValueCodec<T> {
  /// Creates a codec.
  const LocalizedValueCodec({required this.fromJson, required this.toJson});

  /// Builds a value from its JSON form. May throw; the caller reports the path.
  final T Function(Object? json) fromJson;

  /// Writes a value to its JSON form.
  final Object? Function(T value) toJson;
}

/// Codec for plain strings, which need no conversion at all.
const LocalizedValueCodec<String> stringCodec = LocalizedValueCodec<String>(
  fromJson: _stringFromJson,
  toJson: _stringToJson,
);

/// Codec for [Uri], stored as its string form.
const LocalizedValueCodec<Uri> uriCodec = LocalizedValueCodec<Uri>(
  fromJson: _uriFromJson,
  toJson: _uriToJson,
);

String _stringFromJson(Object? json) => json! as String;
Object? _stringToJson(String value) => value;

Uri _uriFromJson(Object? json) => Uri.parse(json! as String);
Object? _uriToJson(Uri value) => value.toString();
