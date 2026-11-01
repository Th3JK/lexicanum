/// The content types this package ships.
///
/// Each is an ordinary [ContentObject] with a [Localized] payload -- exactly
/// what a host writes for its own type, and registered through the same map, so
/// a built-in has no privilege a registered type lacks.
///
/// There is deliberately no separate `animation` type: the speech-animation
/// case is [SpeechObject], whose cue track is what drives a rig, and anything
/// else is a video or a file reference the host already models.
library;

import 'package:meta/meta.dart';

import '../errors.dart';
import '../internal/json.dart';
import '../localized/media.dart';
import '../localized/text.dart';
import 'content_object.dart';
import 'content_registry.dart';

/// Shared decoding of the fields every content object carries.
({String id, LocalizedText? title, LocalizedText? description}) _common(
  Json json,
  String path,
) {
  final Object? id = json['id'];
  if (id is! String) {
    throw LexicanumFormatException(
      '$path.id',
      '$path: content needs a string "id", found ${id.runtimeType}.',
    );
  }
  return (
    id: id,
    title: json['title'] == null
        ? null
        : LocalizedText.fromJson(json['title'], '$path.title'),
    description: json['description'] == null
        ? null
        : LocalizedText.fromJson(json['description'], '$path.description'),
  );
}

Json _commonJson(ContentObject object) => <String, Object?>{
  'id': object.id,
  'type': object.type,
  'title': object.title?.toJson(),
  'description': object.description?.toJson(),
};

/// A block of locale-varying text.
@immutable
final class TextObject implements ContentObject {
  /// Creates a text object.
  const TextObject({
    required this.id,
    required this.text,
    this.title,
    this.description,
  });

  /// Reads a text object from JSON.
  factory TextObject.fromJson(Json json, [String path = r'$']) {
    final ({String id, LocalizedText? title, LocalizedText? description})
    common = _common(json, path);
    return TextObject(
      id: common.id,
      text: LocalizedText.fromJson(json['text'], '$path.text'),
      title: common.title,
      description: common.description,
    );
  }

  @override
  final String id;

  /// The body, as ICU patterns per locale.
  final LocalizedText text;

  @override
  final LocalizedText? title;

  @override
  final LocalizedText? description;

  @override
  String get type => 'text';

  @override
  Json toJson() =>
      compact(<String, Object?>{..._commonJson(this), 'text': text.toJson()});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextObject &&
          other.id == id &&
          other.text == text &&
          other.title == title &&
          other.description == description;

  @override
  int get hashCode => Object.hash(id, text, title, description);

  @override
  String toString() => 'TextObject($id)';
}

/// An image that differs by locale.
@immutable
final class ImageObject implements ContentObject {
  /// Creates an image object.
  const ImageObject({
    required this.id,
    required this.image,
    this.title,
    this.description,
  });

  /// Reads an image object from JSON.
  factory ImageObject.fromJson(Json json, [String path = r'$']) {
    final ({String id, LocalizedText? title, LocalizedText? description})
    common = _common(json, path);
    return ImageObject(
      id: common.id,
      image: LocalizedImage.fromJson(json['image'], '$path.image'),
      title: common.title,
      description: common.description,
    );
  }

  @override
  final String id;

  /// The image, per locale.
  final LocalizedImage image;

  @override
  final LocalizedText? title;

  @override
  final LocalizedText? description;

  @override
  String get type => 'image';

  @override
  Json toJson() =>
      compact(<String, Object?>{..._commonJson(this), 'image': image.toJson()});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageObject &&
          other.id == id &&
          other.image == image &&
          other.title == title &&
          other.description == description;

  @override
  int get hashCode => Object.hash(id, image, title, description);

  @override
  String toString() => 'ImageObject($id)';
}

/// An audio clip that differs by locale.
@immutable
final class AudioObject implements ContentObject {
  /// Creates an audio object.
  const AudioObject({
    required this.id,
    required this.audio,
    this.title,
    this.description,
  });

  /// Reads an audio object from JSON.
  factory AudioObject.fromJson(Json json, [String path = r'$']) {
    final ({String id, LocalizedText? title, LocalizedText? description})
    common = _common(json, path);
    return AudioObject(
      id: common.id,
      audio: LocalizedAudio.fromJson(json['audio'], '$path.audio'),
      title: common.title,
      description: common.description,
    );
  }

  @override
  final String id;

  /// The clip, per locale.
  final LocalizedAudio audio;

  @override
  final LocalizedText? title;

  @override
  final LocalizedText? description;

  @override
  String get type => 'audio';

  @override
  Json toJson() =>
      compact(<String, Object?>{..._commonJson(this), 'audio': audio.toJson()});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioObject &&
          other.id == id &&
          other.audio == audio &&
          other.title == title &&
          other.description == description;

  @override
  int get hashCode => Object.hash(id, audio, title, description);

  @override
  String toString() => 'AudioObject($id)';
}

/// A video that differs by locale.
@immutable
final class VideoObject implements ContentObject {
  /// Creates a video object.
  const VideoObject({
    required this.id,
    required this.video,
    this.title,
    this.description,
  });

  /// Reads a video object from JSON.
  factory VideoObject.fromJson(Json json, [String path = r'$']) {
    final ({String id, LocalizedText? title, LocalizedText? description})
    common = _common(json, path);
    return VideoObject(
      id: common.id,
      video: LocalizedVideo.fromJson(json['video'], '$path.video'),
      title: common.title,
      description: common.description,
    );
  }

  @override
  final String id;

  /// The video, per locale.
  final LocalizedVideo video;

  @override
  final LocalizedText? title;

  @override
  final LocalizedText? description;

  @override
  String get type => 'video';

  @override
  Json toJson() =>
      compact(<String, Object?>{..._commonJson(this), 'video': video.toJson()});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoObject &&
          other.id == id &&
          other.video == video &&
          other.title == title &&
          other.description == description;

  @override
  int get hashCode => Object.hash(id, video, title, description);

  @override
  String toString() => 'VideoObject($id)';
}

/// Spoken audio with a per-locale cue track.
@immutable
final class SpeechObject implements ContentObject {
  /// Creates a speech object.
  const SpeechObject({
    required this.id,
    required this.speech,
    this.title,
    this.description,
  });

  /// Reads a speech object from JSON.
  factory SpeechObject.fromJson(Json json, [String path = r'$']) {
    final ({String id, LocalizedText? title, LocalizedText? description})
    common = _common(json, path);
    return SpeechObject(
      id: common.id,
      speech: LocalizedSpeech.fromJson(json['speech'], '$path.speech'),
      title: common.title,
      description: common.description,
    );
  }

  @override
  final String id;

  /// The recording and its cues, per locale.
  final LocalizedSpeech speech;

  @override
  final LocalizedText? title;

  @override
  final LocalizedText? description;

  @override
  String get type => 'speech';

  @override
  Json toJson() => compact(<String, Object?>{
    ..._commonJson(this),
    'speech': speech.toJson(),
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpeechObject &&
          other.id == id &&
          other.speech == speech &&
          other.title == title &&
          other.description == description;

  @override
  int get hashCode => Object.hash(id, speech, title, description);

  @override
  String toString() => 'SpeechObject($id)';
}

/// The decoders a fresh [ContentRegistry] starts with.
const Map<String, ContentDecoder> builtInContentDecoders =
    <String, ContentDecoder>{
      'text': TextObject.fromJson,
      'image': ImageObject.fromJson,
      'audio': AudioObject.fromJson,
      'video': VideoObject.fromJson,
      'speech': SpeechObject.fromJson,
    };
