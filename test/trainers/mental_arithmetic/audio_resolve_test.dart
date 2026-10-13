import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/flash_audio_tempo.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/resolve_step_audio.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

void main() {
  group('resolve_step_audio', () {
    test('maps +/− and 0…99 / hundreds', () {
      expect(getOperationAudioAsset('+'), '');
      expect(getOperationAudioAsset('-'), '');
      expect(getAmountAudioAsset(4), isNull);
      expect(getAmountAudioAsset(100), isNull);
      expect(getAmountAudioAsset(123), isNull);
      expect(getAmountAudioAssets(154), isEmpty);
      expect(getAmountAudioAssets(506), isEmpty);
    });

    test('resolveStepAudio queues sign then amount clip(s)', () {
      final resolved = resolveStepAudio(const ChainStep(amount: 4, sign: '+'));
      expect(resolved.assets, isEmpty);

      final composite =
          resolveStepAudio(const ChainStep(amount: 123, sign: '+'));
      expect(composite.assets, isEmpty);
    });
  });

  group('flash_audio_tempo', () {
    test('mute and rate match web', () {
      expect(shouldPlayFlashAudio(0.5), isFalse);
      expect(shouldPlayFlashAudio(0.7), isTrue);
      expect(flashAudioPlaybackRate(1), 2);
      expect(flashAudioPlaybackRate(2), 2);
      expect(flashAudioPlaybackRate(5), 2);
    });
  });
}
