import 'package:larnes_mobile/trainers/math/digit_trace/trace_reveal.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';

/// Web: `platform/src/trainers/reading/letter-case-match/case-match-reveal.ts`

int getCaseMatchRevealStartMs() {
  return traceGuidePopDurationMs;
}

int getCaseMatchCardRevealDelayMs(int index, int cardCount) {
  return getCaseMatchRevealStartMs() + getFruitRevealDelayMs(index, cardCount);
}

int getCaseMatchInteractionReadyMs(int cardCount) {
  return getCaseMatchRevealStartMs() + getFruitRevealTotalMs(cardCount) + 120;
}
