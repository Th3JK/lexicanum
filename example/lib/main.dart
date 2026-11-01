import 'package:flutter/material.dart';
import 'package:lexicanum/lexicanum.dart';

import 'l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// The two extensions a host writes. Lexicanum cannot ship them: AppLocalizations
// is generated in this app, so the package cannot name the type.
// ---------------------------------------------------------------------------

/// Turns `AppLocalizations.of(context)!.welcomeTitle` into
/// `context.locale.welcomeTitle`.
///
/// No `!` because l10n.yaml sets `nullable-getter: false`. Lexicanum
/// deliberately never declares `locale` on BuildContext, so this name is free.
extension LocaleContext on BuildContext {
  /// The generated localizations for this subtree.
  AppLocalizations get locale => AppLocalizations.of(this);
}

/// Key-based lookup over the compiled catalogue.
///
/// gen-l10n emits only typed members -- `String get welcomeTitle;` and
/// `String itemCount(int n);` -- with no map and no `operator []`, and a Dart
/// extension cannot reflect over them. So this switch is the one piece of
/// per-key work, and it is what lets a database row store `'welcomeTitle'` and
/// still render in every language the app ships.
extension AppLocalizationsLexicon on AppLocalizations {
  /// Renders the catalogue entry for [key], or null when there is none.
  String? lookup(String key, [MessageArgs args = const MessageArgs.empty()]) =>
      switch (key) {
        'welcomeTitle' => welcomeTitle,
        'itemCount' => itemCount(
          (args[const ArgName('n')] as num? ?? 0).toInt(),
        ),
        _ => null,
      };
}

// ---------------------------------------------------------------------------
// Content: translations that travel with the record, not in the catalogue.
// ---------------------------------------------------------------------------

/// A product as it would arrive from a database row or a CMS.
final class Product {
  const Product({required this.name, required this.hero});

  /// Reads a product from JSON -- exactly what an administratum
  /// `CollectionSpec.fromJson` or a drift `TypeConverter` would call.
  factory Product.fromJson(Json json) => Product(
    name: LocalizedText.fromJson(json['name'], r'$.name'),
    hero: LocalizedImage.fromJson(json['hero'], r'$.hero'),
  );

  final LocalizedText name;
  final LocalizedImage hero;
}

final Product _product = Product.fromJson(<String, Object?>{
  'name': <String, Object?>{'en': 'Apple', 'cs': 'Jablko'},
  'hero': <String, Object?>{
    'en': <String, Object?>{'source': 'apple_en.png', 'alt': 'A red apple'},
    'cs': <String, Object?>{'source': 'apple_cs.png', 'alt': 'Červené jablko'},
  },
});

/// A key stored in content, resolved against the compiled catalogue.
const KeyedText _basketLabel = KeyedText(MessageKey('itemCount'));

void main() => runApp(const ExampleApp());

/// The example application.
class ExampleApp extends StatefulWidget {
  /// Creates the example.
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  Locale _locale = const Locale('en');

  @override
  Widget build(BuildContext context) => MaterialApp(
    locale: _locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: LexiconScope(
      // The scope's only job is handing lexicanum the catalogue lookup.
      lookupBuilder: (BuildContext context) => context.locale.lookup,
      child: _HomePage(
        onToggleLocale: () => setState(() {
          _locale = _locale.languageCode == 'en'
              ? const Locale('cs')
              : const Locale('en');
        }),
      ),
    ),
  );
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.onToggleLocale});

  final VoidCallback onToggleLocale;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.locale.welcomeTitle)),
    body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Chrome: typed, compile-checked, owned by gen-l10n.
        Text(context.locale.itemCount(3)),

        // A key stored in data, resolved through the same catalogue.
        Text(
          _basketLabel.of(
            context,
            args: const MessageArgs(<String, Object?>{'n': 3}),
          ),
        ),

        // Content: translations carried by the record itself.
        Text(_product.name.of(context)),
        Text(_product.hero.ofOrNull(context)?.alt ?? ''),

        TextButton(
          onPressed: onToggleLocale,
          child: const Text('Switch language'),
        ),
      ],
    ),
  );
}
