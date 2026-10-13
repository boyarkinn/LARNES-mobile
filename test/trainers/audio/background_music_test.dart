import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/audio/background_music.dart';
import 'package:larnes_mobile/trainers/catalog/trainer_direction.dart';
import 'package:larnes_mobile/trainers/audio/catalog_audio_store.dart';
import 'package:larnes_mobile/trainers/audio/exercise_audio_manifest.dart';

void main() {
  test('unpublished music does not block and an unknown track does not start', () {
    expect(isBackgroundMusicAudioKey('music:background:17'), isTrue);
    expect(isBackgroundMusicAudioKey('music:background:18'), isFalse);
    expect(preparedBackgroundMusicPath('music:background:18'), isNull);
    expect(preparedBackgroundMusicPath('music:background:1'), isNull);

    setBackgroundMusicFiles({
      'music:background:1': BackgroundMusicFile(path: '/tmp/music.mp3'),
    });
    expect(preparedBackgroundMusicPath('music:background:1'), '/tmp/music.mp3');
    expect(preparedBackgroundMusicPath('music:background:2'), isNull);
    setBackgroundMusicFiles({});

    final manifest = ExerciseAudioManifest(
      catalogRevision: 1,
      clips: [
        PublishedAudioClip(
          bytes: 4,
          contentLocale: 'ru-RU',
          durationMs: 1000,
          locale: 'ru-RU',
          semanticKey: 'music:background:1',
          sha256: 'a' * 64,
          url: 'https://audio.larnes.ru/v1/${'a' * 64}.mp3',
          versionId: 'v1',
        ),
      ],
      contentLocale: 'ru-RU',
      instructionLocale: 'ru-RU',
      missing: const [],
      trainerKey: 'reading-vanish',
    );
    expect(catalogExpectsStimuli(manifest), isFalse);
  });

  test('a downloaded track is remembered and can start', () {
    var heard = 0;
    void listener() {
      heard += 1;
    }

    listenBackgroundMusic(listener);
    rememberBackgroundMusicFile('music:background:18', '/tmp/missing.mp3');
    expect(heard, 0);
    expect(backgroundMusicVolumeFor(TrainerDirection.mental), 0.02);
    expect(backgroundMusicVolumeFor(TrainerDirection.reading), 0.05);
    rememberBackgroundMusicFile('music:background:4', '/tmp/4.mp3');
    expect(preparedBackgroundMusicPath('music:background:4'), '/tmp/4.mp3');
    expect(pickPreparedBackgroundMusicPath((_) => 0), '/tmp/4.mp3');
    expect(heard, 1);
    unlistenBackgroundMusic(listener);
    setBackgroundMusicFiles({});
  });
}
