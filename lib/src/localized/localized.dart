/// The spine of the package: per-locale variants of any value.
library;

import 'dart:ui' show Locale;

import 'package:meta/meta.dart';

import '../errors.dart';
import '../ids.dart';
import '../internal/equality.dart';
import '../internal/json.dart';
import '../locale/fallback_policy.dart';
import '../locale/locale_conversion.dart';
import '../locale/locale_match.dart' as match;
import 'value_codec.dart';

/// Per-locale variants of a value, with a fallback chain.
///
/// A host model declares `Localized<Uri> promoVideo` where it would otherwise
/// declare `Uri promoVideo`, and the translations travel with the record rather
/// than living in a catalogue keyed off it. The value round-trips through JSON
/// unchanged, so it drops into an administratum `CollectionSpec` or a drift
/// `TypeConverter` the host writes -- this package depends on neither.
///
/// `base` rather than `interface` is deliberate: a subclass must `extends`, and
/// so inherits [resolveOrNull]'s chain walk instead of reimplementing it. The
/// cost is that the modifier is viral -- a subtype must itself be `base`,
/// `final` or `sealed`, and nobody can `implements Localized`, so a test double
/// has to be a real subclass.
///
/// Resolution takes a plain [Locale], never a `BuildContext`: this type belongs
/// to the domain layer, and which locale to render is a presentation decision
/// made above it.
@immutable
abstract base class Localized<T> {
  /// Const superclass constructor.
  const Localized();

  /// Per-locale variants keyed by canonical tag, canonicalising [values].
  ///
  /// Not `const`, because canonicalising and validating the keys is work. Use
  /// [Localized.tagged] where a compile-time constant is wanted.
  factory Localized.values(
    Map<String, T> values, {
    required LocalizedValueCodec<T> codec,
    FallbackPolicy? fallback,
  }) {
    final Map<LocaleTag, T> tagged = <LocaleTag, T>{
      for (final MapEntry<String, T> entry in values.entries)
        parseLocaleTag(entry.key): entry.value,
    };
    return MapLocalized<T>(tagged, codec: codec, fallback: fallback);
  }

  /// Per-locale variants that are already canonical tags.
  ///
  /// Const-constructible when the map literal is const and [codec] is a
  /// constant expression -- which it is for a codec built from static method or
  /// top-level function tear-offs, and is not for one built from a closure.
  const factory Localized.tagged(
    Map<LocaleTag, T> variants, {
    required LocalizedValueCodec<T> codec,
    FallbackPolicy? fallback,
  }) = MapLocalized<T>;

  /// The variants, keyed by canonical locale tag.
  Map<LocaleTag, T> get variants;

  /// How this value crosses the JSON boundary.
  LocalizedValueCodec<T> get codec;

  /// A policy pinned to this value, overriding whatever the caller passes.
  ///
  /// Null means "whatever the caller asks for", which is almost always right.
  /// Pinning is for a value that genuinely must not fall back -- a legal notice
  /// that may only appear in the language it was approved in.
  FallbackPolicy? get fallback;

  /// The locales this value can serve, most specific first, for [locale].
  ///
  /// Exposed because a caller that got null from [resolveOrNull] usually wants
  /// to report what was tried, and because it is the seam a subclass overrides
  /// to change matching without touching the rest.
  List<LocaleTag> chainFor(Locale locale, {FallbackPolicy? policy}) =>
      match.chainFor(
        localeTagOf(locale),
        available: variants.keys.toSet(),
        policy: fallback ?? policy ?? const FallbackPolicy(),
      );

  /// The best variant for [locale], or null when the chain runs out.
  ///
  /// Never throws. This is the resolution path for anything that would rather
  /// render nothing than fail.
  T? resolveOrNull(Locale locale, {FallbackPolicy? policy}) {
    for (final LocaleTag tag in chainFor(locale, policy: policy)) {
      final T? value = variants[tag];
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  /// The best variant for [locale], throwing when the chain runs out.
  ///
  /// Throws [MissingLocalizedValue] naming what was requested and what was
  /// tried, because there is no universally sensible stand-in for an arbitrary
  /// `T`. Subclasses over a type that has a neutral value may override this.
  T resolve(Locale locale, {FallbackPolicy? policy}) {
    final T? value = resolveOrNull(locale, policy: policy);
    if (value != null) {
      return value;
    }
    final List<LocaleTag> tried = chainFor(locale, policy: policy);
    final LocaleTag requested = localeTagOf(locale);
    throw MissingLocalizedValue(
      requested.value,
      tried.map((LocaleTag t) => t.value).toList(growable: false),
      'No value for "${requested.value}". Tried ${tried.isEmpty ? 'nothing' : //
            tried.map((LocaleTag t) => t.value).join(', ')}; the value has '
      '${variants.keys.map((LocaleTag t) => t.value).join(', ')}. Add a '
      'variant, widen the FallbackPolicy, or call resolveOrNull instead.',
    );
  }

  /// Writes the variants as a locale-keyed JSON object.
  Json toJson() => <String, Object?>{
    for (final MapEntry<LocaleTag, T> entry in variants.entries)
      entry.key.value: codec.toJson(entry.value),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Localized<T> &&
          other.runtimeType == runtimeType &&
          mapEq.equals(other.variants, variants) &&
          other.fallback == fallback;

  /// Equality covers the variants and the pinned policy, but deliberately not
  /// the codec: the codec is machinery for crossing the JSON boundary, not part
  /// of the value, and two closures that behave identically are never equal.
  @override
  int get hashCode => Object.hash(runtimeType, mapEq.hash(variants), fallback);

  @override
  String toString() =>
      '$runtimeType(${variants.keys.map((LocaleTag t) => t.value).join(', ')})';
}

/// The plain per-locale map, and the target of both public constructors.
///
/// Public so that `Localized.tagged` can redirect to it -- a const factory must
/// name its target -- but there is no reason to write it directly.
final class MapLocalized<T> extends Localized<T> {
  /// Creates a container over already-canonical [variants].
  const MapLocalized(this.variants, {required this.codec, this.fallback});

  @override
  final Map<LocaleTag, T> variants;

  @override
  final LocalizedValueCodec<T> codec;

  @override
  final FallbackPolicy? fallback;
}

/// Decodes a locale-keyed JSON object into a container.
///
/// Every key must be a locale tag; a key that is not is a decode error naming
/// the offender, because silently accepting one would mean a host object that
/// happened to land here became a catalogue of nonsense locales.
Localized<T> decodeLocalized<T>(
  Object? json,
  LocalizedValueCodec<T> codec, {
  String path = r'$',
  FallbackPolicy? fallback,
}) {
  if (json is! Map<String, Object?>) {
    throw LexicanumFormatException(
      path,
      '$path: expected a locale-keyed object, found ${json.runtimeType}.',
    );
  }
  if (json.isEmpty) {
    throw LexicanumFormatException(
      path,
      '$path: empty object. A variant map needs at least one locale key.',
    );
  }

  final Map<LocaleTag, T> variants = <LocaleTag, T>{};
  for (final MapEntry<String, Object?> entry in json.entries) {
    final LocaleTag? tag = tryParseLocaleTag(entry.key);
    if (tag == null) {
      throw LexicanumFormatException(
        '$path.${entry.key}',
        '$path: "${entry.key}" is not a locale tag, so this is not a variant '
            'map. Locale keys look like "cs", "cs_CZ" or "zh_Hant_TW".',
      );
    }
    variants[tag] = codec.fromJson(entry.value);
  }
  return MapLocalized<T>(variants, codec: codec, fallback: fallback);
}
