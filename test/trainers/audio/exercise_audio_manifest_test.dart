import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/audio/exercise_audio_manifest.dart';

void main() {
  test(
    'practice warmup keeps its instruction and removes missing action narration',
    () {
      final manifest = ExerciseAudioManifest.fromJson({
        'trainerKey': 'abacus-warmup',
        'catalogRevision': 1,
        'contentLocale': 'ru-RU',
        'instructionLocale': 'en-US',
        'clips': [
          {
            'bytes': 10,
            'durationMs': 900,
            'locale': 'en-US',
            'semanticKey': 'instruction:abacus-warmup',
            'required': true,
            'url': 'https://audio.larnes.ru/existing.mp3',
            'versionId': 'existing',
            'sha256': 'old',
          },
        ],
        'missing': [
          {
            'semanticKey': 'explanation:abacus-gesture:old',
            'locale': 'en-US',
            'reason': 'unpublished',
            'required': true,
          },
        ],
      })!;
      final scoped = scopeTrainerAudioForParams(manifest, 'abacus-warmup', {
        'withExplanations': false,
      })!;
      expect(scoped.clips.single.semanticKey, 'instruction:abacus-warmup');
      expect(scoped.missing, isEmpty);
      expect(
        scopeTrainerAudioForParams(
          manifest,
          'abacus-warmup',
          {},
        )!.clips.single.semanticKey,
        'instruction:abacus-warmup',
      );
      expect(
        identical(
          scopeTrainerAudioForParams(manifest, 'abacus-topic-explanation', {
            'withExplanations': false,
          }),
          manifest,
        ),
        true,
      );
    },
  );
  test('practice warmup drops obsolete block introductions', () {
    final manifest = ExerciseAudioManifest.fromJson({
      'trainerKey': 'abacus-warmup',
      'clips': [
        for (final type in ['simple-9', 'friends'])
          {
            'bytes': 10,
            'durationMs': 1000,
            'locale': 'ru-RU',
            'semanticKey': 'explanation:abacus-warmup:intro:$type',
            'url': 'https://audio.larnes.ru/$type.mp3',
          },
      ],
    })!;
    expect(
      scopeTrainerAudioForParams(manifest, 'abacus-warmup', {
        'warmupType': 'friends',
        'withExplanations': false,
      })!.clips,
      isEmpty,
    );
  });
  test(
    'mixed topics keep the one universal instruction and drop topic titles',
    () {
      final manifest = ExerciseAudioManifest.fromJson({
        'trainerKey': 'abacus-warmup',
        'clips': [
          for (final key in [
            'instruction:abacus-warmup',
            'explanation:abacus-topic:brother-4:intro',
            'explanation:abacus-topic:brother-1:intro',
          ])
            {
              'bytes': 10,
              'durationMs': 1000,
              'locale': 'en-US',
              'semanticKey': key,
              'required': false,
              'url': 'https://audio.larnes.ru/$key.mp3',
            },
        ],
      })!;
      final params = {
        'warmupType': 'brothers',
        'warmupTopics': ['simple-9:2', 'brothers:4', 'friends:9'],
        'withExplanations': false,
      };
      final scoped = scopeTrainerAudioForParams(
        manifest,
        'abacus-warmup',
        params,
      )!;
      expect(scoped.clips.single.semanticKey, 'instruction:abacus-warmup');
      expect(scoped.clips.single.url, contains('instruction:abacus-warmup'));
      expect(scoped.clips.single.isRequired, true);
      expect(
        scopeTrainerAudioForParams(
          scoped,
          'abacus-warmup',
          params,
        )!.clips.single.url,
        scoped.clips.single.url,
      );
    },
  );
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
    expect(
      audioForLaunch(fresh: fresh!, pinned: pinned).clips.single.versionId,
      'old',
    );
    expect(audioForLaunch(fresh: fresh).clips.single.versionId, 'new');
    expect(pinned.instructionLocale, 'en-US');
    expect(pinned.contentLocale, 'ru-RU');
  });
}
