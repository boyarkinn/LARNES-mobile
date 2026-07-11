import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_show_choreography.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_sizes.dart';

/// Web v2: `platform/src/trainers/math/apple-count-show/apple-count-reveal.ts`

int getAppleDropCompleteMs(int appleCount) {
  if (appleCount <= 0) {
    return appleBasketRevealMs;
  }

  return appleBasketRevealMs +
      (appleCount - 1) * appleDropStaggerMs +
      appleFlightDurationMs;
}
