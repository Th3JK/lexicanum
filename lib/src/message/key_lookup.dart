/// The seam between stored keys and the host's compiled catalogue.
library;

import 'dart:ui' show Locale;

import 'package:meta/meta.dart';

import '../errors.dart';
import '../ids.dart';
import '../localized/text.dart';
import '../locale/fallback_policy.dart';
import 'args.dart';

/// Turns a stored key into a rendered string.
///
/// This package never implements it. gen-l10n keeps full ownership of the
/// catalogue, and the generated `AppLocalizations` is the only thing holding
/// the compiled messages -- so the host satisfies this against its own
/// generated class, typically through an extension:
///
/// ```dart
/// extension AppLocalizationsLexicon on AppLocalizations {
///   String? lookup(String key, [MessageArgs a = const MessageArgs.empty()]) =>
///       switch (key) {
///         'welcomeTitle' => welcomeTitle,
///         'itemCount'    => itemCount(a.values['n']! as int),
///         _ => null,
///       };
/// }
/// ```
///
/// The `switch` is the host's to maintain, and deliberately so: gen-l10n emits
/// only `String get name;` and `String name(params);` -- no map, no
/// `operator []` -- and a Dart extension cannot reflect over them. Nothing here
/// can derive it. Returning null for an unknown key is expected, not an error;
/// [MissingKeyPolicy] decides what the reader sees.
typedef KeyLookup = String? Function(String key, MessageArgs args);

/// What a reader sees when a key is not in the catalogue.
enum MissingKeyPolicy {
  /// Render the key itself, for example `checkout.title`.
  ///
  /// The default, for administratum's `DecodeErrorPolicy.skip` reasoning: one
  /// missing entry must not blank a screen. Wrong but legible beats invisible,
  /// it is reportable from a single screenshot, and it is unmistakably not
  /// finished copy.
  keyAsText,

  /// Render nothing.
  ///
  /// Correct where a label is genuinely optional; a poor default, because a
  /// button that loses its text is indistinguishable from a layout bug.
  empty,

  /// Throw [MissingMessageKey].
  ///
  /// For a test suite, or a build that would rather fail loudly than ship a
  /// gap. Rarely what you want in a release.
  throwError,
}

/// Text whose translation lives in the host's compiled catalogue.
///
/// The counterpart to [LocalizedText]: use this when the string is UI chrome
/// that gen-l10n already owns and the record only needs to point at it, and
/// [LocalizedText] when the translations genuinely travel with the record.
/// A row storing a key is how one record can serve every locale the app ships
/// without being rewritten.
@immutable
final class KeyedText {
  /// Creates a reference to [key].
  const KeyedText(this.key, {this.fallback});

  /// Reads from JSON: a bare string, or an object with a `fallback`.
  factory KeyedText.fromJson(Object? json, [String path = r'$']) {
    if (json is String) {
      return KeyedText(MessageKey(json));
    }
    if (json is Map<String, Object?>) {
      final Object? key = json['key'];
      if (key is String) {
        return KeyedText(
          MessageKey(key),
          fallback: json['fallback'] == null
              ? null
              : LocalizedText.fromJson(json['fallback'], '$path.fallback'),
        );
      }
    }
    throw LexicanumFormatException(
      path,
      '$path: expected a catalogue key as a string, or an object with a "key" '
      'field, found ${json.runtimeType}.',
    );
  }

  /// The catalogue entry to look up.
  final MessageKey key;

  /// Rendered when the catalogue has no entry, in preference to the policy.
  ///
  /// Content that ships its own fallback should never show a bare key, which
  /// matters most for keys added by a newer client than the catalogue it runs
  /// against.
  final LocalizedText? fallback;

  /// Renders [key] through [lookup], or null when nothing resolves it.
  String? resolveOrNull(
    KeyLookup lookup,
    Locale locale, {
    MessageArgs args = const MessageArgs.empty(),
    FallbackPolicy? policy,
  }) =>
      lookup(key.value, args) ??
      fallback?.formatOrNull(locale, args: args, policy: policy);

  /// Renders [key], applying [policy] when nothing resolves it.
  String resolve(
    KeyLookup lookup,
    Locale locale, {
    MessageArgs args = const MessageArgs.empty(),
    MissingKeyPolicy onMissing = MissingKeyPolicy.keyAsText,
    FallbackPolicy? fallbackPolicy,
  }) {
    final String? resolved = resolveOrNull(
      lookup,
      locale,
      args: args,
      policy: fallbackPolicy,
    );
    if (resolved != null) {
      return resolved;
    }
    return switch (onMissing) {
      MissingKeyPolicy.keyAsText => key.value,
      MissingKeyPolicy.empty => '',
      MissingKeyPolicy.throwError => throw MissingMessageKey(
        key.value,
        'No catalogue entry for "${key.value}". Add it to your .arb and to '
        'the lookup extension, give this KeyedText a fallback, or use a '
        'gentler MissingKeyPolicy.',
      ),
    };
  }

  /// Writes to JSON: a bare string unless there is a [fallback].
  Object? toJson() => fallback == null
      ? key.value
      : <String, Object?>{'key': key.value, 'fallback': fallback!.toJson()};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyedText && other.key == key && other.fallback == fallback;

  @override
  int get hashCode => Object.hash(key, fallback);

  @override
  String toString() => 'KeyedText(${key.value})';
}
