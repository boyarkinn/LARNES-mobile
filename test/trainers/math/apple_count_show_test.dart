import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_show_model.dart';

void main() {
  group('normalizeTargetCount', () {
    test('clamps to 1-9', () {
      expect(normalizeTargetCount(-3), 1);
      expect(normalizeTargetCount(4), 4);
      expect(normalizeTargetCount(15), 9);
    });
  });

  group('normalizeTotalApples', () {
    test('clamps to 1-15', () {
      expect(normalizeTotalApples(0), 1);
      expect(normalizeTotalApples(5), 5);
      expect(normalizeTotalApples(20), 15);
    });
  });

  group('normalizeTargetDisplay', () {
    test('defaults to with_digit', () {
      expect(normalizeTargetDisplay(null), targetDisplayWithDigit);
      expect(normalizeTargetDisplay('audio_only'), targetDisplayAudioOnly);
    });
  });

  group('interactive apple flow', () {
    test('tracks basket count and reshuffles on error', () {
      final initial = buildInitialApples(4, 2, targetDisplayWithDigit);
      final withTwo = moveAppleToBasket(moveAppleToBasket(initial, 'apple-0'), 'apple-1');

      expect(isCorrectBasketCount(2, 2), isTrue);
      expect(isCorrectBasketCount(1, 2), isFalse);

      final reshuffled = reshuffleAllApplesToField(
        withTwo,
        4,
        2,
        targetDisplayWithDigit,
        1,
      );
      expect(reshuffled.every((apple) => apple.zone == AppleEntity.zoneField), isTrue);
    });
  });
}
