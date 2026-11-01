/// Conversion and validation between Flutter's [Locale] and [LocaleTag].
///
/// Hand-rolled rather than delegating to `Intl.canonicalizedLocale`, because
/// that function reads process-global state when handed a null and this package
/// must never touch it. Nothing here imports `package:intl`.
library;

import 'dart:ui' show Locale;

import '../errors.dart';
import '../ids.dart';

final RegExp _separator = RegExp('[_-]');
final RegExp _alpha = RegExp(r'^[a-zA-Z]+$');
final RegExp _digits = RegExp(r'^[0-9]+$');

/// The undetermined locale, used where a value is deliberately language-neutral.
const LocaleTag undeterminedLocale = LocaleTag('und');

/// Builds a canonical tag from a Flutter [locale].
///
/// Assembled from the parts rather than parsed from `toString`, so a locale
/// carrying a script survives the trip intact.
LocaleTag localeTagOf(Locale locale) {
  final StringBuffer buffer = StringBuffer(locale.languageCode.toLowerCase());
  final String? script = locale.scriptCode;
  if (script != null && script.isNotEmpty) {
    buffer.write('_${_titleCase(script)}');
  }
  final String? region = locale.countryCode;
  if (region != null && region.isNotEmpty) {
    buffer.write('_${region.toUpperCase()}');
  }
  return LocaleTag(buffer.toString());
}

/// Rebuilds a Flutter [Locale] from a canonical [tag].
Locale localeOf(LocaleTag tag) {
  final List<String> parts = tag.value.split('_');
  return Locale.fromSubtags(
    languageCode: parts.first,
    scriptCode: parts.length > 1 && parts[1].length == 4 ? parts[1] : null,
    countryCode: parts.length > 1 && parts.last.length != 4 ? parts.last : null,
  );
}

/// Canonicalises [raw] if it is shaped like a locale tag, else returns null.
///
/// The language subtag is restricted to 2-3 letters rather than BCP-47's 2-8.
/// That matters because a map whose keys are all locale tags is how this package
/// recognises a variant map, and `[a-z]{2,8}` matches `title`, `name` and
/// `label` — so the looser grammar would decode a host object as a catalogue of
/// nonsense locales. The cost is the reconstructed languages and a handful of
/// Wikimedia-only codes, none of which appear in shipped content.
LocaleTag? tryParseLocaleTag(String raw) {
  if (raw.isEmpty) {
    return null;
  }
  final List<String> parts = raw.split(_separator);
  if (parts.length > 3 || parts.any((String p) => p.isEmpty)) {
    return null;
  }

  final String language = parts.first.toLowerCase();
  if (language == 'und') {
    return parts.length == 1 ? undeterminedLocale : null;
  }
  if (language.length < 2 ||
      language.length > 3 ||
      !_alpha.hasMatch(language)) {
    return null;
  }

  int index = 1;
  String? script;
  if (index < parts.length &&
      parts[index].length == 4 &&
      _alpha.hasMatch(parts[index])) {
    script = _titleCase(parts[index]);
    index++;
  }

  String? region;
  if (index < parts.length) {
    final String candidate = parts[index];
    if (candidate.length == 2 && _alpha.hasMatch(candidate)) {
      region = candidate.toUpperCase();
    } else if (candidate.length == 3 && _digits.hasMatch(candidate)) {
      region = candidate;
    } else {
      return null;
    }
    index++;
  }

  if (index != parts.length) {
    return null;
  }

  final StringBuffer buffer = StringBuffer(language);
  if (script != null) {
    buffer.write('_$script');
  }
  if (region != null) {
    buffer.write('_$region');
  }
  return LocaleTag(buffer.toString());
}

/// Canonicalises [raw], throwing [LocaleTagFormatException] if it cannot.
LocaleTag parseLocaleTag(String raw) {
  final LocaleTag? tag = tryParseLocaleTag(raw);
  if (tag == null) {
    throw LocaleTagFormatException(
      raw,
      '"$raw" is not a locale tag. Expected a 2-3 letter language, optionally '
      'followed by a 4-letter script and a 2-letter or 3-digit region, for '
      'example "cs", "cs_CZ" or "zh_Hant_TW".',
    );
  }
  return tag;
}

/// Whether [raw] is shaped like a locale tag.
///
/// Used to tell a per-locale variant map apart from an ordinary JSON object.
bool isLocaleTagShaped(String raw) => tryParseLocaleTag(raw) != null;

String _titleCase(String value) =>
    value[0].toUpperCase() + value.substring(1).toLowerCase();
