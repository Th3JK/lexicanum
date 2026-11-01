/// A host-defined content type the package has never heard of.
library;

import 'package:lexicanum/lexicanum.dart';

/// Something a game might store, with a per-locale portrait and voice.
final class CharacterObject implements ContentObject {
  /// Creates a character.
  const CharacterObject({
    required this.id,
    required this.portrait,
    this.title,
    this.description,
  });

  /// Reads a character from JSON, as a [ContentDecoder].
  factory CharacterObject.fromJson(Json json, [String path = r'$']) =>
      CharacterObject(
        id: json['id']! as String,
        portrait: LocalizedImage.fromJson(json['portrait'], '$path.portrait'),
        title: json['title'] == null
            ? null
            : LocalizedText.fromJson(json['title'], '$path.title'),
      );

  @override
  final String id;

  /// The character's portrait, which differs by locale.
  final LocalizedImage portrait;

  @override
  final LocalizedText? title;

  @override
  final LocalizedText? description;

  @override
  String get type => 'character';

  @override
  Json toJson() => <String, Object?>{
    'id': id,
    'type': type,
    'portrait': portrait.toJson(),
    if (title != null) 'title': title!.toJson(),
  };
}
