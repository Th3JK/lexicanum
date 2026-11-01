/// A host value type and a host subclass, so both extension stories are
/// exercised by the suite rather than only by the README.
library;

import 'dart:ui' show Locale;

import 'package:lexicanum/lexicanum.dart';

/// A host domain type that lexicanum knows nothing about.
enum Badge {
  /// Top tier.
  gold,

  /// Second tier.
  silver;

  /// Reads a badge from JSON. A static method, so the codec stays const.
  static Badge fromJson(Object? json) =>
      Badge.values.firstWhere((Badge b) => b.name == json);

  /// Writes a badge to JSON.
  static Object? encode(Badge value) => value.name;
}

/// The composition story: no subclass, just a codec.
const LocalizedValueCodec<Badge> badgeCodec = LocalizedValueCodec<Badge>(
  fromJson: Badge.fromJson,
  toJson: Badge.encode,
);

/// The subclassing story: resolution semantics this package does not ship.
///
/// Picks by region alone, ignoring language entirely -- a market, not a
/// translation. It overrides only [resolveOrNull]; everything else, including
/// the throwing path and JSON, is inherited.
final class MarketBadge extends Localized<Badge> {
  /// Creates a market-keyed badge.
  const MarketBadge(this.variants, {this.fallback});

  @override
  final Map<LocaleTag, Badge> variants;

  @override
  final FallbackPolicy? fallback;

  @override
  LocalizedValueCodec<Badge> get codec => badgeCodec;

  @override
  Badge? resolveOrNull(Locale locale, {FallbackPolicy? policy}) {
    final String? region = locale.countryCode;
    if (region == null) {
      return null;
    }
    for (final MapEntry<LocaleTag, Badge> entry in variants.entries) {
      if (entry.key.value.endsWith('_$region')) {
        return entry.value;
      }
    }
    return null;
  }
}
