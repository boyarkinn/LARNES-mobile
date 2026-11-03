import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_pair_connect/letter_pair_connect_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_pair_connect/definition.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';

void main() {
  LetterPairRound round(String letters, {int seed = 42, String letterCase = 'upper'}) =>
      buildLetterPairRound(practiceLetters: letters, letterCase: letterCase, rng: TrainerSnapshotRandom(seed).nextDouble);

  test('parameter defaults and invalid input match Web', () {
    expect(validateLetterPairConnectParams({}).params, {'practiceLetters': defaultPairLetters, 'letterCase': 'upper'});
    for (final params in [{'practiceLetters': null}, {'practiceLetters': '123'}, {'letterCase': 'other'}, {'practiceLetters': ''}]) {
      expect(validateLetterPairConnectParams(params).ok, isFalse);
    }
    expect(validateLetterPairConnectParams({'practiceLetters': 'ё, Ё;а', 'letterCase': 'lower'}).params, {'practiceLetters': 'Ё,А', 'letterCase': 'lower'});
  });

  test('teacher chooses unique letters, each creates exactly one pair', () {
    expect(parsePairLetters('а, О; У М С,А, о'), ['А', 'О', 'У', 'М', 'С']);
    final letters = round('а, О; У М С,А, о').letters;
    expect(letters.length, 10);
    expect(letters.map((letter) => letter.id).toSet().length, 10);
    for (final key in parsePairLetters(defaultPairLetters)) {
      expect(letters.where((letter) => letter.pairKey == key).length, 2);
    }
    expect(parsePairLetters('ABC,123,АОУ'), isEmpty);
  });

  test('seed 42 matches the Web positions, order and colors including ё', () {
    final letters = round('А,Ё', letterCase: 'lower').letters;
    expect(letters.map((letter) => letter.id), ['А-0', 'Ё-1', 'А-1', 'Ё-0']);
    expect(letters.map((letter) => letter.letter), ['а', 'ё', 'а', 'ё']);
    expect(letters.map((letter) => letter.displayColor), ['#4ADE80', '#22C55E', '#FB7185', '#0EA5E9']);
    const positions = [
      [59.97957231476903, 79.23797186464071],
      [47.78536440804601, 29.99389873817563],
      [80.56470667943358, 69.65900519862771],
      [50.058359019458294, 64.92896143347025],
    ];
    for (var index = 0; index < letters.length; index++) {
      expect(letters[index].xPercent, closeTo(positions[index][0], 1e-9));
      expect(letters[index].yPercent, closeTo(positions[index][1], 1e-9));
    }
  });

  test('full alphabet keeps every pair on screen', () {
    for (var seed = 0; seed < 30; seed++) {
      final value = round(pairAlphabet.split('').join(','), seed: seed);
      expect(value.letters.length, 66);
      expect(value.gridColumns, 9);
      expect(value.letters.every((letter) => letter.xPercent >= 10 && letter.xPercent <= 90 && letter.yPercent >= 10 && letter.yPercent <= 90), isTrue);
    }
  });

  test('only all distinct correct pairs complete the task', () {
    final letters = round('А,О').letters;
    const a = LetterConnection('А-0', 'А-1');
    const o = LetterConnection('О-0', 'О-1');
    expect(isLetterPairRoundComplete(letters, []), isFalse);
    expect(isLetterPairRoundComplete(letters, [a]), isFalse);
    expect(isLetterPairRoundComplete(letters, [a, a]), isFalse);
    expect(isLetterPairRoundComplete(letters, [a, o]), isTrue);
    expect(isLetterPairRoundComplete([], []), isFalse);
    expect(isMatchingLetterPair(letters, 'А-0', 'А-0'), isFalse);
    expect(isMatchingLetterPair(letters, 'А-0', 'О-0'), isFalse);
    expect(isMatchingLetterPair(letters, 'missing', 'О-0'), isFalse);
  });
}
