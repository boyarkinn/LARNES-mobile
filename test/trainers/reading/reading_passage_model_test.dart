import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/reading_noisy_text/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_pace_track/reading_pace_track_trainer.dart';
import 'package:larnes_mobile/trainers/reading/reading_pointer/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_blocks/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_tree/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_flash/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_fixation/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_diagonal/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_reread/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_echo/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_phrases/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_find_span/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_sprint/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_cloze/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_story_order/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_main_idea/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_anagram/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_maze/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_grid_mask/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_snake/model.dart';
import 'package:larnes_mobile/trainers/reading/reading_line_pace/model.dart';
import 'package:larnes_mobile/trainers/shared/first_words/resolve_first_word.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';

void main() {
  test('spaces vanish with the previous letter', () {
    final units = buildVanishUnits('А б');
    expect(units.map((unit) => '${unit.grapheme}:${unit.order}').toList(), [
      'А:1',
      ' :1',
      'б:2',
    ]);
  });

  test('extra letters are not lesson steps', () {
    final units = buildNoisyUnits('Аб', 'extra-letters');
    expect(units.where((unit) => !unit.noise).map((unit) => unit.grapheme), ['А', 'б']);
    expect(units.where((unit) => unit.noise).length, 2);
    expect(units.where((unit) => unit.noise).every((unit) => unit.order == 0), isTrue);
  });

  test('flip turns every other word', () {
    final units = buildNoisyUnits('А б', 'flip');
    expect(units.first.turned, isFalse);
    expect(units.where((unit) => unit.turned).map((unit) => unit.grapheme).join(), 'б');
  });

  test('pace clicks only on the metronome', () {
    expect(readingPaceTrackOf({'track': 'countdown'}), 'countdown');
    expect(readingPaceTrackOf({'track': 'metronome'}), 'metronome');
    expect(validateReadingPaceTrackRaw({'source': 'bank', 'passageId': 'short-window'}), isNull);
  });

  test('noisy snapshot keeps the frozen noise', () {
    final plan = readingNoisyTextPlanFromSnapshot({
      'letterPauseMs': 240,
      'noise': 'wave',
      'text': 'Кот.',
    });
    expect(plan?.noise, 'wave');
    expect(plan?.text, 'Кот.');
    expect(readingNoisyTextPlanFromParams({'source': 'bank'}).noise, 'strokes');
  });

  test('pointer marks the next letter', () {
    final units = buildVanishUnits('А б');
    expect(isPointerLetter(units.first, 0), isTrue);
    expect(isPointerLetter(units[1], 0), isFalse);
    expect(units.where((unit) => isPointerLetter(unit, 1)).map((unit) => unit.grapheme), ['б']);
  });

  test('blocks pack words and keep the remainder', () {
    expect(readingBlockLines('А б в г д', 2), ['А б', 'в г', 'д']);
    expect(readingBlocksWordsPerLine('2'), 2);
    expect(readingBlocksWordsPerLine('0'), 3);
  });

  test('tree grows, then shrinks', () {
    expect(readingTreeLines('Утром кот сел на окно и смотрел на тихий двор.'), [
      'Утром',
      'кот сел на',
      'окно и смотрел',
      'на тихий',
      'двор.',
    ]);
  });

  test('flash groups letters and packs a short line', () {
    expect(
      takeReadingFlashShows(readingFlashChunks('Утром кот сел на окно и смотрел на тихий двор.', 'letters'), 5),
      ['Утр', 'омк', 'отс', 'елн', 'аок'],
    );
    expect(readingFlashChunks('Утром кот сел на окно и смотрел на тихий двор.', 'line').take(2), [
      'Утром кот сел на',
      'окно и смотрел на',
    ]);
    expect(readingFlashDurationMs('50'), 600);
    expect(readingFlashShows('0'), 5);
    expect(readingFlashKind('line'), 'line');
  });

  test('fixation splits a word, a pair, and a sentence', () {
    expect(readingFixationFragments('А б в', 'word'), ['А', 'б', 'в']);
    expect(readingFixationFragments('А б в г д', 'pair'), ['А б', 'в г', 'д']);
    expect(readingFixationFragments('Кот спит. Дома тихо.', 'sentence'), ['Кот спит.', 'Дома тихо.']);
    expect(readingFixationFragments('Маша нашла красный мяч под старым кустом.', 'pair').take(2), [
      'Маша нашла',
      'красный мяч',
    ]);
    expect(readingFixationFragment('line'), 'pair');
    expect(readingFixationPauseMs('50'), 800);
  });

  test('diagonal steps each line further right', () {
    final lines = readingDiagonalLines('Утром кот сел на окно и смотрел на тихий двор.');
    expect(lines.map((line) => line.text), [
      'Утром кот',
      'сел на окно',
      'и смотрел на',
      'тихий двор.',
    ]);
    expect(lines.map((line) => line.step), [0, 1, 2, 3]);
    expect(
      readingDiagonalLines('абвгдежзик абвгдежзил абвгдежзим абвгдежзин абвгдежзио').map((line) => line.step),
      [0, 1, 2, 3, 0],
    );
  });

  test('reread compares two attempts and keeps the bank question', () {
    final gap = describeReadingRereadGap(
      ReadingRereadAttempt(elapsedMs: 3200, errors: 2),
      ReadingRereadAttempt(elapsedMs: 1800, errors: 1),
    );
    expect(gap.time, 'быстрее на 1,4 с');
    expect(gap.errors, 'меньше ошибок на 1');
    expect(passageById('short-window')?.question.prompt, 'Что делал кот?');
    expect(passageById('short-window')?.question.correctIndex, 1);
  });

  test('echo keeps the first sentences', () {
    final puddles = passageById('medium-puddles')!.text;
    expect(readingEchoFragment(puddles, 1), ['После дождя на дорожке блестели лужи.']);
    expect(readingEchoFragment(puddles, 2), splitReadingEchoSentences(puddles));
    expect(readingEchoSpan('9'), 1);
    expect(readingEchoPauseMs('900'), 900);
    expect(readingEchoSwitch('off'), 'off');
  });

  test('phrases stay cut by meaning and join back into the text', () {
    final window = passageById('short-window')!;
    expect(window.phrases, ['Утром', 'кот сел на окно', 'и смотрел на тихий двор.']);
    expect(joinReadingPhrases(window.phrases), window.text);
    expect(readingPhraseGaps(window.phrases), [0, 4]);
    expect(readingPhraseBoundaryVisible(0, 1), isFalse);
    expect(readingPhraseBoundaryVisible(1, 1), isTrue);
    expect(readingPhraseMode('place'), 'place');
  });

  test('find span marks the named word and the answer words', () {
    final window = passageById('short-window')!;
    final words = readingFindWords(window.text);
    expect(readingFindTargetIndexes(words, [window.find.word]), [4]);
    expect(readingFindTargetIndexes(words, window.find.answer), [6, 7, 8, 9]);
    expect(words[1], 'кот');
    expect(readingFindMode('answer'), 'answer');
  });

  test('sprint words grow longer and a miss returns to the end', () {
    final window = passageById('short-window')!;
    expect(window.sprint.words, ['кот', 'окно', 'тихий', 'смотрел']);
    expect(
      window.sprint.words.map(readingSprintLength).toList(),
      [3, 4, 5, 7],
    );
    expect(readingSprintTextHasWord(window.text, 'окно'), isTrue);
    expect(readingSprintTextHasWord(window.sprint.sentences.join(' '), 'смотрел'), isTrue);
    expect(
      readingSprintQueueAfter(['кот', 'окно'], 'miss'),
      ['окно', 'кот'],
    );
  });

  test('cloze story keeps the word from the bank text', () {
    final window = passageById('short-window')!;
    expect(window.cloze.simple.choices[window.cloze.simple.correctIndex], 'миски');
    expect(window.cloze.story.choices[window.cloze.story.correctIndex], 'двор');
    expect(window.cloze.story.prompt, 'Кот смотрел на тихий ….');
    expect(readingClozeMode('story'), 'story');
  });

  test('story order is a fixed rotation of the card sentences', () {
    final window = passageById('short-window')!;
    expect(window.story.length, 5);
    expect(window.story.first, 'Утром кот сел на окно.');
    expect(readingStoryOrder(3), [1, 2, 0]);
    expect(readingStoryCards(4), 4);
  });

  test('main idea keeps a confirming sentence from the bank text', () {
    final puddles = passageById('medium-puddles')!;
    expect(puddles.idea.choices[puddles.idea.correctIndex], 'Дети играли после дождя.');
    expect(readingMainIdeaSentences(puddles.text), contains(puddles.idea.confirm));
    expect(puddles.text.contains('школу'), isFalse);
  });

  test('anagram letters rotate and the picture word stays in the bank', () {
    final card = readingAnagramCardBySlug('16_кот')!;
    expect(getFirstWord(card.slug)?.label, card.label);
    expect(readingAnagramOrder(3), [1, 2, 0]);
    expect(card.definition.contains(card.label), isFalse);
    expect(readingAnagramHint('sentence'), 'sentence');
  });

  test('word maze keeps a stored neighbor path', () {
    final window = passageById('short-window')!;
    expect(window.text, 'Утром кот сел на окно и смотрел на тихий двор.');
    expect(window.maze.group.path, [0, 1, 2, 5, 8]);
    expect(readingMazeNeighbors(0, 1), isTrue);
    expect(readingMazeNeighbors(0, 4), isFalse);
    expect(readingMazeMode('sentence'), 'sentence');
    expect(
      window.maze.sentence.path.map((index) => window.maze.sentence.words[index]).join(' '),
      'Кот сидел на окне.',
    );
  });

  test('grid step stays one of three stored sizes', () {
    expect(readingGridStep('wide'), 'wide');
    expect(readingGridStepPx('fine'), 16);
    expect(readingGridStepPx('medium'), 24);
    expect(readingGridStep('later'), 'medium');
  });

  test('snake head stays on letters and the tail follows behind', () {
    final units = buildVanishUnits('А б');
    final count = vanishLetterCount(units);
    expect(units.where((unit) => isSnakeHead(unit, 0, count)).map((unit) => unit.grapheme).join(), 'А');
    expect(units.where((unit) => isSnakeHead(unit, 1, count)).map((unit) => unit.grapheme).join(), 'б');
    expect(units.where((unit) => isSnakeTail(unit, 1, count)).map((unit) => unit.grapheme).join(), 'А');
    expect(units.any((unit) => unit.grapheme == ' ' && isSnakeHead(unit, 0, count)), isFalse);
    expect(units.any((unit) => unit.order > 1 && isSnakeTail(unit, 0, count)), isFalse);
  });

  test('line pace keeps a stored width and earlier-line choice', () {
    expect(readingLinePaceLines('Кот сидел на окне.', 2), ['Кот сидел', 'на окне.']);
    expect(readingLineKeep('drop'), 'drop');
    expect(readingLineKeep('later'), 'keep');
    expect(readingLinePaceMs(400), 400);
    expect(readingLinePaceMs(20), 1600);
  });
}
