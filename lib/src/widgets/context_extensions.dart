/// Reading localized content from a widget.
///
/// Note what is deliberately *absent*: this package never declares a member
/// named `locale` on [BuildContext]. That name belongs to the host's own
/// extension over its generated `AppLocalizations`, which is what makes
/// `context.locale.welcomeTitle` read well -- and two extensions declaring the
/// same member on the same type are ambiguous at every call site, resolvable
/// only by the explicit `LexicanumContext(context).locale` spelling that
/// defeats the point. An architecture test enforces the absence.
library;

import 'package:flutter/widgets.dart';

import '../localized/localized.dart';
import '../localized/text.dart';
import '../message/args.dart';
import '../message/key_lookup.dart';
import 'lexicon_scope.dart';

/// Locale and catalogue access, under names the host's own extension will not
/// collide with.
extension LexicanumContext on BuildContext {
  /// The locale Flutter resolved for this subtree.
  Locale get activeLocale => Localizations.localeOf(this);

  /// The catalogue lookup from the nearest [LexiconScope].
  KeyLookup get lexiconLookup => LexiconScope.of(this).lookupFor(this);
}

/// Resolving any container against the locale in scope.
extension LocalizedContext<T> on Localized<T> {
  /// The best variant for the locale in scope, or null.
  T? ofOrNull(BuildContext context) => resolveOrNull(
    context.activeLocale,
    policy: LexiconScope.of(context).fallback,
  );

  /// The best variant for the locale in scope, throwing when there is none.
  ///
  /// Prefer [ofOrNull] inside `build`: an exception escaping a build method is
  /// a red screen, and missing content rarely deserves one.
  T ofContext(BuildContext context) =>
      resolve(context.activeLocale, policy: LexiconScope.of(context).fallback);
}

/// Rendering text against the locale in scope.
///
/// More specific than [LocalizedContext], so `text.of(context)` on a
/// [LocalizedText] resolves to this one and returns a `String`.
extension LocalizedTextContext on LocalizedText {
  /// Resolves and formats for the locale in scope.
  ///
  /// Returns an empty string when no variant matches, rather than throwing
  /// inside `build`. Use [ofOrNull] to detect that case and render your own
  /// placeholder.
  String of(
    BuildContext context, {
    MessageArgs args = const MessageArgs.empty(),
  }) => ofOrNull(context, args: args) ?? '';

  /// As [of], but null when no variant matches.
  String? ofOrNull(
    BuildContext context, {
    MessageArgs args = const MessageArgs.empty(),
  }) => formatOrNull(
    context.activeLocale,
    args: args,
    policy: LexiconScope.of(context).fallback,
  );
}

/// Resolving a stored catalogue key against the scope's lookup.
extension KeyedTextContext on KeyedText {
  /// Looks the key up through the nearest [LexiconScope].
  ///
  /// Applies the scope's [LexiconScope.onMissingKey] when nothing resolves it,
  /// which by default renders the key itself.
  String of(
    BuildContext context, {
    MessageArgs args = const MessageArgs.empty(),
  }) {
    final LexiconScope scope = LexiconScope.of(context);
    return resolve(
      scope.lookupFor(context),
      context.activeLocale,
      args: args,
      onMissing: scope.onMissingKey,
      fallbackPolicy: scope.fallback,
    );
  }
}
