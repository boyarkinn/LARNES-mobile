import 'package:larnes_mobile/trainers/math/digit_trace/trace_reveal.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';

/// Web: `platform/src/trainers/reading/letter-build/build-reveal.ts`

int getGhostRevealTotalMs() {
  return traceGuidePopDurationMs;
}

int getStickRevealDelayMs(int index, int pieceCount) {
  return getGhostRevealTotalMs() + getFruitRevealDelayMs(index, pieceCount);
}

int getStickRevealTotalMs(int pieceCount) {
  return getGhostRevealTotalMs() + getFruitRevealTotalMs(pieceCount);
}

int getBuildInteractionReadyMs(int pieceCount) {
  return getStickRevealTotalMs(pieceCount) + 120;
}
