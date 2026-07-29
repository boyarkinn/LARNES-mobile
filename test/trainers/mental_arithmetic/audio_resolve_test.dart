import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/flash_audio_tempo.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/resolve_step_audio.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

void main() {
  group('resolve_step_audio', () {
    test('maps +/− and 0…99 / hundreds', () {
      expect(
        getOperationAudioAsset('+'),
        'audio/ru/mental-arithmetic/operations/plus.mp3',
      );
      expect(
        getOperationAudioAsset('-'),
        'audio/ru/mental-arithmetic/operations/minus.mp3',
      );
      expect(
        getAmountAudioAsset(4),
        'audio/ru/mental-arithmetic/numbers/4.mp3',
      );
      expect(
        getAmountAudioAsset(100),
        'audio/ru/mental-arithmetic/hundreds/100.mp3',
      );
      expect(getAmountAudioAsset(123), isNull);
    });

    test('resolveStepAudio queues sign then amount', () {
      final resolved = resolveStepAudio(const ChainStep(amount: 4, sign: '+'));
      expect(resolved.assets, [
        'audio/ru/mental-arithmetic/operations/plus.mp3',
        'audio/ru/mental-arithmetic/numbers/4.mp3',
      ]);
    });
  });

  group('flash_audio_tempo', () {
    test('mute and rate match web', () {
      expect(shouldPlayFlashAudio(0.5), isFalse);
      expect(shouldPlayFlashAudio(0.7), isTrue);
      expect(flashAudioPlaybackRate(1), 2);
      expect(flashAudioPlaybackRate(2), 1);
      expect(flashAudioPlaybackRate(5), 1);
    });
  });
}
