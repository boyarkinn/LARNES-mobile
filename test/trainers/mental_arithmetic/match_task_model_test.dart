import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/match_task_model.dart';

void main() {
  group('buildMatchTaskPlan', () {
    test('builds deterministic plans for the same seed', () {
      final first = buildMatchTaskPlan(7, 42);
      final second = buildMatchTaskPlan(7, 42);

      expect(first.targetDigitId, second.targetDigitId);
      expect(first.targetAbacusId, second.targetAbacusId);
      expect(first.dotsValue, second.dotsValue);
      expect(
        first.digitItems.map((item) => '${item.id}:${item.value}').toList(),
        second.digitItems.map((item) => '${item.id}:${item.value}').toList(),
      );
      expect(
        first.abacusItems.map((item) => '${item.id}:${item.value}').toList(),
        second.abacusItems.map((item) => '${item.id}:${item.value}').toList(),
      );
    });

    test('includes target value and distractors in both columns', () {
      final plan = buildMatchTaskPlan(4, 11);

      expect(plan.digitItems.length, matchTaskOptionCount);
      expect(plan.abacusItems.length, matchTaskOptionCount);
      expect(plan.dotsValue, 4);
      expect(plan.targetValue, 4);
      expect(plan.digitItems.any((item) => item.value == 4), isTrue);
      expect(plan.abacusItems.any((item) => item.value == 4), isTrue);
    });

    test('never uses target value as distractor', () {
      for (var seed = 0; seed < 20; seed++) {
        final plan = buildMatchTaskPlan(5, seed);
        final digitDistractors = plan.digitItems.where(
          (item) => !item.isTarget,
        );
        final abacusDistractors = plan.abacusItems.where(
          (item) => !item.isTarget,
        );

        expect(
          digitDistractors.every((item) => item.value != plan.targetValue),
          isTrue,
        );
        expect(
          abacusDistractors.every((item) => item.value != plan.targetValue),
          isTrue,
        );
      }
    });
  });

  group('match task flow', () {
    test('requires dots-digit before digit-abacus', () {
      expect(getMatchTaskStep(const []), MatchTaskStep.dotsToDigit);

      const afterDots = [
        MatchTaskConnection(
          fromId: dotsSourceId,
          kind: MatchTaskConnectionKind.dotsDigit,
          toId: 'digit-4-0',
          value: 4,
        ),
      ];

      expect(getMatchTaskStep(afterDots), MatchTaskStep.digitToAbacus);
      expect(isMatchTaskComplete(afterDots), isFalse);

      const complete = [
        MatchTaskConnection(
          fromId: dotsSourceId,
          kind: MatchTaskConnectionKind.dotsDigit,
          toId: 'digit-4-0',
          value: 4,
        ),
        MatchTaskConnection(
          fromId: 'digit-4-0',
          kind: MatchTaskConnectionKind.digitAbacus,
          toId: 'abacus-4-1',
          value: 4,
        ),
      ];

      expect(getMatchTaskStep(complete), MatchTaskStep.complete);
      expect(isMatchTaskComplete(complete), isTrue);
    });
  });
}
