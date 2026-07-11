import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_name_aloud/name_aloud_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_name_aloud/name_aloud_sizes.dart';

void main() {
  group('isValidNameAloudPracticeLetters', () {
    test('accepts comma-separated letters', () {
      expect(isValidNameAloudPracticeLetters('А,М,К'), isTrue);
    });

    test('rejects empty input', () {
      expect(isValidNameAloudPracticeLetters(''), isFalse);
    });
  });

  group('buildDisplayLetters', () {
    test('applies letter case', () {
      expect(buildDisplayLetters('А,М', 'lower'), ['а', 'м']);
    });

    test('preserves teacher order', () {
      expect(buildDisplayLetters('К,А,М', 'upper'), ['К', 'А', 'М']);
    });
  });

  group('getNameAloudTotalDisplayMs', () {
    test('calculates total slideshow duration', () {
      expect(getNameAloudTotalDisplayMs(3, 4), 12000);
    });
  });

  group('name aloud sizing', () {
    test('caps letter box like trace pad', () {
      expect(nameAloudBoxSize(800, 400), 340);
    });

    test('caps letter font size', () {
      expect(nameAloudLetterFontSize(800, 400), 160);
    });

    test('uses finish delay from settle and complete parts', () {
      expect(nameAloudFinishDelayMs, nameAloudSettlePulseMs + nameAloudCompleteDelayMs);
    });
  });
}
