# lexicanum

**Localized generic data objects.** Hold per-locale variants of text, media or any value in an
immutable, JSON-round-trippable container; resolve them at the presentation boundary. Your domain
and repository objects stay free of `BuildContext`.

```dart
final class Product {
  const Product({required this.name, required this.hero});

  factory Product.fromJson(Json json) => Product(
        name: LocalizedText.fromJson(json['name']),
        hero: LocalizedImage.fromJson(json['hero']),
      );

  final LocalizedText name;   // translations travel with the record
  final LocalizedImage hero;  // so does the artwork
}

// in a widget
Text(product.name.of(context))
```

The JSON is exactly what you would want to write by hand:

```json
{
  "name": { "en": "Apple", "cs": "Jablko" },
  "hero": {
    "en": { "source": "apple_en.png", "alt": "A red apple" },
    "cs": { "source": "apple_cs.png", "alt": "Červené jablko" }
  }
}
```

## Why this exists

Flutter's gen-l10n pipeline handles strings you author at build time. It says nothing about a
product name from a database row, a locale-specific promo video, or a description from a CMS —
content whose translations have to travel **with the record**.

This package is that missing half, and only that half:

```
Repository → ContentObject → Localized<T> → resolve(locale) → BLoC / UI
```

The repository supplies the *variants*. The presentation layer decides which locale to resolve.
Nothing below `lib/src/widgets/` ever sees a `BuildContext` — enforced by a test, not a convention.

## It sits above gen-l10n, not beside it

**gen-l10n keeps full ownership of your catalogue.** This package reads no `.arb`, bundles nothing,
and ships no catalogue of its own. Both halves speak ICU MessageFormat, so there is one syntax in
your system and your translators' tools already understand it.

```dart
Text(context.locale.welcomeTitle)          // chrome: typed, compile-checked
Text(basketLabel.of(context))              // a key stored in a row
Text(product.name.of(context))             // content carried by the row
```

## `Localized<T>` — the spine

One container, any payload. `String`, `Uri`, `ImageData`, or your own type:

```dart
final Localized<Uri> video = Localized.values({
  'en': Uri.parse('https://…/welcome-en.webm'),
  'cs': Uri.parse('https://…/welcome-cs.webm'),
}, codec: uriCodec);

video.resolve(const Locale('cs', 'CZ'));  // cs_CZ → cs → en
```

Two ways to extend it, for two different needs:

| You want | Do this |
|---|---|
| A per-locale value of your own type | `Localized<Badge>` with a `LocalizedValueCodec<Badge>`. No subclass. |
| Your own *resolution semantics* | `final class MarketPrice extends Localized<Money>` |

It is `base` rather than `interface` on purpose: you must `extends`, so you inherit the fallback
chain instead of reimplementing it. The cost is that the modifier is viral — a subtype must be
`base`, `final` or `sealed`, and nobody can `implements Localized`, so a test double has to be a
real subclass.

Shipped subclasses — `LocalizedText`, `LocalizedImage`, `LocalizedAudio`, `LocalizedVideo`,
`LocalizedSpeech` — are written with no privileged access. They are exactly what you would write.

## Text is more than a map of strings

`Map<String, String>` cannot say "3 položky" but "5 položek". So text variants are ICU patterns:

```dart
final items = LocalizedText.values({
  'cs': '{n, plural, one{{n} položka} few{{n} položky} other{{n} položek}}',
  'en': '{n, plural, one{{n} item} other{{n} items}}',
});

items.format(const Locale('cs'), args: const MessageArgs({'n': 3}));  // "3 položky"
```

Patterns parse lazily and are memoised by source, so a row carrying five locales does not scan five
patterns to render one. `validate()` checks them all at once, which is what a content test wants.

**What is supported:** placeholders, `plural` (with `=0` exact cases and `offset:`), `select` (which
covers grammatical gender), nesting, and ICU apostrophe quoting.

**What is rejected, loudly:**

- `selectordinal` — `intl` resolves it with *cardinal* rules, rendering `2th` and `3th` in English.
  Rather than ship that silently, this package refuses the pattern and tells you why.
