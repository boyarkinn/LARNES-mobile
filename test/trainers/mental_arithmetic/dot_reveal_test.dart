import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dot_reveal.dart';

void main() {
  group('getDotPhaseDurationMs', () {
    test('returns zero for empty count', () {
      expect(getDotPhaseDurationMs(0), 0);
    });

    test('waits one interval per dot before the next scene beat', () {
      expect(getDotPhaseDurationMs(1), kDotRevealIntervalMs);
      expect(getDotPhaseDurationMs(3), kDotRevealIntervalMs * 3);
    });
  });
}
