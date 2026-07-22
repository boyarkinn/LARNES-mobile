import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/move_hints.dart';

List<String> overlayKeys({
  required String operation,
  required int operandA,
  required int operandB,
  required int totalRods,
}) {
  return resolveMoveOverlays(
    operation: operation,
    operandA: operandA,
    operandB: operandB,
    totalRods: totalRods,
  ).map((overlay) => '${overlay.kind}@${overlay.rodIndex}').toList();
}

void main() {
  group('resolveMoveOverlays', () {
    test('10 − 9: −10 on tens, +1 on ones', () {
      expect(
        overlayKeys(
          operation: 'subtract',
          operandA: 10,
          operandB: 9,
          totalRods: 2,
        ),
        ['earth-from-bar@0', 'earth-to-bar@1'],
      );
    });

    test('11 − 9: borrow from tens, +1 on ones', () {
      expect(
        overlayKeys(
          operation: 'subtract',
          operandA: 11,
          operandB: 9,
          totalRods: 2,
        ),
        ['earth-from-bar@0', 'earth-to-bar@1'],
      );
    });

    test('1 + 9: +10 on tens, −1 on ones', () {
      expect(
        overlayKeys(
          operation: 'add',
          operandA: 1,
          operandB: 9,
          totalRods: 2,
        ),
        ['earth-to-bar@0', 'earth-from-bar@1'],
      );
    });

    test('2 + 9: big friend of 10 on ones', () {
      expect(
        overlayKeys(
          operation: 'add',
          operandA: 2,
          operandB: 9,
          totalRods: 2,
        ),
        ['earth-to-bar@0', 'earth-from-bar@1'],
      );
    });

    test('6 + 3: direct add on ones', () {
      expect(
        overlayKeys(
          operation: 'add',
          operandA: 6,
          operandB: 3,
          totalRods: 2,
        ),
        ['earth-to-bar@1', 'earth-to-bar@1', 'earth-to-bar@1'],
      );
    });

    test('19 − 9: direct subtract on ones', () {
      expect(
        overlayKeys(
          operation: 'subtract',
          operandA: 19,
          operandB: 9,
          totalRods: 2,
        ),
        [
          'heaven-from-bar@1',
          'earth-from-bar@1',
          'earth-from-bar@1',
          'earth-from-bar@1',
          'earth-from-bar@1',
        ],
      );
    });

    test('5 − 1: small friend −5 +4 on ones', () {
      expect(
        overlayKeys(
          operation: 'subtract',
          operandA: 5,
          operandB: 1,
          totalRods: 1,
        ),
        [
          'heaven-from-bar@0',
          'earth-to-bar@0',
          'earth-to-bar@0',
          'earth-to-bar@0',
          'earth-to-bar@0',
        ],
      );
    });

    test('1 + 7: small friend +5 +2 on ones', () {
      expect(
        overlayKeys(
          operation: 'add',
          operandA: 1,
          operandB: 7,
          totalRods: 1,
        ),
        ['heaven-to-bar@0', 'earth-to-bar@0', 'earth-to-bar@0'],
      );
    });
  });
}
