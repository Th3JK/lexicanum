/// Everything this package throws on purpose.
///
/// Sealed so a host can switch exhaustively over the failure modes, and so
/// adding one is a visible change rather than a surprise at a call site.
library;

import 'package:meta/meta.dart';

/// Base class for every deliberate failure in this package.
@immutable
sealed class LexicanumException implements Exception {
  /// Const superclass constructor.
  const LexicanumException(this.message);

  /// Actionable prose naming what went wrong and how to fix it.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// A string that was meant to be a locale tag is not shaped like one.
final class LocaleTagFormatException extends LexicanumException {
  /// Creates the exception for [offending].
  const LocaleTagFormatException(this.offending, String message)
    : super(message);

  /// The text that failed to parse, verbatim.
  final String offending;
}

/// A [Localized] value had nothing to offer for the requested locale.
///
/// Thrown only by the non-nullable resolve path. There is no universally
/// sensible stand-in for an arbitrary `T`, so a caller that would rather cope
/// than crash asks for the nullable one.
final class MissingLocalizedValue extends LexicanumException {
  /// Creates the exception for a value that had no variant in [tried].
  const MissingLocalizedValue(this.requested, this.tried, String message)
    : super(message);

  /// The locale the caller asked for.
  final String requested;

  /// The locales that were actually attempted, in order.
  final List<String> tried;
}

/// JSON did not have the shape a decoder required.
final class LexicanumFormatException extends LexicanumException {
  /// Creates the exception, naming the JSON [path] that failed.
  const LexicanumFormatException(this.path, String message) : super(message);

  /// A dotted path to the offending node, for example `$.price.cs`.
  final String path;
}

/// An ICU message pattern could not be used.
///
/// Raised by the scanner before `intl` ever sees the pattern. That ordering is
/// deliberate: `intl`'s own failure for a malformed pattern is an
/// `AssertionError`, and assertions are stripped from release builds, so a bad
/// pattern that merely throws in debug would do something undefined in
/// production.
final class MessagePatternException extends LexicanumException {
  /// Creates the exception for [pattern], pointing at [offset].
  const MessagePatternException(this.pattern, this.offset, String message)
    : super(message);

  /// The pattern that failed, verbatim.
  final String pattern;

  /// Character offset into [pattern] where the problem starts.
  final int offset;

  /// The pattern with a caret under [offset], for an error message.
  String get excerpt => '$pattern\n${' ' * offset}^';
}

/// A catalogue key resolved to nothing, under the throwing missing-key policy.
final class MissingMessageKey extends LexicanumException {
  /// Creates the exception for [key].
  const MissingMessageKey(this.key, String message) : super(message);

  /// The key that was not found.
  final String key;
}
