/// Values substituted into an ICU pattern.
library;

import 'package:meta/meta.dart';

import '../ids.dart';
import '../internal/equality.dart';

/// The arguments a pattern interpolates.
///
/// A thin wrapper over a map rather than the map itself, so the package can
/// give actionable errors naming the placeholder and the expected type instead
/// of failing somewhere inside a cast.
@immutable
final class MessageArgs {
  /// Creates arguments from [values].
  const MessageArgs(this.values);

  /// No arguments at all.
  const MessageArgs.empty() : values = const <String, Object?>{};

  /// The raw values, keyed by placeholder name.
  final Map<String, Object?> values;

  /// Whether [name] was supplied with a non-null value.
  bool has(ArgName name) => values[name.value] != null;

  /// The raw value for [name], or null.
  Object? operator [](ArgName name) => values[name.value];

  /// Whether no arguments were supplied.
  bool get isEmpty => values.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageArgs && mapEq.equals(other.values, values);

  @override
  int get hashCode => mapEq.hash(values);

  @override
  String toString() => 'MessageArgs($values)';
}