- `{d, date, yMMMd}` and friends — `intl` reads these as a placeholder literally *named*
  `d, date, yMMMd`. Format the value in Dart and pass the result instead.

Numeric and `DateTime` arguments are formatted for the locale, because `intl` does that only for `#`
inside a plural — a bare `{n}` would otherwise read `1234567` in every language.

## Keys, for content that points at your catalogue

A row can store a catalogue key instead of its own translations. Resolving it needs one thing from
you, because gen-l10n emits only typed members — `String get welcomeTitle;`, `String itemCount(int n);`
— with no map, no `operator []`, and nothing a Dart extension can reflect over:

```dart
// l10n.yaml: nullable-getter: false   → no `!` anywhere
extension LocaleContext on BuildContext {
  AppLocalizations get locale => AppLocalizations.of(this);
}

extension AppLocalizationsLexicon on AppLocalizations {
  String? lookup(String key, [MessageArgs a = const MessageArgs.empty()]) =>
      switch (key) {
        'welcomeTitle' => welcomeTitle,
        'itemCount' => itemCount((a[const ArgName('n')] as num? ?? 0).toInt()),
        _ => null,
      };
}
```

Then install it once and store keys freely:

```dart
LexiconScope(lookupBuilder: (context) => context.locale.lookup, child: const MyApp())
```

The `switch` is yours to maintain. That is the price of keeping translations compiled, and it is
paid per key rather than per record. A key with no arm renders as itself by default — legible,
reportable from a screenshot, and unmistakably not finished copy.

**This package never declares `locale` on `BuildContext`**, so that name stays free for your
extension above. Two extensions declaring one member on one type are ambiguous at every call site,
so it is reserved for you deliberately, and a test enforces it.

## Polymorphic content

A repository can return `List<ContentObject>` without knowing what is in it:

```dart
final registry = ContentRegistry()..register('character', CharacterObject.fromJson);
final List<ContentObject> items = registry.decodeAll(json);
```

Built in: `text`, `image`, `audio`, `video`, `speech`. `title` and `description` live on the
interface, so a gallery renders a list without a `switch` over every kind.

`speech` carries a per-locale recording *and* its own cue track, because a mouth moves differently
in Czech than in English.

## Storage

Everything here is a plain value that round-trips through JSON, which is the whole compatibility
story. This package depends on no database and no data layer.

With [administratum](https://github.com/th3jk/administratum), the model's own `fromJson`/`toJson`
already do the work — there is nothing to add. With drift, note that `Localized.toJson` returns a
`Json`, so the converter encodes it:

```dart
class LocalizedTextConverter extends TypeConverter<LocalizedText, String> {
  const LocalizedTextConverter();
  @override
  LocalizedText fromSql(String value) =>
      LocalizedText.fromJson(jsonDecode(value));
  @override
  String toSql(LocalizedText value) => jsonEncode(value.toJson());
}
```

**Round-trip promise:** `decode(encode(x)) == x` for every value, and `encode` is a fixed point, so
golden files are stable. ICU patterns are preserved verbatim, never re-serialised.

## Fallback

`cs_CZ → cs → en`, and `zh_Hant_TW → zh_Hant → zh_TW → zh`, matching Flutter's own match priority so
the two can never disagree about which candidate is closer. `FallbackPolicy` sets the tail;
`FallbackPolicy.none` stops at truncation, which is usually what user-generated content wants.

Known limitation, documented rather than half-solved: CLDR's parent-locale table has exceptions this
misses — `en_GB`'s true parent is `en_001`. Shipping a partial copy of that table would be worse
than none, because it would be right often enough to hide where it is wrong.

## Testing

`package:lexicanum/lexicanum_testing.dart` carries `mapKeyLookup`, so your tests exercise the key
path with no generated code. It is free of `flutter_test` so it never drags a test framework into a
consumer's graph.

```dart
final lookup = mapKeyLookup({'welcomeTitle': 'Vítejte'}, locale: const Locale('cs'));
```
