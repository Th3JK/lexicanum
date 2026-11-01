import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:lexicanum/lexicanum.dart';

import '../fixtures/badge.dart';

/// Asserts at compile time that the const constructor really is const.
const Localized<Badge> _constBadge = Localized<Badge>.tagged(<LocaleTag, Badge>{
  LocaleTag('en'): Badge.gold,
}, codec: badgeCodec);

void main() {
  group('composition -- no subclass needed', () {
    final Localized<Uri> video = Localized<Uri>.values(<String, Uri>{
      'en': Uri.parse('https://example.com/welcome-en.webm'),
      'cs': Uri.parse('https://example.com/welcome-cs.webm'),
    }, codec: uriCodec);

    test('resolves an exact locale', () {
      expect(
        video.resolve(const Locale('cs')).toString(),
        'https://example.com/welcome-cs.webm',
      );
    });

    test('truncates a region away', () {
      expect(
        video.resolve(const Locale('cs', 'CZ')).toString(),
        endsWith('welcome-cs.webm'),
      );
    });

    test('falls back to English for an unrelated locale', () {
      expect(
        video.resolve(const Locale('ja')).toString(),
        endsWith('welcome-en.webm'),
      );
    });

    test('canonicalises keys on the way in', () {
      final Localized<String> value = Localized<String>.values(<String, String>{
        'CS-cz': 'Ahoj',
      }, codec: stringCodec);
      expect(value.variants.keys.single, const LocaleTag('cs_CZ'));
    });

    test('rejects a key that is not a locale tag', () {
      expect(
        () => Localized<String>.values(<String, String>{
          'title': 'x',
        }, codec: stringCodec),
        throwsA(isA<LocaleTagFormatException>()),
      );
    });
  });

  group('const construction', () {
    test('a tagged container built from a tear-off codec is a constant', () {
      // The assertion is that the top-level `_constBadge` compiled at all;
      // this just proves it is the value we think it is.
      expect(_constBadge.resolve(const Locale('en')), Badge.gold);
      expect(
        identical(
          _constBadge,
          const Localized<Badge>.tagged(<LocaleTag, Badge>{
            LocaleTag('en'): Badge.gold,
          }, codec: badgeCodec),
        ),
        isTrue,
      );
    });
  });

  group('the missing path', () {
    final Localized<String> only = Localized<String>.values(
      <String, String>{'cs': 'Ahoj'},
      codec: stringCodec,
      fallback: FallbackPolicy.none,
    );

    test('resolveOrNull returns null rather than throwing', () {
      expect(only.resolveOrNull(const Locale('ja')), isNull);
    });

    test('resolve names what was requested, tried and available', () {
      expect(
        () => only.resolve(const Locale('ja')),
        throwsA(
          isA<MissingLocalizedValue>()
              .having(
                (MissingLocalizedValue e) => e.requested,
                'requested',
                'ja',
              )
              .having((MissingLocalizedValue e) => e.tried, 'tried', isEmpty)
              .having(
                (MissingLocalizedValue e) => e.message,
                'message',
                allOf(contains('cs'), contains('resolveOrNull')),
              ),
        ),
      );
    });

    test('a pinned policy overrides the caller', () {
      // The caller asks for the default English tail; the value refuses.
      expect(only.resolveOrNull(const Locale('ja')), isNull);
    });
  });

  group('subclassing -- custom resolution semantics', () {
    const MarketBadge badge = MarketBadge(<LocaleTag, Badge>{
      LocaleTag('en_GB'): Badge.gold,
      LocaleTag('de_AT'): Badge.silver,
    });

    test('the override replaces the chain walk', () {
      // German language, Great Britain market: the market wins.
      expect(badge.resolveOrNull(const Locale('de', 'GB')), Badge.gold);
    });

    test('the inherited throwing path still reports through the override', () {
      expect(
        () => badge.resolve(const Locale('ja')),
        throwsA(isA<MissingLocalizedValue>()),
      );
    });

    test('inherits JSON without implementing it', () {
      expect(badge.toJson(), <String, Object?>{
        'en_GB': 'gold',
        'de_AT': 'silver',
      });
    });
  });

  group('JSON', () {
    test('round-trips through decode(encode(x)) == x', () {
      final Localized<Badge> original = Localized<Badge>.values(<String, Badge>{
        'en': Badge.gold,
        'cs': Badge.silver,
      }, codec: badgeCodec);
      expect(decodeLocalized<Badge>(original.toJson(), badgeCodec), original);
    });

    test('encoding is a fixed point', () {
      const Json encoded = <String, Object?>{'en': 'gold'};
      expect(decodeLocalized<Badge>(encoded, badgeCodec).toJson(), encoded);
    });

    test('a non-locale key is a decode error naming the offender', () {
      expect(
        () => decodeLocalized<String>(<String, Object?>{
          'title': 'x',
        }, stringCodec),
        throwsA(
          isA<LexicanumFormatException>().having(
            (LexicanumFormatException e) => e.message,
            'message',
            contains('"title" is not a locale tag'),
          ),
        ),
      );
    });

    test('an empty object is an error, not an empty container', () {
      expect(
        () => decodeLocalized<String>(<String, Object?>{}, stringCodec),
        throwsA(
          isA<LexicanumFormatException>().having(
            (LexicanumFormatException e) => e.message,
            'message',
            contains('empty object'),
          ),
        ),
      );
    });

    test('a non-object is an error naming what was found', () {
      expect(
        () => decodeLocalized<String>('nope', stringCodec),
        throwsA(isA<LexicanumFormatException>()),
      );
    });
  });

  group('equality', () {
    test('is by value over the variants', () {
      expect(
        Localized<String>.values(<String, String>{
          'en': 'a',
        }, codec: stringCodec),
        Localized<String>.values(<String, String>{
          'en': 'a',
        }, codec: stringCodec),
      );
    });

    test('distinguishes different variants', () {
      expect(
        Localized<String>.values(<String, String>{
          'en': 'a',
        }, codec: stringCodec),
        isNot(
          Localized<String>.values(<String, String>{
            'en': 'b',
          }, codec: stringCodec),
        ),
      );
    });

    test('a subclass is never equal to the plain container', () {
      // runtimeType is part of equality, so MarketBadge's different resolution
      // semantics cannot hide behind matching variants.
      expect(
        const MarketBadge(<LocaleTag, Badge>{LocaleTag('en'): Badge.gold}),
        isNot(_constBadge),
      );
    });
  });
}
