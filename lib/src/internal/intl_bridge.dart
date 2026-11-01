/// The only file in this package that imports `package:intl`.
///
/// Funnelling every call through one file is what makes two guarantees
/// auditable: that a locale is always passed explicitly, and that
/// `Intl.defaultLocale` -- process-global state shared with the host and every
/// other package -- is never written.
library;

import 'package:intl/intl.dart';
import 'package:intl/message_format.dart';

import '../ids.dart';

/// Caps on the memo caches.
///
/// Patterns usually come from a fixed set of records, but content can be
/// user-generated and unbounded. Clearing wholesale on overflow is cruder than
/// an LRU and much simpler to reason about; the caches refill in microseconds.
const int _cacheLimit = 512;

final Map<String, String> _localeCache = <String, String>{};
final Map<(String, String), MessageFormat> _formatCache =
    <(String, String), MessageFormat>{};
final Map<(String, String), NumberFormat> _numberCache =
    <(String, String), NumberFormat>{};
final Map<(String, String), DateFormat> _dateCache =
    <(String, String), DateFormat>{};

/// A locale string `intl` will accept, degrading rather than throwing.
///
/// `intl` throws from inside the `MessageFormat` constructor for a locale it
/// does not know, which would turn an unusual locale into a crash during
/// `build`. Falling back to the language subtag and finally to English keeps
/// rendering a string.
String intlLocaleFor(LocaleTag tag) => _localeCache.putIfAbsent(tag.value, () {
  for (final String candidate in <String>[
    tag.value,
    tag.value.split('_').first,
  ]) {
    try {
      NumberFormat.decimalPattern(candidate);
      return candidate;
    } on Object {
      continue;
    }
  }
  return 'en';
});

/// Formats [pattern] for [locale] with already-prepared [args].
///
/// The pattern must have been validated by the scanner first: `intl` signals a
/// malformed pattern with an `AssertionError`, which release builds strip.
String formatMessage(
  String pattern,
  LocaleTag locale,
  Map<String, Object> args,
) {
  final String intlLocale = intlLocaleFor(locale);
  if (_formatCache.length >= _cacheLimit) {
    _formatCache.clear();
  }
  final MessageFormat format = _formatCache.putIfAbsent((
    pattern,
    intlLocale,
  ), () => MessageFormat(pattern, locale: intlLocale));
  return format.format(args);
}

/// Formats [value] for [locale] using the locale's own grouping and decimals.
///
/// `intl` formats `#` inside a plural but leaves a bare `{n}` as `toString`, so
/// without this `1234567.5` would render identically in every language.
String formatNumber(num value, LocaleTag locale) {
  final String intlLocale = intlLocaleFor(locale);
  if (_numberCache.length >= _cacheLimit) {
    _numberCache.clear();
  }
  return _numberCache
      .putIfAbsent((
        'decimal',
        intlLocale,
      ), () => NumberFormat.decimalPattern(intlLocale))
      .format(value);
}

/// Formats [value] for [locale] with the medium date skeleton.
///
/// Guarded by try/catch rather than by `DateFormat.localeExists`, because that
/// check is itself unsafe: it reads `dateTimeSymbols`, which is an
/// `UninitializedLocaleData` that *throws* for any locale but `en_US` until
/// something calls `initializeDateFormatting`. In an application
/// `GlobalMaterialLocalizations` does that; in a bare unit test nothing does.
/// Falling back to `en_US` -- the one locale compiled in -- is the difference
/// between a readable date and an exception escaping from inside `build`.
String formatDate(DateTime value, LocaleTag locale) {
  final String intlLocale = intlLocaleFor(locale);
  if (_dateCache.length >= _cacheLimit) {
    _dateCache.clear();
  }
  final DateFormat? cached = _dateCache[('yMMMd', intlLocale)];
  if (cached != null) {
    return cached.format(value);
  }
  try {
    final DateFormat format = DateFormat.yMMMd(intlLocale);
    final String result = format.format(value);
    _dateCache[('yMMMd', intlLocale)] = format;
    return result;
  } on Object {
    return DateFormat.yMMMd('en_US').format(value);
  }
}

/// Empties the memo caches. For tests that assert on cache behaviour.
void resetIntlCaches() {
  _localeCache.clear();
  _formatCache.clear();
  _numberCache.clear();
  _dateCache.clear();
}
