import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_build/build_reveal.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/trace_reveal.dart';

void main() {
  group('build_reveal', () {
    test('matches web stick reveal timing chain', () {
      expect(getGhostRevealTotalMs(), traceGuidePopDurationMs);
      expect(getStickRevealDelayMs(0, 3), getGhostRevealTotalMs());
      expect(
        getBuildInteractionReadyMs(3),
        getStickRevealTotalMs(3) + 120,
      );
    });
  });
}
