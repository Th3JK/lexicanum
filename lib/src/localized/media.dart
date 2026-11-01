/// Locale-varying media.
///
/// Four subclasses that differ only in their payload, kept in one file because
/// four near-identical files would hide how alike they are. Each is written
/// with no privileged access to [Localized] -- they are exactly what a host
/// would write for its own type, which is the point of dogfooding the
/// extension point rather than only documenting it.
library;

import '../ids.dart';
import '../locale/fallback_policy.dart';
import '../locale/locale_conversion.dart';
import '../payload/media_data.dart';
import 'localized.dart';
import 'value_codec.dart';

ImageData _imageFromJson(Object? json) => ImageData.fromJson(json);
Object? _imageToJson(ImageData value) => value.toJson();
AudioData _audioFromJson(Object? json) => AudioData.fromJson(json);
Object? _audioToJson(AudioData value) => value.toJson();
VideoData _videoFromJson(Object? json) => VideoData.fromJson(json);
Object? _videoToJson(VideoData value) => value.toJson();
SpeechData _speechFromJson(Object? json) => SpeechData.fromJson(json);
Object? _speechToJson(SpeechData value) => value.toJson();

/// Codec for [ImageData].
const LocalizedValueCodec<ImageData> imageDataCodec =
    LocalizedValueCodec<ImageData>(
      fromJson: _imageFromJson,
      toJson: _imageToJson,
    );

/// Codec for [AudioData].
const LocalizedValueCodec<AudioData> audioDataCodec =
    LocalizedValueCodec<AudioData>(
      fromJson: _audioFromJson,
      toJson: _audioToJson,
    );

/// Codec for [VideoData].
const LocalizedValueCodec<VideoData> videoDataCodec =
    LocalizedValueCodec<VideoData>(
      fromJson: _videoFromJson,
      toJson: _videoToJson,
    );

/// Codec for [SpeechData].
const LocalizedValueCodec<SpeechData> speechDataCodec =
    LocalizedValueCodec<SpeechData>(
      fromJson: _speechFromJson,
      toJson: _speechToJson,
    );

/// An image that differs by locale -- a diagram with baked-in text, a flag, a
/// screenshot of a translated interface.
final class LocalizedImage extends Localized<ImageData> {
  /// Creates an image over already-canonical tags.
  const LocalizedImage(this.variants, {this.fallback});

  /// Creates an image, canonicalising the locale keys.
  factory LocalizedImage.values(
    Map<String, ImageData> values, {
    FallbackPolicy? fallback,
  }) => LocalizedImage(_tag(values), fallback: fallback);

  /// Reads from a locale-keyed JSON object.
  factory LocalizedImage.fromJson(Object? json, [String path = r'$']) =>
      LocalizedImage(
        decodeLocalized<ImageData>(json, imageDataCodec, path: path).variants,
      );

  @override
  final Map<LocaleTag, ImageData> variants;

  @override
  final FallbackPolicy? fallback;

  @override
  LocalizedValueCodec<ImageData> get codec => imageDataCodec;
}

/// An audio clip that differs by locale.
final class LocalizedAudio extends Localized<AudioData> {
  /// Creates audio over already-canonical tags.
  const LocalizedAudio(this.variants, {this.fallback});

  /// Creates audio, canonicalising the locale keys.
  factory LocalizedAudio.values(
    Map<String, AudioData> values, {
    FallbackPolicy? fallback,
  }) => LocalizedAudio(_tag(values), fallback: fallback);

  /// Reads from a locale-keyed JSON object.
  factory LocalizedAudio.fromJson(Object? json, [String path = r'$']) =>
      LocalizedAudio(
        decodeLocalized<AudioData>(json, audioDataCodec, path: path).variants,
      );

  @override
  final Map<LocaleTag, AudioData> variants;

  @override
  final FallbackPolicy? fallback;

  @override
  LocalizedValueCodec<AudioData> get codec => audioDataCodec;
}

/// A video that differs by locale, including its poster and caption track.
final class LocalizedVideo extends Localized<VideoData> {
  /// Creates video over already-canonical tags.
  const LocalizedVideo(this.variants, {this.fallback});

  /// Creates video, canonicalising the locale keys.
  factory LocalizedVideo.values(
    Map<String, VideoData> values, {
    FallbackPolicy? fallback,
  }) => LocalizedVideo(_tag(values), fallback: fallback);

  /// Reads from a locale-keyed JSON object.
  factory LocalizedVideo.fromJson(Object? json, [String path = r'$']) =>
      LocalizedVideo(
        decodeLocalized<VideoData>(json, videoDataCodec, path: path).variants,
      );

  @override
  final Map<LocaleTag, VideoData> variants;

  @override
  final FallbackPolicy? fallback;

  @override
  LocalizedValueCodec<VideoData> get codec => videoDataCodec;
}

/// Spoken audio with its own timing track per locale.
///
/// The speech-animation case: one line of dialogue, several languages, each
/// with its own recording and its own cue timings, because a mouth moves
/// differently in Czech than in English.
final class LocalizedSpeech extends Localized<SpeechData> {
  /// Creates speech over already-canonical tags.
  const LocalizedSpeech(this.variants, {this.fallback});

  /// Creates speech, canonicalising the locale keys.
  factory LocalizedSpeech.values(
    Map<String, SpeechData> values, {
    FallbackPolicy? fallback,
  }) => LocalizedSpeech(_tag(values), fallback: fallback);

  /// Reads from a locale-keyed JSON object.
  factory LocalizedSpeech.fromJson(Object? json, [String path = r'$']) =>
      LocalizedSpeech(
        decodeLocalized<SpeechData>(json, speechDataCodec, path: path).variants,
      );

  @override
  final Map<LocaleTag, SpeechData> variants;

  @override
  final FallbackPolicy? fallback;

  @override
  LocalizedValueCodec<SpeechData> get codec => speechDataCodec;
}

Map<LocaleTag, T> _tag<T>(Map<String, T> values) => <LocaleTag, T>{
  for (final MapEntry<String, T> entry in values.entries)
    parseLocaleTag(entry.key): entry.value,
};
