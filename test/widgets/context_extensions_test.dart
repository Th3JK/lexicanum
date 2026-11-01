import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lexicanum/lexicanum.dart';
import 'package:lexicanum/lexicanum_testing.dart';

final LocalizedText items = LocalizedText.values(<String, String>{
  'cs': '{n, plural, one{{n} položka} few{{n} položky} other{{n} položek}}',
  'en': '{n, plural, one{{n} item} other{{n} items}}',
});

Widget _app({
  required Widget child,
  Locale? locale,
  KeyLookup Function(BuildContext)? lookupBuilder,
}) => MaterialApp(
  locale: locale,
  supportedLocales: const <Locale>[Locale('en'), Locale('cs')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: LexiconScope(lookupBuilder: lookupBuilder, child: child),
);

void main() {
  testWidgets('content renders for the locale Flutter resolved', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _app(
        locale: const Locale('cs'),
        child: Builder(
          builder: (BuildContext context) => Text(
            items.of(
              context,
              args: const MessageArgs(<String, Object?>{'n': 3}),
            ),
          ),
        ),
      ),
    );
    expect(find.text('3 položky'), findsOneWidget);
  });

  testWidgets('changing MaterialApp.locale re-renders every value', (
    WidgetTester tester,
  ) async {
    // This package contributes no notification code at all: Localizations
    // rebuilds, and everything that read the locale rebuilds with it.
    Widget build(Locale locale) => _app(
      locale: locale,
      child: Builder(
        builder: (BuildContext context) => Text(
          items.of(context, args: const MessageArgs(<String, Object?>{'n': 3})),
        ),
      ),
    );

    await tester.pumpWidget(build(const Locale('cs')));
    expect(find.text('3 položky'), findsOneWidget);

    await tester.pumpWidget(build(const Locale('en')));
    await tester.pump();
    expect(find.text('3 items'), findsOneWidget);
    expect(find.text('3 položky'), findsNothing);
  });

  testWidgets('the more specific extension wins for LocalizedText', (
    WidgetTester tester,
  ) async {
    // LocalizedText is a subtype of Localized<MessagePattern>, and both carry
    // an `of`. Dart picks the more specific extension, so this is a String.
    await tester.pumpWidget(
      _app(
        locale: const Locale('en'),
        child: Builder(
          builder: (BuildContext context) {
            final String rendered = items.of(
              context,
              args: const MessageArgs(<String, Object?>{'n': 1}),
            );
            return Text(rendered);
          },
        ),
      ),
    );
    expect(find.text('1 item'), findsOneWidget);
  });

  testWidgets('a generic container resolves to its payload type', (
    WidgetTester tester,
  ) async {
    final LocalizedImage hero = LocalizedImage.values(<String, ImageData>{
      'cs': ImageData(source: Uri.parse('cs.png'), alt: 'Kočka'),
      'en': ImageData(source: Uri.parse('en.png'), alt: 'A cat'),
    });
    await tester.pumpWidget(
      _app(
        locale: const Locale('cs'),
        child: Builder(
          builder: (BuildContext context) =>
              Text(hero.ofOrNull(context)?.alt ?? '-'),
        ),
      ),
    );
    expect(find.text('Kočka'), findsOneWidget);
  });

  group('keys', () {
    const KeyedText welcome = KeyedText(MessageKey('welcomeTitle'));

    testWidgets('resolve through the scope lookup', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _app(
          locale: const Locale('cs'),
          lookupBuilder: (BuildContext context) => mapKeyLookup(
            <String, String>{'welcomeTitle': 'Vítejte'},
            locale: context.activeLocale,
          ),
          child: Builder(
            builder: (BuildContext context) => Text(welcome.of(context)),
          ),
        ),
      );
      expect(find.text('Vítejte'), findsOneWidget);
    });

    testWidgets('render the key itself when there is no scope at all', (
      WidgetTester tester,
    ) async {
      // The scope is optional; without one a key is legible rather than a
      // crash, which is the whole argument for keyAsText being the default.
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const <Locale>[Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Builder(
            builder: (BuildContext context) => Text(welcome.of(context)),
          ),
        ),
      );
      expect(find.text('welcomeTitle'), findsOneWidget);
    });
  });

  testWidgets('context.activeLocale reports what Flutter resolved', (
    WidgetTester tester,
  ) async {
    late Locale seen;
    await tester.pumpWidget(
      _app(
        locale: const Locale('cs'),
        child: Builder(
          builder: (BuildContext context) {
            seen = context.activeLocale;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(seen.languageCode, 'cs');
  });
}
