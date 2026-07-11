import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/trace_reveal.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_case_match/case_match_reveal.dart';

void main() {
  group('case_match_reveal', () {
    test('matches web reveal start and card delay chain', () {
      expect(getCaseMatchRevealStartMs(), traceGuidePopDurationMs);
      expect(
        getCaseMatchCardRevealDelayMs(2, 4),
        traceGuidePopDurationMs + getFruitRevealDelayMs(2, 4),
      );
    });

    test('interaction ready follows fruit reveal total plus buffer', () {
      const cardCount = 4;

      expect(
        getCaseMatchInteractionReadyMs(cardCount),
        traceGuidePopDurationMs + getFruitRevealTotalMs(cardCount) + 120,
      );
    });
  });
}
