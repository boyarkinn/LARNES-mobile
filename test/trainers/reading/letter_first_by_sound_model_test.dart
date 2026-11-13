import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_first_by_sound/letter_first_by_sound_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

void main() {
  test('server rounds keep word, audio and choices without a local lookup', () {
    final rounds = firstBySoundRoundsFromPayload({
      'rounds': [
        {
          'slug': 'new-material',
          'label': 'лист',
          'firstLetter': 'Л',
          'choices': ['М', 'Л'],
          'audio': {'semanticKey': 'stimulus:content-bank:v1'},
        },
      ],
    });
    expect(rounds.single.label, 'лист');
    expect(rounds.single.choices, ['М', 'Л']);
    expect(rounds.single.audioKey, 'stimulus:content-bank:v1');
    expect(firstBySoundRoundsFromPayload({'seed': 42}), isEmpty);
  });
  test(
    'alphabet choices and case checks remain independent of word content',
    () {
      final choices = buildLetterChoices(
        BuildLetterChoicesInput(
          distractorCount: 3,
          firstLetter: 'Л',
          letterCase: 'lower',
          rng: createSeededRng(5),
        ),
      );
      expect(choices, hasLength(4));
      expect(choices.where((value) => value == 'л'), hasLength(1));
      expect(isCorrectLetterChoice('Л', 'lower', 'л'), isTrue);
      expect(canFitFirstBySoundChoices(8), isFalse);
      expect(cyclePracticeLetters(['Л', 'Р'], 3), ['Л', 'Р', 'Л']);
    },
  );
}
