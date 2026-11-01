/// Architecture tests.
///
/// These enforce boundaries the compiler cannot see. Nothing but this file
/// stops the package growing a dependency that would break its whole premise,
/// so it reads the source off disk rather than trusting anyone to remember.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Strips comments, so a rule about code is not tripped by prose about it.
///
/// Doc comments here talk about BuildContext and administratum deliberately --
/// explaining a boundary is not crossing it.
String stripComments(String source) {
  final String withoutBlocks = source.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
  return withoutBlocks
      .split('\n')
      .where((String line) => !line.trimLeft().startsWith('//'))
      .join('\n');
}

/// Every Dart file under `lib/`, as (path, source) pairs.
List<(String, String)> _libSources() {
  final Directory lib = Directory('lib');
  return lib
      .listSync(recursive: true)
      .whereType<File>()
      .where((File f) => f.path.endsWith('.dart'))
      .map((File f) => (f.path, stripComments(f.readAsStringSync())))
      .toList(growable: false);
}

void main() {
  late List<(String, String)> sources;

  setUpAll(() {
    sources = _libSources();
    expect(sources, isNotEmpty, reason: 'lib/ should contain Dart files');
  });

  test('lib never depends on administratum', () {
    // Compatibility with administratum is achieved by being plain JSON values,
    // not by depending on it. The moment this fails, "works standalone" is a
    // claim rather than a fact. Prose mentions are fine and in fact wanted --
    // it is the package: URI that would be a lie.
    for (final (String path, String source) in sources) {
      expect(source.contains('package:administratum'), isFalse, reason: path);
    }
  });

  test('lib never depends on drift', () {
    // The README documents a TypeConverter the host writes; the package ships
    // no drift code and takes no drift dependency.
    for (final (String path, String source) in sources) {
      expect(source.contains('package:drift'), isFalse, reason: path);
    }
  });

  test('only intl_bridge.dart imports package:intl', () {
    // Every intl call passes an explicit locale. Funnelling them through one
    // file is what makes that auditable, and what keeps Intl.defaultLocale --
    // which is process-global and shared with the host -- untouched.
    for (final (String path, String source) in sources) {
      if (path.endsWith('intl_bridge.dart')) {
        continue;
      }
      expect(
        source.contains('package:intl/'),
        isFalse,
        reason: '$path should reach intl through internal/intl_bridge.dart',
      );
    }
  });

  test('lib never imports package:intl/src', () {
    // plural_rules.dart lives under src/. Importing it is an
    // implementation_imports violation and means hand-driving the global state
    // that Intl.pluralLogic already sequences correctly.
    for (final (String path, String source) in sources) {
      expect(source.contains('package:intl/src/'), isFalse, reason: path);
    }
  });

  _layeringTests(() => sources);
}

/// The layering rule: localization is a presentation concern, so the domain
/// half of this package must never see a BuildContext.
void _layeringTests(List<(String, String)> Function() sources) {
  test('BuildContext appears only under lib/src/widgets', () {
    // resolve(Locale) is the domain API. A repository or model that had to
    // reach for a BuildContext to read its own data would have the layering
    // upside down, and nothing but this test enforces that.
    for (final (String path, String source) in sources()) {
      if (path.contains('widgets/')) {
        continue;
      }
      expect(
        source.contains('BuildContext'),
        isFalse,
        reason: '$path should take a Locale, not a BuildContext',
      );
    }
  });

  test('no member named `locale` is declared on BuildContext', () {
    // That name belongs to the host's extension over its generated
    // AppLocalizations -- context.locale.welcomeTitle. Two extensions
    // declaring the same member on one type are ambiguous at every call site,
    // so claiming it here would silently break every consumer.
    final RegExp onContext = RegExp(
      r'extension\s+\w+\s+on\s+BuildContext\s*\{([\s\S]*?)\n\}',
    );
    final RegExp declaresLocale = RegExp(
      r'\b(get|set)\s+locale\b|\blocale\s*\(',
    );
    for (final (String path, String source) in sources()) {
      for (final RegExpMatch match in onContext.allMatches(source)) {
        expect(
          declaresLocale.hasMatch(match.group(1)!),
          isFalse,
          reason: '$path declares `locale` on BuildContext',
        );
      }
    }
  });
}
