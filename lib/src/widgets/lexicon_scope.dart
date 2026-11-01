/// The presentation boundary: where a locale and a catalogue become available.
library;

import 'package:flutter/widgets.dart';

import '../locale/fallback_policy.dart';
import '../message/args.dart';
import '../message/key_lookup.dart';

/// Supplies the key lookup and resolution policies to a subtree.
///
/// Optional, like interrogator's scope: every extension below falls back to
/// sensible defaults when there is no scope, so a widget tree that only uses
/// [LocalizedText] never needs one. Install it when content carries
/// [KeyedText], because that is the only thing that needs the host's catalogue.
///
/// The lookup is built from a [BuildContext] rather than passed directly,
/// because the host's `AppLocalizations` is itself read from the context:
///
/// ```dart
/// LexiconScope(
///   lookupBuilder: (context) => context.locale.lookup,
///   child: const MyApp(),
/// )
/// ```
///
/// There is no global state behind this. A locale change is Flutter's own
/// mechanism -- `Localizations` rebuilds, and every widget that read the locale
/// rebuilds with it -- and this package contributes no notification code.
class LexiconScope extends InheritedWidget {
  /// Creates a scope.
  const LexiconScope({
    required super.child,
    this.lookupBuilder,
    this.fallback,
    this.onMissingKey = MissingKeyPolicy.keyAsText,
    super.key,
  });

  /// Builds the catalogue lookup from the context it is used in.
  ///
  /// Null means no catalogue: a [KeyedText] then falls back to its own inline
  /// text, or to [onMissingKey].
  final KeyLookup Function(BuildContext context)? lookupBuilder;

  /// The fallback policy for content in this subtree.
  ///
  /// Null leaves each value to its own, which is almost always right. Set it to
  /// make one part of the app stricter -- user-generated content that should
  /// show nothing rather than an English original, say.
  final FallbackPolicy? fallback;

  /// What a reader sees when a key is not in the catalogue.
  final MissingKeyPolicy onMissingKey;

  /// The nearest scope, or null.
  static LexiconScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LexiconScope>();

  /// The nearest scope, or an empty one carrying the defaults.
  ///
  /// Never throws, so a widget can use content without the host having
  /// installed anything.
  static LexiconScope of(BuildContext context) =>
      maybeOf(context) ?? const LexiconScope(child: SizedBox.shrink());

  /// The catalogue lookup for [context], or one that resolves nothing.
  KeyLookup lookupFor(BuildContext context) =>
      lookupBuilder?.call(context) ?? _noCatalogue;

  @override
  bool updateShouldNotify(LexiconScope oldWidget) =>
      oldWidget.lookupBuilder != lookupBuilder ||
      oldWidget.fallback != fallback ||
      oldWidget.onMissingKey != onMissingKey;
}

String? _noCatalogue(String key, MessageArgs args) => null;
