import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:lexicanum/lexicanum.dart';

void main() {
  group('localeTagOf', () {
    test('a bare language becomes a bare tag', () {
      expect(localeTagOf(const Locale('cs')), const LocaleTag('cs'));
    });

    test('a region is uppercased', () {
      expect(localeTagOf(const Locale('cs', 'cz')), const LocaleTag('cs_CZ'));
    });

    test('a script survives the trip', () {
      // Locale.toString would flatten this; assembling from the subtags is why
      // zh_Hant_TW does not silently become zh_TW.
      expect(
        localeTagOf(
          Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hant',
            countryCode: 'TW',
          ),
        ),
        const LocaleTag('zh_Hant_TW'),
      );
    });
  });

  group('localeOf', () {
    test('round-trips a language, script and region', () {
      final Locale locale = localeOf(const LocaleTag('zh_Hant_TW'));
      expect(locale.languageCode, 'zh');
      expect(locale.scriptCode, 'Hant');
      expect(locale.countryCode, 'TW');
    });

    test('round-trips a language and region with no script', () {
      final Locale locale = localeOf(const LocaleTag('cs_CZ'));
      expect(locale.scriptCode, isNull);
      expect(locale.countryCode, 'CZ');
    });
  });

  group('tryParseLocaleTag', () {
    test('canonicalises case and separators', () {
      expect(tryParseLocaleTag('CS-cz'), const LocaleTag('cs_CZ'));
      expect(tryParseLocaleTag('zh-hant-tw'), const LocaleTag('zh_Hant_TW'));
    });

    test('accepts a three-digit region', () {
      expect(tryParseLocaleTag('es_419'), const LocaleTag('es_419'));
    });

    test('accepts und but only on its own', () {
      expect(tryParseLocaleTag('und'), undeterminedLocale);
      expect(tryParseLocaleTag('und_CZ'), isNull);
    });

    test('rejects ordinary field names', () {
      // The whole variant-map rule rests on this: BCP-47 allows a 2-8 letter
      // language subtag, which would make every one of these a "locale".
      for (final String name in <String>['title', 'name', 'label', 'value']) {
        expect(tryParseLocaleTag(name), isNull, reason: name);
      }
    });

    test('rejects empty, over-long and malformed input', () {
      expect(tryParseLocaleTag(''), isNull);
      expect(tryParseLocaleTag('e'), isNull);
      expect(tryParseLocaleTag('cs_CZ_extra_more'), isNull);
      expect(tryParseLocaleTag('cs__CZ'), isNull);
      expect(tryParseLocaleTag('cs_C'), isNull);
      expect(tryParseLocaleTag('root'), isNull);
    });
  });

  group('parseLocaleTag', () {
    test('names the offending text and the expected shape', () {
      expect(
        () => parseLocaleTag('title'),
        throwsA(
          isA<LocaleTagFormatException>()
              .having(
                (LocaleTagFormatException e) => e.offending,
                'offending',
                'title',
              )
              .having(
                (LocaleTagFormatException e) => e.message,
                'message',
                contains('zh_Hant_TW'),
              ),
        ),
      );
    });
  });

  test('isLocaleTagShaped agrees with tryParseLocaleTag', () {
    expect(isLocaleTagShaped('cs_CZ'), isTrue);
    expect(isLocaleTagShaped('title'), isFalse);
  });
}
