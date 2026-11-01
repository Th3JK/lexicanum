/// How a requested locale degrades when it has no value of its own.
library;

import 'package:meta/meta.dart';

import '../ids.dart';
import '../internal/equality.dart';

/// The locales to fall back to once truncation of the requested tag runs out.
///
/// Truncation — `cs_CZ` to `cs` — is automatic and needs no configuration; this
/// is about what happens *after* it, when the language itself is absent. The
/// default appends `en`, which is the right answer for the overwhelming
/// majority of applications and a visible, deliberate one for the rest.
@immutable
final class FallbackPolicy {
  /// Creates a policy.
  const FallbackPolicy({
    this.tail = const <LocaleTag>[LocaleTag('en')],
    this.useAnyAvailable = false,
  });

  /// A policy that never falls back past truncation.
  ///
  /// Resolution then returns null rather than a string in the wrong language,
  /// which is what a caller rendering user-generated content usually wants.
  static const FallbackPolicy none = FallbackPolicy(tail: <LocaleTag>[]);

  /// Locales to try, in order, after truncating the requested tag.
  final List<LocaleTag> tail;

  /// Whether to try every remaining available locale as a last resort.
  ///
  /// Off by default: showing a Japanese string to a Czech user because it was
  /// the only one present is worse than showing nothing and reporting it.
  /// Ordering is alphabetical so the result is deterministic across runs.
  final bool useAnyAvailable;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FallbackPolicy &&
          listEq.equals(other.tail, tail) &&
          other.useAnyAvailable == useAnyAvailable;

  @override
  int get hashCode => Object.hash(listEq.hash(tail), useAnyAvailable);

  @override
  String toString() =>
      'FallbackPolicy(tail: $tail, useAnyAvailable: $useAnyAvailable)';
}
