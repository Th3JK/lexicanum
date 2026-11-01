## 0.1.0

* Initial release.
* `Localized<T>`: per-locale variants of any value, with a fallback chain. Open for subclassing.
* `LocalizedText` over ICU MessageFormat patterns, with lazy parsing and `validate()`.
* `LocalizedImage`, `LocalizedAudio`, `LocalizedVideo`, `LocalizedSpeech` and their payload types.
* `ContentObject` and `ContentRegistry` for polymorphic content, including host-defined types.
* `KeyedText` and the `KeyLookup` seam, for content that points at a gen-l10n catalogue.
* `LexiconScope` and context extensions, deliberately leaving `context.locale` free for the host.
