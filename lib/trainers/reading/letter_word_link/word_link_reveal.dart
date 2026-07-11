import 'package:larnes_mobile/trainers/math/digit_trace/trace_reveal.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';

/// Web: `platform/src/trainers/reading/letter-word-link/word-link-reveal.ts`

int getWordLinkLetterRevealTotalMs() {
  return traceGuidePopDurationMs;
}

int getWordLinkCardRevealDelayMs(int index, int cardCount) {
  return getWordLinkLetterRevealTotalMs() +
      getFruitRevealDelayMs(index, cardCount);
}

int getWordLinkInteractionReadyMs(int cardCount) {
  return getWordLinkLetterRevealTotalMs() +
      getFruitRevealTotalMs(cardCount) +
      120;
}
