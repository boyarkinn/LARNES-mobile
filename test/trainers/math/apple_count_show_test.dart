import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_show_choreography.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_show_model.dart';

void main() {
  group('normalizeDigit / digitToAppleCount', () {
    test('truncates and clamps negatives to zero', () {
      expect(normalizeDigit(-3), 0);
      expect(normalizeDigit(2.9), 2);
    });

    test('maps digit to apple count 1:1', () {
      expect(digitToAppleCount(0), 0);
      expect(digitToAppleCount(5), 5);
      expect(digitToAppleCount(12), 12);
    });
  });

  group('buildAppleDropSequence', () {
    test('returns empty sequence for zero apples', () {
      expect(buildAppleDropSequence(0), isEmpty);
    });

    test('staggers each apple drop', () {
      final steps = buildAppleDropSequence(3);

      expect(steps.length, 3);
      expect(steps[0].delayMs, 0);
      expect(steps[1].delayMs, appleDropStaggerMs);
      expect(steps[2].delayMs, appleDropStaggerMs * 2);
    });

    test('moves apples from spawn above into basket slots', () {
      final steps = buildAppleDropSequence(2);

      expect(steps[0].from.y < steps[0].to.y, isTrue);
      expect(steps[1].from.y < steps[1].to.y, isTrue);
      expect(steps[0].to.x == steps[1].to.x && steps[0].to.y == steps[1].to.y, isFalse);
    });
  });
}
