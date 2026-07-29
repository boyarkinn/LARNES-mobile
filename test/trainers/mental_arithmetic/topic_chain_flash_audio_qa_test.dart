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
      expect(flashAudioPlaybackRate(2), 1);
    });

    test('resolves assets for simple-1 and simple-hundreds chains', () {
      for (final topicId in ['simple-1', 'simple-hundreds']) {
        final validated = validateTrainerParams('topic-chain-flash', {
          'topicId': topicId,
          'actionCount': 5,
          'signMode': 'mix',
          'stepPauseSec': 1,
        });
        expect(validated.ok, isTrue, reason: validated.error);

        final chain = generateChain(
          GenerateConfig(topicId: topicId, actionCount: 5, signMode: 'mix'),
        );

        for (final step in chain.steps) {
          final resolved = resolveStepAudio(step);
          expect(resolved.assets, isNotEmpty);
          expect(File('assets/${resolved.operationAsset}').existsSync(), isTrue);
          if (resolved.amountAsset != null) {
            expect(File('assets/${resolved.amountAsset}').existsSync(), isTrue);
          }
          if (topicId == 'simple-hundreds') {
            expect(resolved.amountAsset, contains('/hundreds/'));
          }
        }
      }
    });
  });
}
