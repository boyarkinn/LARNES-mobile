import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/number_composition/composition_reveal.dart';

void main() {
  group('composition-reveal', () {
    test('auto-advances demo after reveal and hold', () {
      expect(
        getDemoPhaseDurationMs(),
        getCompositionRevealTotalMs() + demoHoldAfterRevealMs,
      );
    });

    test('unlocks practice taps after equation reveal and answers', () {
      expect(getPracticeInteractionReadyMs(4) >= 2000, isTrue);
    });
  });
}
