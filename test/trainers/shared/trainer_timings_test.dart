import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

void main() {
  group('TrainerTimings web parity', () {
    test('tap feedback and complete delays', () {
      expect(TrainerTimings.wrongFeedbackMs, 550);
      expect(TrainerTimings.completeDelayMs, 900);
      expect(TrainerTimings.phaseAdvanceMs, 800);
    });

    test('burst-based complete matches digit/letter found burst', () {
      expect(TrainerTimings.foundBurstMs, 520);
      expect(TrainerTimings.completeAfterBurstMs, 700);
    });

    test('match and flashcard timings', () {
      expect(TrainerTimings.wrongFlashMs, 450);
      expect(TrainerTimings.wrongConnectionFlashMs, 450);
      expect(TrainerTimings.flashcardCompleteDelayMs, 700);
    });

    test('reading-specific delays', () {
      expect(TrainerTimings.colorCompleteDelayMs, 300);
      expect(TrainerTimings.guideCompleteDelayMs, 600);
    });
  });
}
