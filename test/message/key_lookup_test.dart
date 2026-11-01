import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:lexicanum/lexicanum.dart';
import 'package:lexicanum/lexicanum_testing.dart';

void main() {
  const Locale cs = Locale('cs');
  final KeyLookup catalogue = mapKeyLookup(<String, String>{
    'welcomeTitle': 'Vítejte',
    'itemCount':
        '{n, plural, one{{n} položka} few{{n} položky} other{{n} položek}}',
  }, locale: cs);

  group('resolving a stored key', () {
    test('renders a plain entry', () {
      expect(
        const KeyedText(MessageKey('welcomeTitle')).resolve(catalogue, cs),
        'Vítejte',
      );
    });

    test('passes arguments through to the catalogue entry', () {
      // The host's generated method does the formatting; this only proves the
      // arguments survive the trip.
      expect(
        const KeyedText(MessageKey('itemCount')).resolve(
          catalogue,
          cs,
          args: const MessageArgs(<String, Object?>{'n': 3}),
        ),
        '3 položky',
      );
    });
  });

  group('when the catalogue has no entry', () {
    const KeyedText absent = KeyedText(MessageKey('nope'));

    test('resolveOrNull returns null', () {
      expect(absent.resolveOrNull(catalogue, cs), isNull);
    });

    test('the default policy renders the key, legibly and reportably', () {
      expect(absent.resolve(catalogue, cs), 'nope');
    });

    test('empty renders nothing', () {
      expect(
        absent.resolve(catalogue, cs, onMissing: MissingKeyPolicy.empty),
        '',
      );
    });

    test('throwError names the key and the ways out', () {
      expect(
        () => absent.resolve(
          catalogue,
          cs,
          onMissing: MissingKeyPolicy.throwError,
        ),
        throwsA(
          isA<MissingMessageKey>()
              .having((MissingMessageKey e) => e.key, 'key', 'nope')
              .having(
                (MissingMessageKey e) => e.message,
                'message',
                allOf(contains('.arb'), contains('fallback')),
              ),
        ),
      );
    });

    test('an inline fallback wins over the policy', () {
      // Matters most for a key added by a client newer than the catalogue it
      // is running against: the content carries its own answer.
      final KeyedText withFallback = KeyedText(
        const MessageKey('nope'),
        fallback: LocalizedText.values(<String, String>{'cs': 'Náhrada'}),
      );
      expect(withFallback.resolve(catalogue, cs), 'Náhrada');
    });
  });

  group('JSON', () {
    test('a bare key is a bare string', () {
      expect(const KeyedText(MessageKey('a')).toJson(), 'a');
      expect(KeyedText.fromJson('a'), const KeyedText(MessageKey('a')));
    });

    test('a key with a fallback round-trips as an object', () {
      final KeyedText original = KeyedText(
        const MessageKey('a'),
        fallback: LocalizedText.values(<String, String>{'en': 'A'}),
      );
      expect(KeyedText.fromJson(original.toJson()), original);
    });

    test('a malformed value names what was expected', () {
      expect(
        () => KeyedText.fromJson(42),
        throwsA(
          isA<LexicanumFormatException>().having(
            (LexicanumFormatException e) => e.message,
            'message',
            contains('catalogue key'),
          ),
        ),
      );
    });
  });
}
