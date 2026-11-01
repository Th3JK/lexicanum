/// Helpers for testing content built with this package.
///
/// Kept out of the main barrel so fakes and fixtures never reach an app binary,
/// and deliberately free of `flutter_test` so importing it does not drag a test
/// framework into a consumer's dependency graph -- administratum's reasoning
/// for the same split.
library;

export 'src/internal/intl_bridge.dart' show resetIntlCaches;
export 'src/testing/map_key_lookup.dart';
