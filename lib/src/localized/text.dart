/// Locale-varying text, the most common container by far.
library;

import 'dart:ui' show Locale;

import '../errors.dart';
import '../ids.dart';
import '../locale/fallback_policy.dart';
import '../locale/locale_conversion.dart';
import '../message/args.dart';
import '../message/pattern.dart';
import 'localized.dart';
import 'value_codec.dart';

MessagePattern _patternFromJson(Object? json) {
  if (json is! String) {
    throw LexicanumFormatException(
      r'$',
      'A text variant must be an ICU pattern string, found ${json.runtimeType}.',
    );
  }
  return MessagePattern(json);
}

Object? _patternToJson(MessagePattern pattern) => pattern.source;

/// Codec for ICU patterns. Const, because both halves are top-level functions.
const LocalizedValueCodec<MessagePattern> messagePatternCodec =
    LocalizedValueCodec<MessagePattern>(
      fromJson: _patternFromJson,
      toJson: _patternToJson,
    );

/// Per-locale ICU patterns, resolved and formatted in one step.
///
/// This is where the generic container and the message layer meet: the variants
/// are [MessagePattern]s rather than plain strings, so a language that needs a
/// plural where English needs one word can express that per locale -- which a
/// `Map<String, String>` cannot.
///
/// The first of the package's own subclasses, and written with no privileged
/// access to [Localized], so the extension point is demonstrated rather than
/// asserted.
final class LocalizedText extends Localized<MessagePattern> {
  /// Creates text over already-canonical tags.
  const LocalizedText(this.variants, {this.fallback});

  /// Creates text from ICU pattern strings, canonicalising the locale keys.
  factory LocalizedText.values(
    Map<String, String> patterns, {
    FallbackPolicy? fallback,
  }) => LocalizedText(<LocaleTag, MessagePattern>{
    for (final MapEntry<String, String> entry in patterns.entries)
      parseLocaleTag(entry.key): MessagePattern(entry.value),
  }, fallback: fallback);

  /// Reads text from a locale-keyed JSON object of ICU patterns.
  ///
  /// Patterns are not validated here: a record carrying five locales should not
  /// scan five patterns when one of them is rendered. Call [validate] to check
  /// them eagerly, which is what a content test wants.
  factory LocalizedText.fromJson(Object? json, [String path = r'$']) {
    final Localized<MessagePattern> decoded = decodeLocalized<MessagePattern>(
      json,
      messagePatternCodec,
      path: path,
    );
    return LocalizedText(decoded.variants);
  }

  @override
  final Map<LocaleTag, MessagePattern> variants;

  @override
  final FallbackPolicy? fallback;

  @override
  LocalizedValueCodec<MessagePattern> get codec => messagePatternCodec;

  /// Resolves for [locale] and renders, in one call.
  ///
  /// Throws [MissingLocalizedValue] when no variant matches, matching
  /// [Localized.resolve]. Widget code that would rather show nothing than throw
  /// wants [formatOrNull].
  String format(
    Locale locale, {
    MessageArgs args = const MessageArgs.empty(),
    FallbackPolicy? policy,
  }) => resolve(locale, policy: policy).format(locale, args: args);

  /// As [format], but null rather than throwing when nothing matches.
  String? formatOrNull(
    Locale locale, {
    MessageArgs args = const MessageArgs.empty(),
    FallbackPolicy? policy,
  }) => resolveOrNull(locale, policy: policy)?.format(locale, args: args);

  /// Every argument any variant can substitute.
  ///
  /// The union, not the intersection: a host passing this set satisfies every
  /// locale, which is what matters when the rendering locale is not known at
  /// the call site. Throws if any variant is malformed.
  Set<ArgName> get placeholders => <ArgName>{
    for (final MessagePattern pattern in variants.values)
      ...pattern.info.placeholders,
  };

  /// Checks every variant, returning one problem per malformed pattern.
  ///
  /// Empty means the content is sound. Written to return rather than throw
  /// because a content test wants to report all of them at once, not the first.
  List<MessagePatternException> validate() {
    final List<MessagePatternException> problems = <MessagePatternException>[];
    for (final MapEntry<LocaleTag, MessagePattern> entry in variants.entries) {
      try {
        entry.value.info;
      } on MessagePatternException catch (problem) {
        problems.add(
          MessagePatternException(
            problem.pattern,
            problem.offset,
            '${entry.key.value}: ${problem.message}',
          ),
        );
      }
    }
    return problems;
  }
}
