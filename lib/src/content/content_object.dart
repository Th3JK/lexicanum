/// Polymorphic content a repository can return without knowing every type.
library;

import '../internal/json.dart';
import '../localized/text.dart';

/// One piece of content, whatever kind it is.
///
/// A repository returns `List<ContentObject>` and stays ignorant of the types
/// inside it; a gallery can render a title without knowing whether it is
/// looking at a video or a host-defined character. Built-in kinds and
/// host-registered ones are indistinguishable at this level, which is the
/// point.
///
/// An interface rather than a base class, because the shared behaviour here is
/// nil -- a content type brings its own payload and shares only the shape of
/// its identity. Compare [Localized], which is `base` precisely because it does
/// have behaviour worth inheriting.
abstract interface class ContentObject {
  /// Stable identity within the host's content set.
  String get id;

  /// The registered type name, for example `image` or `character`.
  ///
  /// Written to JSON and used by [ContentRegistry] to pick a decoder, so it
  /// must match what the type was registered under.
  String get type;

  /// A human-readable title, if this content has one.
  ///
  /// On the interface rather than on each type so a list can be rendered
  /// without a `switch` over every possible kind.
  LocalizedText? get title;

  /// A longer description, if this content has one.
  LocalizedText? get description;

  /// Writes to JSON, including [id] and [type].
  Json toJson();
}
