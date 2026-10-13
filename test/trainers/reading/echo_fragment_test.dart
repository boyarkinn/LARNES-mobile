import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/audio/catalog_audio_store.dart';
import 'package:larnes_mobile/trainers/audio/exercise_audio_manifest.dart';
import 'package:larnes_mobile/trainers/reading/shared/echo_fragment.dart';

void main() {
  test(
    'standard Echo needs its narrator; custom text can explicitly omit one',
    () {
      const sentence = 'После дождя на дорожке блестели лужи.';
      final key = echoFragmentAudioKey('  $sentence  ');
      expect(key, echoFragmentAudioKey(sentence));
      expect(key, isNot(echoFragmentAudioKey('Другое предложение.')));
      expect(
        key,
        'passage:echo:3477fe72f55e964314b231838d3a087d3e34b8f4b5dde3e57de4612a123b430f',
      );
      expect(isEchoFragmentAudioKey(key), isTrue);

      final manifest = ExerciseAudioManifest(
        catalogRevision: 0,
        clips: const [],
        contentLocale: 'ru-RU',
        instructionLocale: 'ru-RU',
        missing: [
          MissingAudioBinding(
            locale: 'ru-RU',
            reason: 'unknown_slot',
            semanticKey: key,
          ),
        ],
        trainerKey: 'reading-echo',
      );
      expect(catalogExpectsStimuli(manifest), isTrue);
      final custom = ExerciseAudioManifest(
        catalogRevision: 0,
        clips: const [],
        contentLocale: 'ru-RU',
        instructionLocale: 'ru-RU',
        missing: [
          MissingAudioBinding(
            locale: 'ru-RU',
            reason: 'unknown_slot',
            semanticKey: key,
            required: false,
          ),
        ],
        trainerKey: 'reading-echo',
      );
      expect(catalogExpectsStimuli(custom), isFalse);
    },
  );
}
