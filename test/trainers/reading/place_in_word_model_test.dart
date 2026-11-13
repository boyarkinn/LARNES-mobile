import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/place_in_word_model.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_rules.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

void main() {
  test('decodes frozen tasks and exact pool ids, without a word catalogue', () {
    final payload = {
      'tasks': [
        {
          'slug': 'new-material',
          'before': 'Л',
          'after': 'СТ',
          'displayWord': 'ЛИСТ',
          'omitIndex': 1,
          'correctLetter': 'И',
        },
      ],
      'pool': [
        {'id': 'correct-0', 'letter': 'И', 'used': false},
      ],
    };
    final tasks = fillGapTasksFromPayload(payload);
    expect(tasks.single.displayWord, 'ЛИСТ');
    expect(tasks.single.before, 'Л');
    expect(letterPoolFromPayload(payload).single.id, 'correct-0');
    expect(fillGapTasksFromPayload({'seed': 4}), isEmpty);
  });
  test('letter rules keep Ё, priority and a bounded pool', () {
    expect(parseFillGapPracticeLetters('ё, е'), ['Ё', 'Е']);
    expect(
      resolveOmitForWord('Лист', ['И', 'Л']),
      const OmitResolution(omitIndex: 1, omitLetter: 'И'),
    );
    final tasks = fillGapTasksFromPayload({
      'tasks': [
        {
          'slug': 'new',
          'before': '',
          'after': 'ИСТ',
          'displayWord': 'ЛИСТ',
          'omitIndex': 0,
          'correctLetter': 'Л',
        },
      ],
    });
    final tiles = buildLetterPoolTiles(
      distractorCount: 2,
      letterCase: 'upper',
      rng: createSeededRng(9),
      tasks: tasks,
    );
    expect(tiles, hasLength(3));
    expect(tiles.where((tile) => tile.letter == 'Л'), hasLength(1));
    expect(canFitLetterPool(8, 8), isFalse);
  });
}
