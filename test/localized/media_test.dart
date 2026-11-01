import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:lexicanum/lexicanum.dart';

void main() {
  group('the speech-animation case', () {
    // One line of dialogue, two languages, each with its own recording and its
    // own cue timings -- a mouth moves differently in Czech than in English.
    final LocalizedSpeech greeting = LocalizedSpeech.values(
      <String, SpeechData>{
        'en': SpeechData(
          audio: AudioData(
            source: Uri.parse('asset:///speech/hello_en.m4a'),
            duration: const Duration(milliseconds: 900),
            transcript: 'Hello there',
          ),
          cues: const <SpeechCue>[
            SpeechCue(at: Duration.zero, value: 'HH'),
            SpeechCue(at: Duration(milliseconds: 180), value: 'EH'),
          ],
        ),
        'cs': SpeechData(
          audio: AudioData(
            source: Uri.parse('asset:///speech/hello_cs.m4a'),
            duration: const Duration(milliseconds: 1100),
            transcript: 'Dobrý den',
          ),
          cues: const <SpeechCue>[
            SpeechCue(at: Duration.zero, value: 'D'),
            SpeechCue(at: Duration(milliseconds: 240), value: 'O'),
          ],
        ),
      },
    );

    test('resolves audio and timing together as one value', () {
      final SpeechData cs = greeting.resolve(const Locale('cs', 'CZ'));
      expect(cs.audio.source.path, endsWith('hello_cs.m4a'));
      expect(cs.cues.first.value, 'D');
      expect(cs.audio.duration, const Duration(milliseconds: 1100));
    });

    test('a different locale brings a different timing track', () {
      expect(
        greeting.resolve(const Locale('en')).cues.last.at,
        const Duration(milliseconds: 180),
      );
      expect(
        greeting.resolve(const Locale('cs')).cues.last.at,
        const Duration(milliseconds: 240),
      );
    });

    test('round-trips through JSON', () {
      expect(LocalizedSpeech.fromJson(greeting.toJson()), greeting);
    });
  });

  group('image, audio and video', () {
    test('per-locale alt text comes free from the container', () {
      // Because the container holds one ImageData per locale, everything on
      // it is per-locale -- which is why a locale-varying image is more than
      // a locale-varying URL.
      final LocalizedImage hero = LocalizedImage.values(<String, ImageData>{
        'en': ImageData(source: Uri.parse('a.png'), alt: 'A cat'),
        'cs': ImageData(source: Uri.parse('b.png'), alt: 'Kočka'),
      });
      expect(hero.resolve(const Locale('cs')).alt, 'Kočka');
      expect(hero.resolve(const Locale('en')).alt, 'A cat');
    });

    test(
      'optional fields are omitted from JSON rather than written as null',
      () {
        final ImageData bare = ImageData(source: Uri.parse('a.png'));
        expect(bare.toJson(), <String, Object?>{'source': 'a.png'});
      },
    );

    test('video carries a per-locale poster and caption track', () {
      final LocalizedVideo intro = LocalizedVideo.values(<String, VideoData>{
        'en': VideoData(
          source: Uri.parse('intro_en.webm'),
          poster: Uri.parse('poster_en.png'),
          captions: Uri.parse('intro_en.vtt'),
        ),
      });
      final VideoData resolved = intro.resolve(const Locale('en'));
      expect(resolved.captions.toString(), 'intro_en.vtt');
      expect(LocalizedVideo.fromJson(intro.toJson()), intro);
    });

    test('audio round-trips with its duration', () {
      final LocalizedAudio clip = LocalizedAudio.values(<String, AudioData>{
        'en': AudioData(
          source: Uri.parse('a.m4a'),
          duration: const Duration(seconds: 3),
        ),
      });
      expect(LocalizedAudio.fromJson(clip.toJson()), clip);
    });

    test('a malformed payload names the field that failed', () {
      expect(
        () => LocalizedImage.fromJson(<String, Object?>{
          'en': <String, Object?>{'source': 42},
        }),
        throwsA(
          isA<LexicanumFormatException>().having(
            (LexicanumFormatException e) => e.message,
            'message',
            contains('source'),
          ),
        ),
      );
    });
  });
}
