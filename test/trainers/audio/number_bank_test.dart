import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/audio/number_bank.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/resolve_step_audio.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

void main() {
  tearDown(() => setNumberAudioFiles(const {}));

  test(
    'shared English and Arabic numbers use the correct fragments and word order',
    () {
      expect(amountAudioKeys(123, 'en-US'), [
        'number:hundreds:100',
        'number:20',
        'number:3',
      ]);
      expect(amountAudioKeys(123, 'ar-XA'), [
        'number:hundreds:100',
        numberBankAndKey,
        'number:3',
        numberBankAndKey,
        'number:20',
      ]);
      for (final locale in ['ru-RU', 'en-US', 'ar-XA']) {
        for (var value = 0; value <= 999; value++) {
          final keys = amountAudioKeys(value, locale);
          expect(keys, isNotEmpty);
          expect(keys.every(isNumberBankAudioKey), isTrue);
        }
        final keys = stepAudioKeys(amount: 123, sign: '+', locale: locale);
        setNumberAudioFiles({
          for (final key in keys)
            key: NumberAudioFile(
              durationMs: 250,
              path: 'cache/$locale/$key.mp3',
            ),
        }, locale: locale);
        expect(
          resolveStepAudio(const ChainStep(amount: 123, sign: '+')).assets,
          keys.map((key) => 'cache/$locale/$key.mp3').toList(),
        );
      }
    },
  );

  test('a composite stays sign, hundreds, then the rest', () {
    expect(stepAudioKeys(amount: 123, sign: '+'), [
      'operation:plus',
      'number:hundreds:100',
      'number:23',
    ]);
    expect(getAmountAudioAssets(100), isEmpty);
    expect(getAmountAudioAssets(154), isEmpty);
    expect(
      resolveStepAudio(const ChainStep(amount: 8, sign: '-')).assets,
      isEmpty,
    );
  });

  test('a published file replaces the old asset and keeps a natural tempo', () {
    setNumberAudioFiles({
      'number:8': const NumberAudioFile(
        durationMs: 500,
        path: r'C:\cache\eight.mp3',
      ),
    });

    expect(getAmountAudioAssets(8), [r'C:\cache\eight.mp3']);
    expect(catalogFlashPlaybackRate(1, [500]), 1);
    expect(catalogFlashPlaybackRate(1, [1800]), 1.8);
  });
}
