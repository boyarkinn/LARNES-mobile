import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/audio/exercise_audio_manifest.dart';

void main() {
  test('a running launch keeps the old clip and drops a non-public url', () {
    final pinned = ExerciseAudioManifest.fromJson({
      'catalogRevision': 4,
      'clips': [
        {
          'bytes': 120,
          'durationMs': 900,
          'locale': 'en-US',
          'semanticKey': 'instruction:digit-find-tap',
          'sha256': 'old',
          'url': 'https://audio.larnes.ru/v1/old.mp3',
          'versionId': 'old',
        },
        {
          'bytes': 10,
          'durationMs': 10,
          'locale': 'en-US',
          'semanticKey': 'instruction:secret',
          'sha256': 'x',
          'url': 'http://drafts.example/secret.mp3',
          'versionId': 'draft',
        },
      ],
      'contentLocale': 'ru-RU',
      'instructionLocale': 'en-US',
      'missing': [],
      'trainerKey': 'digit-find-tap',
    });
    final fresh = ExerciseAudioManifest.fromJson({
      'catalogRevision': 5,
      'clips': [
        {
          'bytes': 140,
          'durationMs': 1000,
          'locale': 'en-US',
          'semanticKey': 'instruction:digit-find-tap',
          'sha256': 'new',
          'url': 'https://audio.larnes.ru/v1/new.mp3',
          'versionId': 'new',
        },
      ],
      'contentLocale': 'ru-RU',
      'instructionLocale': 'en-US',
      'missing': [],
      'trainerKey': 'digit-find-tap',
    });

    expect(pinned, isNotNull);
    expect(fresh, isNotNull);
    expect(pinned!.clips, hasLength(1));
    expect(audioForLaunch(fresh: fresh!, pinned: pinned).clips.single.versionId, 'old');
    expect(audioForLaunch(fresh: fresh).clips.single.versionId, 'new');
    expect(pinned.instructionLocale, 'en-US');
    expect(pinned.contentLocale, 'ru-RU');
  });
}
