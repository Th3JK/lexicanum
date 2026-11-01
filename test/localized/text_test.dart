import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:lexicanum/lexicanum.dart';

void main() {
  final LocalizedText items = LocalizedText.values(<String, String>{
    'cs': '{n, plural, one{{n} položka} few{{n} položky} other{{n} položek}}',
    'en': '{n, plural, one{{n} item} other{{n} items}}',
  });

  group('resolve and format in one step', () {
    test('picks the locale, then the plural category within it', () {
      // The reconciliation working: Localized<T> stays generic, and the
      // message layer still gets Czech grammar right inside the chosen variant.
      expect(
        items.format(
          const Locale('cs'),
          args: const MessageArgs(<String, Object?>{'n': 3}),
        ),
        '3 položky',
      );
      expect(
        items.format(
          const Locale('en'),
          args: const MessageArgs(<String, Object?>{'n': 3}),
        ),
        '3 items',
      );
    });

    test('a region truncates to the language before formatting', () {
      expect(
        items.format(
          const Locale('cs', 'CZ'),
          args: const MessageArgs(<String, Object?>{'n': 5}),
        ),
        '5 položek',
      );
    });

    test('grammar follows the requested locale, not the matched one', () {
      // Japanese falls back to the English variant, and the English variant
      // pluralises with English rules -- which is right, because the string
      // that was chosen is English.
      expect(
        items.format(
          const Locale('ja'),
          args: const MessageArgs(<String, Object?>{'n': 2}),
        ),
        '2 items',
      );
    });

    test('formatOrNull returns null instead of throwing', () {
      final LocalizedText pinned = LocalizedText.values(<String, String>{
        'cs': 'Ahoj',
      }, fallback: FallbackPolicy.none);
      expect(pinned.formatOrNull(const Locale('ja')), isNull);
      expect(
        () => pinned.format(const Locale('ja')),
        throwsA(isA<MissingLocalizedValue>()),
      );
    });
  });

  group('placeholders', () {
    test('are the union across variants', () {
      // The union, not the intersection: a caller that satisfies this set
      // satisfies every locale, which is what matters when the rendering
      // locale is not known where the arguments are assembled.
      final LocalizedText text = LocalizedText.values(<String, String>{
        'en': 'Hi {name}',
        'cs': 'Ahoj {name}, {count} zpráv',
      });
      expect(text.placeholders, <ArgName>{
        const ArgName('name'),
        const ArgName('count'),
      });
    });
  });

  group('validate', () {
    test('is empty for sound content', () {
      expect(items.validate(), isEmpty);
    });

    test('reports every malformed variant, not just the first', () {
      final LocalizedText broken = LocalizedText.values(<String, String>{
        'en': '{n, plural, one{x}}',
        'cs': '{d, date, yMMMd}',
        'de': 'fine',
      });
      final List<MessagePatternException> problems = broken.validate();
      expect(problems, hasLength(2));
      expect(
        problems.map((MessagePatternException e) => e.message).join(),
        allOf(contains('en:'), contains('cs:')),
      );
    });

    test('decoding stays lazy, so a bad variant does not break loading', () {
      // A record carrying five locales should not scan five patterns to be
      // read. The cost of that choice is that validation is opt-in.
      expect(
        () => LocalizedText.fromJson(<String, Object?>{
          'en': '{n, plural, one{x}}',
        }),
        returnsNormally,
      );
    });
  });

  group('JSON', () {
    test('round-trips, preserving the pattern verbatim', () {
      final Json encoded = items.toJson();
      expect(encoded['cs'], contains('položky'));
      expect(LocalizedText.fromJson(encoded), items);
    });

    test('a non-string variant is a decode error', () {
      expect(
        () => LocalizedText.fromJson(<String, Object?>{'en': 42}),
        throwsA(isA<LexicanumFormatException>()),
      );
    });
  });
}
