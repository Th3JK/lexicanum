import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:lexicanum/lexicanum.dart';

import '../fixtures/character.dart';

Json _image(String id) => <String, Object?>{
  'id': id,
  'type': 'image',
  'title': <String, Object?>{'en': 'Hero', 'cs': 'Hrdina'},
  'image': <String, Object?>{
    'en': <String, Object?>{'source': 'hero_en.png', 'alt': 'A hero'},
    'cs': <String, Object?>{'source': 'hero_cs.png', 'alt': 'Hrdina'},
  },
};

Json _character(String id) => <String, Object?>{
  'id': id,
  'type': 'character',
  'portrait': <String, Object?>{
    'en': <String, Object?>{'source': 'p_en.png'},
  },
};

void main() {
  group('a repository stays type-agnostic', () {
    test('decodes a list containing a type this package never saw', () {
      // The whole point of the registry: the repository returns
      // List<ContentObject> and knows nothing about CharacterObject.
      final ContentRegistry registry = ContentRegistry()
        ..register('character', CharacterObject.fromJson);

      final List<ContentObject> items = registry.decodeAll(<Object?>[
        _image('hero'),
        _character('villain'),
      ]);

      expect(items, hasLength(2));
      expect(items.first, isA<ImageObject>());
      expect(items.last, isA<CharacterObject>());
      expect(items.map((ContentObject o) => o.type), <String>[
        'image',
        'character',
      ]);
    });

    test('a title reads uniformly across built-in and host types', () {
      // A gallery renders a list without a switch over every kind, which is
      // why title and description live on the interface.
      final ContentRegistry registry = ContentRegistry()
        ..register('character', CharacterObject.fromJson);
      final List<ContentObject> items = registry.decodeAll(<Object?>[
        _image('hero'),
        _character('v'),
      ]);
      expect(
        items.map(
          (ContentObject o) => o.title?.formatOrNull(const Locale('cs')),
        ),
        <String?>['Hrdina', null],
      );
    });
  });

  group('registration', () {
    test('rejects a reserved built-in type', () {
      expect(
        () => ContentRegistry().register('image', CharacterObject.fromJson),
        throwsA(
          isA<ArgumentError>().having(
            (ArgumentError e) => e.message,
            'message',
            contains('reserved'),
          ),
        ),
      );
    });

    test('rejects a duplicate registration', () {
      final ContentRegistry registry = ContentRegistry()
        ..register('character', CharacterObject.fromJson);
      expect(
        () => registry.register('character', CharacterObject.fromJson),
        throwsA(
          isA<ArgumentError>().having(
            (ArgumentError e) => e.message,
            'message',
            contains('already registered'),
          ),
        ),
      );
    });

    test('an empty registry lets a host own the vocabulary entirely', () {
      final ContentRegistry registry = ContentRegistry.empty()
        ..register('image', CharacterObject.fromJson);
      expect(registry.types, <String>{'image'});
    });
  });

  group('decode failures', () {
    test('an unknown type names what is registered', () {
      expect(
        () => ContentRegistry().decode(<String, Object?>{
          'id': 'a',
          'type': 'nope',
        }),
        throwsA(
          isA<LexicanumFormatException>().having(
            (LexicanumFormatException e) => e.message,
            'message',
            allOf(contains('"nope"'), contains('image'), contains('register')),
          ),
        ),
      );
    });

    test('a missing type field is reported as such', () {
      expect(
        () => ContentRegistry().decode(<String, Object?>{'id': 'a'}),
        throwsA(
          isA<LexicanumFormatException>().having(
            (LexicanumFormatException e) => e.message,
            'message',
            contains('"type"'),
          ),
        ),
      );
    });

    test('a failure in a list names the index', () {
      expect(
        () => ContentRegistry().decodeAll(<Object?>[
          _image('ok'),
          <String, Object?>{'id': 'b', 'type': 'nope'},
        ]),
        throwsA(
          isA<LexicanumFormatException>().having(
            (LexicanumFormatException e) => e.path,
            'path',
            contains('[1]'),
          ),
        ),
      );
    });

    test('a missing id names the field', () {
      expect(
        () => ContentRegistry().decode(<String, Object?>{'type': 'text'}),
        throwsA(
          isA<LexicanumFormatException>().having(
            (LexicanumFormatException e) => e.path,
            'path',
            endsWith('.id'),
          ),
        ),
      );
    });
  });

  group('round trip', () {
    test('built-in objects survive encode then decode', () {
      final ContentObject original = ContentRegistry().decode(_image('hero'));
      expect(ContentRegistry().decode(original.toJson()), original);
    });
  });
}
