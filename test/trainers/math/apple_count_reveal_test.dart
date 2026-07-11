import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_reveal.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_show_choreography.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_sizes.dart';

void main() {
  group('getAppleDropCompleteMs', () {
    test('returns basket reveal time for empty basket', () {
      expect(getAppleDropCompleteMs(0), appleBasketRevealMs);
    });

    test('waits for the last apple flight to finish', () {
      const appleCount = 3;

      expect(
        getAppleDropCompleteMs(appleCount),
        appleBasketRevealMs +
            (appleCount - 1) * appleDropStaggerMs +
            appleFlightDurationMs,
      );
    });
  });
}
