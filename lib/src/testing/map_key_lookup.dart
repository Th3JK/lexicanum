/// A catalogue standing in for generated code.
library;

import '../message/args.dart';
import '../message/key_lookup.dart';
import '../message/pattern.dart';

import 'package:flutter/widgets.dart' show Locale;

/// Builds a [KeyLookup] from a plain map, for tests and previews.
///
/// The suite needs no generated `AppLocalizations` to exercise the key path,
/// and neither does a host writing tests for its own content. Values are ICU
/// patterns, formatted for [locale], so the stand-in behaves like the real
/// thing rather than merely returning strings.
KeyLookup mapKeyLookup(
  Map<String, String> catalogue, {
  required Locale locale,
}) => (String key, MessageArgs args) {
  final String? pattern = catalogue[key];
  return pattern == null
      ? null
      : MessagePattern(pattern).format(locale, args: args);
};
