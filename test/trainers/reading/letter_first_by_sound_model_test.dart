import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_first_by_sound/letter_first_by_sound_model.dart';
import 'package:larnes_mobile/trainers/shared/first_words/resolve_first_word.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

void main() {
  group('letter-first-by-sound rounds', () {
    test('cycles practice letters across an explicit round count', () {
      expect(cyclePracticeLetters(['А', 'Д', 'Н'], 6), ['А', 'Д', 'Н', 'А', 'Д', 'Н']);
      expect(cyclePracticeLetters(['А'], 3), ['А', 'А', 'А']);
    });

    test('picks another word when the pool has more than one item', () {
      final pool = listFirstWordsByLetter('А');
      expect(pool.length, greaterThan(1));
      final first = pool.first.slug;
      final next = pickWordSlugForLetter('А', first, () => 0);
      expect(next, isNotNull);
      expect(next, isNot(first));
    });

    test('builds a 6-round А,Д,Н plan without repeating the same slug back-to-back', () {
      final plan = buildRoundPlan(
        letters: const ['А', 'Д', 'Н'],
        rng: createSeededRng(11),
        rounds: 6,
      );

      expect(plan, hasLength(6));
      expect(
        plan.map((round) => round.firstLetter).toList(),
        ['А', 'Д', 'Н', 'А', 'Д', 'Н'],
      );

      for (var index = 1; index < plan.length; index++) {
        expect(plan[index].slug, isNot(plan[index - 1].slug));
      }
    });
  });

  group('letter-first-by-sound choices', () {
    test('includes the target letter once', () {
      final choices = buildLetterChoices(
        BuildLetterChoicesInput(
          distractorCount: 3,
          firstLetter: 'Д',
          letterCase: 'upper',
          rng: createSeededRng(5),
        ),
      );

      expect(choices, hasLength(4));
      expect(choices.where((letter) => letter == 'Д').length, 1);
    });

    test('limits button count and matches case-aware answers', () {
      expect(canFitFirstBySoundChoices(3), isTrue);
      expect(canFitFirstBySoundChoices(8), isFalse);
      expect(isCorrectLetterChoice('А', 'lower', 'а'), isTrue);
      expect(isCorrectLetterChoice('А', 'upper', 'а'), isFalse);
    });
  });

  group('letter-first-by-sound practice letters', () {
    test('defaults empty input to А,Д,Н and rejects letters without a bank', () {
      expect(resolveFirstBySoundPracticeLetters(null), ['А', 'Д', 'Н']);
      expect(isValidFirstBySoundPracticeLetters('А,Д,Н'), isTrue);
      expect(isValidFirstBySoundPracticeLetters(''), isFalse);
      expect(isValidFirstBySoundPracticeLetters('Ъ'), isFalse);
    });
  });
}
