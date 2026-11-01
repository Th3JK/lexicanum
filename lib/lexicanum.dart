/// Localized generic data objects.
///
/// Hold per-locale variants of text, media or any value in an immutable,
/// JSON-round-trippable container; resolve them at the presentation boundary.
/// Domain and repository objects stay free of `BuildContext`.
///
/// The package sits above `intl` and `flutter_localizations` rather than
/// replacing them: gen-l10n keeps full ownership of the compiled catalogue, and
/// nothing here reads an `.arb` file.
library;

export 'src/errors.dart';
export 'src/content/built_in_objects.dart';
export 'src/content/content_object.dart';
export 'src/content/content_registry.dart';
export 'src/ids.dart';
export 'src/internal/json.dart' show Json;
export 'src/locale/fallback_policy.dart';
export 'src/locale/locale_conversion.dart';
export 'src/locale/locale_match.dart';
export 'src/localized/localized.dart';
export 'src/localized/media.dart';
export 'src/localized/text.dart';
export 'src/payload/media_data.dart';
export 'src/widgets/context_extensions.dart';
export 'src/widgets/lexicon_scope.dart';
export 'src/internal/intl_bridge.dart' show resetIntlCaches;
export 'src/message/args.dart';
export 'src/message/key_lookup.dart';
export 'src/message/pattern.dart';
export 'src/message/scanner.dart' show PatternInfo, scanPattern;
export 'src/localized/value_codec.dart';
