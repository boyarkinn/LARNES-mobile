import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/audio/number_bank.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/resolve_step_audio.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

void main() {
  tearDown(() => setNumberAudioFiles(const {}));

  test('a composite stays sign, hundreds, then the rest', () {
    expect(stepAudioKeys(amount: 123, sign: '+'), [
      'operation:plus',
      'number:hundreds:100',
      'number:23',
    ]);
    expect(getAmountAudioAssets(100), ['audio/ru/mental-arithmetic/hundreds/100.mp3']);
    expect(getAmountAudioAssets(154), [
      'audio/ru/mental-arithmetic/hundreds/100.mp3',
      'audio/ru/mental-arithmetic/numbers/54.mp3',
    ]);
    expect(resolveStepAudio(const ChainStep(amount: 8, sign: '-')).assets.first, contains('minus.mp3'));
  });

  test('a published file replaces the old asset and keeps a natural tempo', () {
    setNumberAudioFiles({
      'number:8': const NumberAudioFile(durationMs: 500, path: r'C:\cache\eight.mp3'),
    });

    expect(getAmountAudioAssets(8), [r'C:\cache\eight.mp3']);
    expect(catalogFlashPlaybackRate(1, [500]), 1);
    expect(catalogFlashPlaybackRate(1, [1800]), 1.8);
  });
}
