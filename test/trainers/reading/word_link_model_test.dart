import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_word_link/word_link_model.dart';

void main() {
  test(
    'frozen labels determine matching and completion after source removal',
    () {
      final round = wordLinkRoundFromPayload({
        'round': {
          'letter': 'Л',
          'displayLetter': 'л',
          'wordItems': [
            {
              'id': 'one',
              'slug': 'new-one',
              'label': 'лист',
              'displayLabel': 'ЛИСТ',
              'isMatch': true,
            },
            {
              'id': 'two',
              'slug': 'new-two',
              'label': 'река',
              'displayLabel': 'РЕКА',
              'isMatch': false,
            },
          ],
        },
      })!;
      expect(isCorrectWordLink(round.wordItems.first, 'Л'), isTrue);
      expect(isCorrectWordLink(round.wordItems.last, 'Л'), isFalse);
      expect(isWordLinkRoundComplete([], round), isFalse);
      expect(
        isWordLinkRoundComplete([
          const WordLinkConnection(rightId: 'one', slug: 'new-one'),
        ], round),
        isTrue,
      );
      expect(wordLinkRoundFromPayload({'seed': 42}), isNull);
    },
  );
}
