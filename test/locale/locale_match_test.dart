import 'package:flutter_test/flutter_test.dart';
import 'package:lexicanum/lexicanum.dart';

Set<LocaleTag> _tags(List<String> values) => values.map(LocaleTag.new).toSet();

void main() {
  group('ladderFor', () {
    test('a bare language is its own ladder', () {
      expect(ladderFor(const LocaleTag('cs')), <LocaleTag>[
        const LocaleTag('cs'),
      ]);
    });

    test('a region truncates to the language', () {
      expect(ladderFor(const LocaleTag('cs_CZ')), <LocaleTag>[
        const LocaleTag('cs_CZ'),
        const LocaleTag('cs'),
      ]);
    });

    test('script is tried before region', () {
      // Matching Flutter's own match priority: a shared script is a closer
      // match than a shared region, because it is what the reader can read.
      expect(ladderFor(const LocaleTag('zh_Hant_TW')), <LocaleTag>[
        const LocaleTag('zh_Hant_TW'),
        const LocaleTag('zh_Hant'),
        const LocaleTag('zh_TW'),
        const LocaleTag('zh'),
      ]);
    });
  });

  group('chainFor', () {
    test('cs_CZ falls back to cs', () {
      expect(
        chainFor(
          const LocaleTag('cs_CZ'),
          available: _tags(<String>['cs', 'en']),
        ),
        <LocaleTag>[const LocaleTag('cs'), const LocaleTag('en')],
      );
    });

    test('an exact hit still appends the tail', () {
      expect(
        chainFor(const LocaleTag('cs'), available: _tags(<String>['cs', 'en'])),
        <LocaleTag>[const LocaleTag('cs'), const LocaleTag('en')],
      );
    });

    test('is intersected with what is available', () {
      expect(
        chainFor(
          const LocaleTag('pt_BR'),
          available: _tags(<String>['en', 'cs']),
        ),
        <LocaleTag>[const LocaleTag('en')],
      );
    });

    test('zh_Hant_TW reaches zh_Hant before the tail', () {
      expect(
        chainFor(
          const LocaleTag('zh_Hant_TW'),
          available: _tags(<String>['en', 'zh_Hant']),
        ),
        <LocaleTag>[const LocaleTag('zh_Hant'), const LocaleTag('en')],
      );
    });

    test('is deduplicated when the tail repeats a ladder entry', () {
      expect(
        chainFor(const LocaleTag('en_GB'), available: _tags(<String>['en'])),
        <LocaleTag>[const LocaleTag('en')],
      );
    });

    test('FallbackPolicy.none stops at truncation', () {
      expect(
        chainFor(
          const LocaleTag('pt_BR'),
          available: _tags(<String>['en', 'cs']),
          policy: FallbackPolicy.none,
        ),
        isEmpty,
      );
    });

    test('useAnyAvailable appends the rest deterministically', () {
      expect(
        chainFor(
          const LocaleTag('pt'),
          available: _tags(<String>['ja', 'cs', 'de']),
          policy: const FallbackPolicy(
            tail: <LocaleTag>[],
            useAnyAvailable: true,
          ),
        ),
        <LocaleTag>[
          const LocaleTag('cs'),
          const LocaleTag('de'),
          const LocaleTag('ja'),
        ],
      );
    });

    test('returns an unmodifiable list', () {
      final List<LocaleTag> chain = chainFor(
        const LocaleTag('cs'),
        available: _tags(<String>['cs']),
      );
      expect(() => chain.add(const LocaleTag('en')), throwsUnsupportedError);
    });
  });
}
