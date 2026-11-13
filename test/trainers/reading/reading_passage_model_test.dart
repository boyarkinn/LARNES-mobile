import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/reading/shared/content_bank.dart';
import 'package:larnes_mobile/trainers/reading/reading_reread/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_blocks/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_echo/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_flash/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_find_span/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_maze/model.dart';

void main() {
  test('no params or retired passage id resolves local text', () {
    expect(resolvePassageText({'passageId': 'short-window'}), isEmpty);
    expect(
      resolvePassageText({'source': 'custom', 'customText': 'Unprepared'}),
      isEmpty,
    );
    expect(validatePassageAssignment({'passageId': 'short-window'}), isNotNull);
    expect(
      validatePassageAssignment({
        'contentBank': {
          'libraryId': readingContentBankLibraryId,
          'materialIds': ['11111111-1111-4111-8111-111111111111'],
        },
      }),
      isNull,
    );
  });
  test('old complete literal snapshot stays playable after source changes', () {
    final params = {
      'passageId': 'removed',
      '__runtimeSnapshot': {
        'version': 1,
        'trainerKey': 'reading-vanish',
        'mode': 'materialized',
        'payload': {'text': 'Лист упал.', 'letterPauseMs': 180},
      },
    };
    expect(resolvePassageText(params), 'Лист упал.');
    expect(hasPreparedReadingContent('reading-vanish', params), isTrue);
    expect(
      passagePlayFromSnapshot({
        'text': 'Лист упал.',
        'letterPauseMs': 180,
      })?.text,
      'Лист упал.',
    );
    expect(
      hasPreparedReadingContent('reading-vanish', {
        '__runtimeSnapshot': {
          'version': 1,
          'trainerKey': 'reading-vanish',
          'mode': 'materialized',
          'payload': {'seed': 42},
        },
      }),
      isFalse,
    );
  });
  test('reread supports multiple questions and 2 to 20 answers', () {
    final questions = readingRereadQuestionsFromPayload({
      'questions': [
        {
          'prompt': 'Первый?',
          'choices': ['А', 'Б'],
          'correctIndex': 1,
        },
        {
          'prompt': 'Второй?',
          'choices': ['А', 'Б', 'В', 'Г'],
          'correctIndex': 3,
        },
      ],
    });
    expect(questions, hasLength(2));
    expect(questions.last.correctIndex, 3);
    expect(
      readingRereadQuestionFromPayload({
        'prompt': 'Ошибка?',
        'choices': ['А', 'Б'],
        'correctIndex': 2,
      }),
      isNull,
    );
    expect(
      readingRereadQuestionsFromPayload({
        'question': {
          'prompt': 'Прежний?',
          'choices': ['А', 'Б', 'В'],
          'correctIndex': 0,
        },
      }),
      hasLength(1),
    );
  });
  test('pure reading transformations keep Unicode and line ordering', () {
    expect(readingBlockLines('А б в г д', 2), ['А б', 'в г', 'д']);
    expect(splitReadingEchoSentences('Лист упал. Стало тихо.'), [
      'Лист упал.',
      'Стало тихо.',
    ]);
    expect(readingFlashChunks('Лист упал.', 'letters').take(4), [
      'Лис',
      'туп',
      'ал',
    ]);
    expect(readingFindTargetIndexes(readingFindWords('Лист упал.'), ['Лист']), [
      0,
    ]);
    expect(readingMazeNeighbors(0, 1), isTrue);
    expect(readingMazeNeighbors(0, 4), isFalse);
  });
}
