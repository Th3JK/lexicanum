/// Strongly-typed identifiers.
///
/// Extension types are free at runtime, delegate `==`/`hashCode` to the wrapped
/// string, and are not assignable to one another — so a [MessageKey] cannot be
/// passed where a [LocaleTag] is wanted. Unwrap with `.value` only at JSON and
/// storage boundaries.
library;

/// A canonical locale identifier: `en`, `cs_CZ`, `zh_Hant_TW`.
///
/// Canonical means underscore-separated, lowercase language, titlecase script,
/// uppercase region. Build one with `localeTagOf` or `tryParseLocaleTag` rather
/// than by hand, so the whole package agrees on spelling.
extension type const LocaleTag(String value) {}

/// Identifies one entry in the host's message catalogue.
///
/// Namespace by convention — `checkout.title` — because the key travels in
/// stored data and outlives whichever screen first used it.
extension type const MessageKey(String value) {}

/// Names one interpolation placeholder inside an ICU pattern.
extension type const ArgName(String value) {}
