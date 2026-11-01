import 'package:flutter_test/flutter_test.dart';
import 'package:lexicanum/lexicanum.dart';

PatternInfo _scan(String p) => scanPattern(p);

Matcher _rejects(Object matcher) => throwsA(
  isA<MessagePatternException>().having(
    (MessagePatternException e) => e.message,
    'message',
    matcher,
  ),
);

void main() {
  group('plain text', () {
    test('a pattern with nothing to substitute is plain', () {
      expect(_scan('Ahoj').isPlain, isTrue);
      expect(_scan('Ahoj').placeholders, isEmpty);
    });

    test('an empty pattern is legal', () {
      expect(_scan('').isPlain, isTrue);
    });
  });

  group('placeholders', () {
    test('collects simple placeholders', () {
      expect(_scan('Hello {name}, you are {age}').placeholders, <ArgName>{
        const ArgName('name'),
        const ArgName('age'),
      });
    });

    test('collects placeholders nested inside branches', () {
      // Nested collection is what lets a host assert its argument map matches
      // the content without rendering it first.
      final PatternInfo info = _scan(
        '{n, plural, one{{who} and one other} other{{who} and # others}}',
      );
      expect(info.placeholders, <ArgName>{
        const ArgName('n'),
        const ArgName('who'),
      });
      expect(info.counts, <ArgName>{const ArgName('n')});
    });

    test('a select argument is a placeholder but not a count', () {
      final PatternInfo info = _scan('{g, select, female{She} other{They}}');
      expect(info.placeholders, <ArgName>{const ArgName('g')});
      expect(info.counts, isEmpty);
    });
  });

  group('quoting', () {
    test('a quoted brace is not an argument', () {
      expect(_scan("This '{isn''t}' an argument").placeholders, isEmpty);
    });

    test('a bare apostrophe is literal', () {
      expect(_scan("it's fine {name}").placeholders, <ArgName>{
        const ArgName('name'),
      });
    });

    test('an unterminated quoted literal is rejected', () {
      expect(_scan, isNotNull);
      expect(
        () => _scan("open '{ forever"),
        _rejects(contains('Unterminated')),
      );
    });
  });

  group('rejections', () {
    test('selectordinal is rejected rather than rendering 2th', () {
      // intl accepts this and resolves it with cardinal rules. Verified:
      // en gives 1st, 2th, 3th, 4th. Rejecting beats shipping that.
      expect(
        () => _scan('{n, selectordinal, one{#st} other{#th}}'),
        _rejects(allOf(contains('selectordinal'), contains('2th'))),
      );
    });

    test('an argument type is rejected, naming what intl would have done', () {
      // intl reads this as a placeholder *named* "d, date, yMMMd" and renders
      // "Undefined parameter - d, date, yMMMd". Silent, and worse than an error.
      expect(
        () => _scan('{d, date, yMMMd}'),
        _rejects(contains('not supported')),
      );
    });

    test('a plural with no other branch is rejected', () {
      // intl fails this with an AssertionError, which release builds strip.
      expect(
        () => _scan('{n, plural, one{x}}'),
        _rejects(allOf(contains('other'), contains('AssertionError'))),
      );
    });

    test('a select with no other branch is rejected', () {
      expect(
        () => _scan('{g, select, female{She}}'),
        _rejects(contains('other')),
      );
    });

    test('an unknown plural branch is rejected', () {
      expect(
        () => _scan('{n, plural, lots{many} other{x}}'),
        _rejects(contains('Unknown plural branch "lots"')),
      );
    });

    test('a duplicated branch is rejected', () {
      expect(
        () => _scan('{n, plural, one{a} one{b} other{c}}'),
        _rejects(contains('twice')),
      );
    });

    test('an unmatched brace is rejected on both sides', () {
      expect(() => _scan('{n, plural, other{x}'), _rejects(contains('"{"')));
      expect(() => _scan('closing } alone'), _rejects(contains('"}"')));
    });

    test('an empty argument name is rejected', () {
      expect(() => _scan('{}'), _rejects(contains('argument name')));
    });

    test('offset with no number is rejected', () {
      expect(
        () => _scan('{n, plural, offset: one{a} other{b}}'),
        _rejects(contains('offset:')),
      );
    });
  });

  group('accepted shapes', () {
    test('exact values and offset parse', () {
      final PatternInfo info = _scan(
        '{n, plural, offset:1 =0{none} =1{one} one{# other} other{# others}}',
      );
      expect(info.counts, <ArgName>{const ArgName('n')});
    });

    test('branches may nest arbitrarily', () {
      final PatternInfo info = _scan(
        '{a, select, x{{b, plural, one{{c}} other{#}}} other{-}}',
      );
      expect(info.placeholders, <ArgName>{
        const ArgName('a'),
        const ArgName('b'),
        const ArgName('c'),
      });
      expect(info.counts, <ArgName>{const ArgName('b')});
    });

    test('whitespace between branches is tolerated', () {
      expect(_scan('{n, plural,\n  one {a}\n  other {b}\n}').counts, <ArgName>{
        const ArgName('n'),
      });
    });
  });
}
