/// The one locale matcher.
///
/// Every per-locale lookup in this package routes through [chainFor] — the
/// generic container, the text subclass, the key lookup. Two hierarchies that
/// know nothing about each other still agree on what "closest locale" means
/// because neither implements it.
library;

import '../ids.dart';
import 'fallback_policy.dart';

/// The locales to try for [requested], most specific first.
///
/// The truncation order matches Flutter's own match priority in
/// `basicLocaleListResolution` — language+script+region, language+script,
/// language+region, language — so this package's search order and Flutter's
/// choice of active locale can never disagree about which candidate is closer.
///
/// `basicLocaleListResolution` itself is deliberately not reused: it returns a
/// single locale, may return one absent from the supported set, and terminates
/// at `supportedLocales.first`. Resolution needs an ordered list that can end
/// in nothing at all.
///
/// Known limitation, documented rather than half-solved: CLDR's parent-locale
/// table has exceptions this truncation misses — `en_GB`'s true parent is
/// `en_001`, `zh_Hant`'s is root rather than `zh`. Shipping a partial copy of
/// that table would be worse than having none, because it would be right often
/// enough to hide where it is wrong. [FallbackPolicy.tail] covers the handful
/// of applications that care.
List<LocaleTag> chainFor(
  LocaleTag requested, {
  required Set<LocaleTag> available,
  FallbackPolicy policy = const FallbackPolicy(),
}) {
  final List<LocaleTag> chain = <LocaleTag>[];

  void add(LocaleTag tag) {
    if (available.contains(tag) && !chain.contains(tag)) {
      chain.add(tag);
    }
  }

  for (final LocaleTag candidate in ladderFor(requested)) {
    add(candidate);
  }
  for (final LocaleTag candidate in policy.tail) {
    add(candidate);
  }
  if (policy.useAnyAvailable) {
    final List<LocaleTag> rest = available.toList()
      ..sort((LocaleTag a, LocaleTag b) => a.value.compareTo(b.value));
    rest.forEach(add);
  }

  return List<LocaleTag>.unmodifiable(chain);
}

/// The truncation ladder for [requested], most specific first.
///
/// Unlike [chainFor] this is not intersected with anything, which is what makes
/// it testable on its own and reusable for reporting what was tried.
List<LocaleTag> ladderFor(LocaleTag requested) {
  final List<String> parts = requested.value.split('_');
  final String language = parts.first;
  final String? script = parts.length > 1 && parts[1].length == 4
      ? parts[1]
      : null;
  final String? region = parts.length > 1 && parts.last.length != 4
      ? parts.last
      : null;

  final List<LocaleTag> ladder = <LocaleTag>[];
  void add(String value) {
    final LocaleTag tag = LocaleTag(value);
    if (!ladder.contains(tag)) {
      ladder.add(tag);
    }
  }

  if (script != null && region != null) {
    add('${language}_${script}_$region');
    add('${language}_$script');
    add('${language}_$region');
  } else if (script != null) {
    add('${language}_$script');
  } else if (region != null) {
    add('${language}_$region');
  }
  add(language);

  return List<LocaleTag>.unmodifiable(ladder);
}
