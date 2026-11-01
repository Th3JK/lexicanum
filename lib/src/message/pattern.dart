/// An ICU message pattern, as a value.
library;

import 'dart:ui' show Locale;

import 'package:meta/meta.dart';

import '../ids.dart';
import '../internal/intl_bridge.dart' as intl;
import '../locale/locale_conversion.dart';
import 'args.dart';
import 'scanner.dart';

final Map<String, PatternInfo> _infoCache = <String, PatternInfo>{};

/// The pattern text of a translatable message.
///
/// Holds the source verbatim and parses on first use, so a record carrying five
/// locales does not scan five patterns when one of them is rendered. That also
/// keeps the type `const`-constructible, which is what lets content be declared
/// as a literal in Dart as well as loaded from a row.
///
/// The syntax is ICU MessageFormat -- the same thing you write in an `.arb`
/// file -- so a translator's tools already understand it and there is one
/// syntax in the system rather than two.
@immutable
final class MessagePattern {
  /// Creates a pattern from its ICU [source]. Not validated until used.
  const MessagePattern(this.source);

  /// The ICU pattern, verbatim. Never re-serialised, so round trips are exact.
  final String source;

  /// What the pattern needs, computed once per distinct source.
  ///
  /// Throws [MessagePatternException] if the pattern cannot be used. Reach for
  /// this at decode time to fail early, or let [format] trigger it lazily.
  PatternInfo get info {
    if (_infoCache.length >= 512) {
      _infoCache.clear();
    }
    return _infoCache.putIfAbsent(source, () => scanPattern(source));
  }

  /// Whether the pattern is valid, without throwing.
  bool get isValid {
    try {
      info;
      return true;
    } on Object {
      return false;
    }
  }

  /// Renders the message for [locale].
  ///
  /// Numeric and [DateTime] arguments are formatted for the locale rather than
  /// stringified, because `intl` does that only for `#` inside a plural -- a
  /// bare `{n}` would otherwise read `1234567` in every language. A plural's
  /// count argument is deliberately left numeric, since category selection and
  /// `#` both depend on it.
  ///
  /// A missing argument renders as its own name in braces rather than throwing:
  /// visible and attributable from a screenshot, but never a blank screen.
  String format(Locale locale, {MessageArgs args = const MessageArgs.empty()}) {
    final PatternInfo pattern = info;
    final LocaleTag tag = localeTagOf(locale);

    if (pattern.isPlain && !source.contains("'") && !source.contains('{')) {
      return source;
    }

    final Map<String, Object> prepared = <String, Object>{};
    for (final ArgName name in pattern.placeholders) {
      prepared[name.value] = _prepare(name, args, pattern, tag);
    }
    return intl.formatMessage(source, tag, prepared);
  }

  Object _prepare(
    ArgName name,
    MessageArgs args,
    PatternInfo pattern,
    LocaleTag tag,
  ) {
    final Object? value = args[name];
    final bool isCount = pattern.counts.contains(name);

    if (value == null) {
      // MessageFormat inserts argument values through a placeholder and
      // substitutes at the end, so braces in a value are safe to pass.
      return isCount ? 0 : '{${name.value}}';
    }
    if (isCount) {
      return _asNumber(value) ?? 0;
    }
    if (value is num) {
      return intl.formatNumber(value, tag);
    }
    if (value is DateTime) {
      return intl.formatDate(value, tag);
    }
    return value;
  }

  static num? _asNumber(Object value) => switch (value) {
    final num n => n,
    final String s => num.tryParse(s),
    _ => null,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessagePattern && other.source == source;

  @override
  int get hashCode => source.hashCode;

  @override
  String toString() =>
      'MessagePattern(${source.length > 40 //
              ? '${source.substring(0, 40)}...' : source})';
}
