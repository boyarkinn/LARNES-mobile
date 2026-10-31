import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/flash_audio_tempo.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/resolve_step_audio.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/generate.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';

void main() {
  group('topic-chain-flash audio QA (progon 19)', () {
    test('tempo mute/rate for 0.5 / 1 / 2', () {
      expect(shouldPlayFlashAudio(0.5), isFalse);
      expect(shouldPlayFlashAudio(1), isTrue);
      expect(shouldPlayFlashAudio(2), isTrue);
      expect(flashAudioPlaybackRate(1), 2);
      expect(flashAudioPlaybackRate(2), 2);
      expect(flashAudioPlaybackRate(5), 2);
    });

    test('without a catalog file the chain does not speak a bundled number', () {
      for (final topicId in ['simple-1', 'simple-hundreds']) {
        final validated = validateTrainerParams('topic-chain-flash', {
          'topicId': topicId,
          'actionCount': 5,
          'stepPauseSec': 1,
        });
        expect(validated.ok, isTrue, reason: validated.error);

        final chain = generateChain(
          GenerateConfig(topicId: topicId, actionCount: 5, signMode: 'mix'),
        );

        for (final step in chain.steps) {
          final resolved = resolveStepAudio(step);
          expect(resolved.assets, isEmpty);
          expect(resolved.operationAsset, isEmpty);
          expect(resolved.amountAssets, isEmpty);
        }
      }
    });

    test('mobile clips are preloaded but never overlap', () {
      final source = File(
        'lib/trainers/mental_arithmetic/audio/clip_player.dart',
      ).readAsStringSync();

      expect(RegExp(r'player\s*\.setAudioSources\(').hasMatch(source), isTrue);
      expect(source, contains("AudioSource.asset('assets/\$path')"));
      expect(source, contains('preload: true'));
      expect(RegExp(r'AudioPlayer\(\)').allMatches(source).length, 1);
      expect(source, isNot(contains('onPlayerComplete')));
      expect(source, isNot(contains('handoffMs')));
    });

    test('flash timer starts from actual mobile audio start', () {
      final playerSource = File(
        'lib/trainers/mental_arithmetic/audio/clip_player.dart',
      ).readAsStringSync();
      final trainerSource = File(
        'lib/trainers/mental_arithmetic/topic_chain_flash/'
        'topic_chain_flash_trainer.dart',
      ).readAsStringSync();

      expect(playerSource, contains('onStarted?.call()'));
      expect(trainerSource, contains('onStarted: startStepTimer'));
      expect(trainerSource, contains('void startStepTimer()'));
    });
  });
}
