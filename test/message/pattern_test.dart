import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lexicanum/lexicanum.dart';

String _fmt(
  String pattern,
  Locale locale, [
  Map<String, Object?> args = const <String, Object?>{},
]) => MessagePattern(pattern).format(locale, args: MessageArgs(args));

void main() {
  group('plurals', () {
    const String items =
        '{n, plural, one{{n} položka} few{{n} položky} other{{n} položek}}';

    test('Czech selects one, few and many-as-other', () {
      // The case that motivates having a message layer at all: a map of
      // strings cannot express this, and English-only pluralisation gets it
      // wrong for every Slavic language.
      expect(
        _fmt(items, const Locale('cs'), <String, Object?>{'n': 1}),
        '1 položka',
      );
      expect(
        _fmt(items, const Locale('cs'), <String, Object?>{'n': 3}),
        '3 položky',
      );
      expect(
        _fmt(items, const Locale('cs'), <String, Object?>{'n': 5}),
        '5 položek',
      );
    });

    test('Arabic reaches all six categories', () {
      const String ar =
          '{n, plural, zero{zero} one{one} two{two} '
          'few{few} many{many} other{other}}';
      const Map<int, String> expected = <int, String>{
        0: 'zero',
        1: 'one',
        2: 'two',
        3: 'few',
        11: 'many',
        100: 'other',
      };
      expected.forEach((int n, String category) {
        expect(
          _fmt(ar, const Locale('ar'), <String, Object?>{'n': n}),
          category,
          reason: 'n = $n',
        );
      });
    });

    test('an exact value beats the category rule', () {
      const String p = '{n, plural, =0{nothing} one{one} other{# things}}';
      expect(_fmt(p, const Locale('en'), <String, Object?>{'n': 0}), 'nothing');
    });

    test('offset subtracts before # renders', () {
      const String p =
          '{n, plural, offset:1 '
          '=0{no one} one{you and 1 other} other{you and # others}}';
      expect(
        _fmt(p, const Locale('en'), <String, Object?>{'n': 3}),
        'you and 2 others',
      );
    });

    test('an unknown locale degrades instead of throwing', () {
      // intl throws Invalid locale from inside the MessageFormat constructor;
      // rendering something is always better than crashing in build.
      expect(
        _fmt(items, const Locale('xx'), <String, Object?>{'n': 1}),
        contains('položka'),
      );
    });
  });

  group('select', () {
    const String p = '{g, select, female{She} male{He} other{They}}';

    test('picks a named branch', () {
      expect(
        _fmt(p, const Locale('en'), <String, Object?>{'g': 'female'}),
        'She',
      );
    });

    test('falls through to other for an unknown value', () {
      expect(_fmt(p, const Locale('en'), <String, Object?>{'g': 'x'}), 'They');
    });
  });

  group('number formatting', () {
    test('a bare placeholder is locale-formatted, not stringified', () {
      // intl formats # inside a plural but leaves {n} as toString, so without
      // the preparation step this would read 1234567 in every language.
      final String en = _fmt('{n}', const Locale('en'), <String, Object?>{
        'n': 1234567,
      });
      final String cs = _fmt('{n}', const Locale('cs'), <String, Object?>{
        'n': 1234567,
      });
      expect(en, '1,234,567');
      expect(cs, isNot('1234567'));
      expect(cs, isNot(en));
    });

    test('a plural count stays numeric so selection still works', () {
      // If the count were pre-formatted to a string, category selection and #
      // would both break. This asserts it did not happen.
      expect(
        _fmt(
          '{n, plural, one{one} other{#}}',
          const Locale('en'),
          <String, Object?>{'n': 1234567},
        ),
        '1,234,567',
      );
    });

    test('a numeric string is coerced for a count', () {
      expect(
        _fmt(
          '{n, plural, one{one} other{many}}',
          const Locale('en'),
          <String, Object?>{'n': '1'},
        ),
        'one',
      );
    });
  });

  group('dates', () {
    final DateTime when = DateTime.utc(2026, 9, 15);

    test('a DateTime argument is formatted, not stringified', () {
      final String out = _fmt('Due {d}', const Locale('en'), <String, Object?>{
        'd': when,
      });
      expect(out, isNot(contains('00:00:00')));
      expect(out, contains('2026'));
    });

    test('an uninitialised locale falls back rather than throwing', () {
      // DateFormat reads dateTimeSymbols, which throws for anything but en_US
      // until initializeDateFormatting runs. An app gets that from
      // GlobalMaterialLocalizations; a bare unit test gets nothing, and an
      // exception escaping from build would be the worst possible outcome.
      expect(
        () => _fmt('Due {d}', const Locale('cs'), <String, Object?>{'d': when}),
        returnsNormally,
      );
    });

    test('once initialised the locale is honoured', () async {
      await initializeDateFormatting('cs');
      resetIntlCaches();
      // Czech yMMMd is numeric -- "15. 9. 2026" -- so the proof that the
      // locale was honoured is that it differs from the English rendering,
      // not that it contains a month name.
      final String cs = _fmt('Due {d}', const Locale('cs'), <String, Object?>{
        'd': when,
      });
      final String en = _fmt('Due {d}', const Locale('en'), <String, Object?>{
        'd': when,
      });
      expect(cs, contains('2026'));
      expect(cs, isNot(en));
    });
  });

  group('missing and extra arguments', () {
    test('a missing argument renders its own name, visibly', () {
      // intl would render "Undefined parameter - name", which reads like a
      // crash report. The braces read like unfinished content, which is what
      // it is, and they survive a screenshot.
      expect(_fmt('Hi {name}', const Locale('en')), 'Hi {name}');
    });

    test('a missing count does not throw', () {
      expect(
        _fmt('{n, plural, one{one} other{other}}', const Locale('en')),
        'other',
      );
    });

    test('extra arguments are ignored', () {
      // Passing one args map to many strings is the normal pattern; warning
      // about it would train people to ignore warnings.
      expect(
        _fmt('Hi {name}', const Locale('en'), <String, Object?>{
          'name': 'Jan',
          'unused': 1,
        }),
        'Hi Jan',
      );
    });
  });

  group('literals and quoting', () {
    test('a plain pattern is returned verbatim', () {
      expect(_fmt('Ahoj', const Locale('cs')), 'Ahoj');
    });

    test("ICU's own quoting example round-trips", () {
      expect(
        _fmt("This '{isn''t}' obvious", const Locale('en')),
        "This {isn't} obvious",
      );
    });

    test('a value containing braces does not re-enter the parser', () {
      expect(
        _fmt('{a}', const Locale('en'), <String, Object?>{'a': '{b}'}),
        '{b}',
      );
    });
  });

  group('the value itself', () {
    test('info is computed once per distinct source', () {
      const MessagePattern a = MessagePattern('Hi {name}');
      const MessagePattern b = MessagePattern('Hi {name}');
      expect(identical(a.info, b.info), isTrue);
    });

    test('isValid reports without throwing', () {
      expect(const MessagePattern('{n, plural, other{x}}').isValid, isTrue);
      expect(const MessagePattern('{n, plural, one{x}}').isValid, isFalse);
    });

    test('an invalid pattern throws only when used', () {
      const MessagePattern bad = MessagePattern('{d, date, yMMMd}');
      expect(
        () => bad.format(const Locale('en')),
        throwsA(isA<MessagePatternException>()),
      );
    });

    test('equality and const-ness are by source', () {
      expect(const MessagePattern('a'), const MessagePattern('a'));
      expect(const MessagePattern('a'), isNot(const MessagePattern('b')));
    });
  });
}
