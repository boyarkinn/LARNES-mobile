import 'package:larnes_mobile/trainers/math/digit_trace/trace_reveal.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';

/// Web: `platform/src/trainers/reading/letter-connect-dots/connect-dots-reveal.ts`

int getConnectDotsRevealStartMs() {
  return traceGuidePopDurationMs;
}

int getConnectDotRevealDelayMs(int index, int dotCount) {
  return getConnectDotsRevealStartMs() + getFruitRevealDelayMs(index, dotCount);
}

int getConnectDotsInteractionReadyMs(int dotCount) {
  return getConnectDotsRevealStartMs() +
      getFruitRevealTotalMs(dotCount) +
      120;
}
