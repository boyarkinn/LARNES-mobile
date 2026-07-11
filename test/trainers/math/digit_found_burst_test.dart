import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_found_burst.dart';

void main() {
  group('digit-found-burst', () {
    test('uses a short radial spark animation budget', () {
      expect(digitFoundBurstSparkCount, 8);
      expect(digitFoundBurstMs <= 600, isTrue);
      expect(digitFoundVanishMs, 380);
    });
  });
}
