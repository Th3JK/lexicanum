/// Payload value types for media that varies by locale.
///
/// These are the `T` in `Localized<T>`, not containers themselves. Because the
/// container holds one of these per locale, everything on them is per-locale
/// for free -- including alt text and captions, which is the whole reason a
/// locale-varying image is more than a locale-varying URL.
library;

import 'package:meta/meta.dart';

import '../errors.dart';
import '../internal/equality.dart';
import '../internal/json.dart';

/// An image, with the text that describes it.
@immutable
final class ImageData {
  /// Creates image data.
  const ImageData({required this.source, this.width, this.height, this.alt});

  /// Reads image data from JSON.
  factory ImageData.fromJson(Object? json, [String path = r'$']) {
    final Json object = requireObject(json, path);
    return ImageData(
      source: requireUri(object, 'source', path),
      width: optionalInt(object, 'width', path),
      height: optionalInt(object, 'height', path),
      alt: optionalString(object, 'alt', path),
    );
  }

  /// Where the image lives. Asset path or absolute URL; the host decides.
  final Uri source;

  /// Intrinsic width in pixels, when known.
  final int? width;

  /// Intrinsic height in pixels, when known.
  final int? height;

  /// Alternative text, in this variant's language.
  final String? alt;

  /// Writes to JSON, omitting absent optional fields.
  Json toJson() => compact(<String, Object?>{
    'source': source.toString(),
    'width': width,
    'height': height,
    'alt': alt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageData &&
          other.source == source &&
          other.width == width &&
          other.height == height &&
          other.alt == alt;

  @override
  int get hashCode => Object.hash(source, width, height, alt);

  @override
  String toString() => 'ImageData($source)';
}

/// An audio clip.
@immutable
final class AudioData {
  /// Creates audio data.
  const AudioData({required this.source, this.duration, this.transcript});

  /// Reads audio data from JSON.
  factory AudioData.fromJson(Object? json, [String path = r'$']) {
    final Json object = requireObject(json, path);
    return AudioData(
      source: requireUri(object, 'source', path),
      duration: optionalDuration(object, 'durationMs', path),
      transcript: optionalString(object, 'transcript', path),
    );
  }

  /// Where the audio lives.
  final Uri source;

  /// Running time, when known.
  final Duration? duration;

  /// What is said, in this variant's language.
  final String? transcript;

  /// Writes to JSON, omitting absent optional fields.
  Json toJson() => compact(<String, Object?>{
    'source': source.toString(),
    'durationMs': duration?.inMilliseconds,
    'transcript': transcript,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioData &&
          other.source == source &&
          other.duration == duration &&
          other.transcript == transcript;

  @override
  int get hashCode => Object.hash(source, duration, transcript);

  @override
  String toString() => 'AudioData($source)';
}

/// A video clip.
@immutable
final class VideoData {
  /// Creates video data.
  const VideoData({
    required this.source,
    this.duration,
    this.poster,
    this.captions,
  });

  /// Reads video data from JSON.
  factory VideoData.fromJson(Object? json, [String path = r'$']) {
    final Json object = requireObject(json, path);
    return VideoData(
      source: requireUri(object, 'source', path),
      duration: optionalDuration(object, 'durationMs', path),
      poster: object['poster'] == null
          ? null
          : requireUri(object, 'poster', path),
      captions: object['captions'] == null
          ? null
          : requireUri(object, 'captions', path),
    );
  }

  /// Where the video lives.
  final Uri source;

  /// Running time, when known.
  final Duration? duration;

  /// Still image shown before playback, in this variant's language.
  final Uri? poster;

  /// Caption track for this variant's language.
  final Uri? captions;

  /// Writes to JSON, omitting absent optional fields.
  Json toJson() => compact(<String, Object?>{
    'source': source.toString(),
    'durationMs': duration?.inMilliseconds,
    'poster': poster?.toString(),
    'captions': captions?.toString(),
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoData &&
          other.source == source &&
          other.duration == duration &&
          other.poster == poster &&
          other.captions == captions;

  @override
  int get hashCode => Object.hash(source, duration, poster, captions);

  @override
  String toString() => 'VideoData($source)';
}

/// One timed marker on a speech track.
///
/// [value] is deliberately an opaque token rather than an enum: the same
/// structure carries visemes for a mouth rig, phonemes for a different one, or
/// whole words for a karaoke-style caption, and this package has no business
/// deciding which.
@immutable
final class SpeechCue {
  /// Creates a cue.
  const SpeechCue({required this.at, required this.value});

  /// Reads a cue from JSON.
  factory SpeechCue.fromJson(Object? json, [String path = r'$']) {
    final Json object = requireObject(json, path);
    final int? at = optionalInt(object, 'atMs', path);
    final String? value = optionalString(object, 'value', path);
    if (at == null || value == null) {
      throw LexicanumFormatException(
        path,
        '$path: a speech cue needs both "atMs" and "value".',
      );
    }
    return SpeechCue(
      at: Duration(milliseconds: at),
      value: value,
    );
  }

  /// Offset from the start of the audio.
  final Duration at;

  /// The marker, whatever the host's rig understands.
  final String value;

  /// Writes to JSON.
  Json toJson() => <String, Object?>{'atMs': at.inMilliseconds, 'value': value};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpeechCue && other.at == at && other.value == value;

  @override
  int get hashCode => Object.hash(at, value);

  @override
  String toString() => 'SpeechCue(${at.inMilliseconds}ms, $value)';
}

/// Spoken audio with a timed marker track.
///
/// The case this package was asked to carry: the same line in several
/// languages, each with its own recording *and* its own timing, because the
/// mouth has to move differently in Czech than in English.
@immutable
final class SpeechData {
  /// Creates speech data.
  const SpeechData({required this.audio, this.cues = const <SpeechCue>[]});

  /// Reads speech data from JSON.
  factory SpeechData.fromJson(Object? json, [String path = r'$']) {
    final Json object = requireObject(json, path);
    final Object? cues = object['cues'];
    return SpeechData(
      audio: AudioData.fromJson(object['audio'], '$path.audio'),
      cues: cues == null
          ? const <SpeechCue>[]
          : <SpeechCue>[
              for (final (int i, Object? cue) in requireList(
                cues,
                '$path.cues',
              ).indexed)
                SpeechCue.fromJson(cue, '$path.cues[$i]'),
            ],
    );
  }

  /// The recording.
  final AudioData audio;

  /// Markers into [audio], in order.
  final List<SpeechCue> cues;

  /// Writes to JSON, omitting an empty cue list.
  Json toJson() => compact(<String, Object?>{
    'audio': audio.toJson(),
    'cues': cues.isEmpty
        ? null
        : <Json>[for (final SpeechCue cue in cues) cue.toJson()],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpeechData &&
          other.audio == audio &&
          listEq.equals(other.cues, cues);

  @override
  int get hashCode => Object.hash(audio, listEq.hash(cues));

  @override
  String toString() => 'SpeechData($audio, ${cues.length} cues)';
}
