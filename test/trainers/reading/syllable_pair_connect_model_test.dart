import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/syllable_pair_connect/syllable_pair_connect_model.dart';
import 'package:larnes_mobile/trainers/reading/syllable_pair_connect/definition.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';

void main() {
  SyllablePairRound round(String vowels, {int count = 5, int seed = 42, String letterCase = 'upper'}) =>
    buildSyllablePairRound(practiceLetters: vowels, pairCount: count, letterCase: letterCase, rng: TrainerSnapshotRandom(seed).nextDouble);

  test('vowel defaults, numeric count and invalid settings match Web', () {
    expect(validateSyllablePairConnectParams({}).params, {'practiceLetters': 'А,О,У', 'pairCount': 5, 'letterCase': 'upper', 'syllableType': 'all'});
    expect(validateSyllablePairConnectParams({'practiceLetters': 'ёаё', 'pairCount': '3', 'letterCase': 'lower'}).params, {'practiceLetters': 'А,Ё', 'pairCount': 3, 'letterCase': 'lower', 'syllableType': 'all'});
    for (final params in [
      {'practiceLetters': ''}, {'practiceLetters': 'А,М'}, {'practiceLetters': null}, {'practiceLetters': 'A'},
      {'syllableType': 'other'}, {'syllableType': null}, {'pairCount': 0}, {'pairCount': 13}, {'pairCount': 1.5}, {'pairCount': null}, {'letterCase': 'other'},
    ]) { expect(validateSyllablePairConnectParams(params).ok, isFalse); }
  });

  test('all ten vowels offer open and closed catalog syllables', () {
    for (final vowel in pairVowels.split('')) {
      final pool = getPairSyllables(vowel);
      expect(pool.length, greaterThanOrEqualTo(12));
      expect(pool.every((token) => token.length == 2 && token.contains(vowel) && !token.contains(RegExp('[ЬЪ]'))), isTrue);
      expect(pool.any((token) => token.startsWith(vowel)), isTrue);
      expect(pool.any((token) => token.endsWith(vowel)), isTrue);
    }
  });

  test('every type and vowel filters draws and legacy settings keep the mixed seed', () {
    for (final type in syllableTypes) for (final vowel in pairVowels.split('')) {
      final pool = getPairSyllables(vowel, syllableType: type);
      expect(pool.length, greaterThanOrEqualTo(12));
      if (type == 'open') expect(pool.every((token) => token.endsWith(vowel)), isTrue);
      if (type == 'closed') expect(pool.every((token) => token.startsWith(vowel)), isTrue);
      expect(validateSyllablePairConnectParams({'syllableType': type}).params!['syllableType'], type);
      for (var seed = 0; seed < 5; seed++) {
        final value = buildSyllablePairRound(practiceLetters: vowel, pairCount: 12, letterCase: 'upper', syllableType: type, rng: TrainerSnapshotRandom(seed).nextDouble);
        expect(value.letters.length, 24);
        expect(value.letters.every((token) => pool.contains(token.pairKey)), isTrue);
      }
    }
    final legacy = round('А,О', count: 2);
    final mixed = buildSyllablePairRound(practiceLetters: 'А,О', pairCount: 2, letterCase: 'upper', syllableType: 'all', rng: TrainerSnapshotRandom(42).nextDouble);
    expect(mixed.letters.map((token) => token.id), legacy.letters.map((token) => token.id));
  });

  test('draws keep exactly the requested unique pairs', () {
    for (final vowel in pairVowels.split('')) for (final count in [1, 5, 12]) for (var seed = 0; seed < 10; seed++) {
      final value = round(vowel, count: count, seed: seed);
      expect(value.letters.length, count * 2);
      expect(value.letters.map((token) => token.id).toSet().length, count * 2);
      final keys = value.letters.map((token) => token.pairKey).toSet();
      expect(keys.length, count);
      for (final key in keys) {
        expect(getPairSyllables(vowel), contains(key));
        expect(value.letters.where((token) => token.pairKey == key).length, 2);
      }
      expect(value.letters.every((token) => token.xPercent >= 10 && token.xPercent <= 90 && token.yPercent >= 10 && token.yPercent <= 90), isTrue);
    }
  });

  test('the two exclusions chosen by Alena never enter a round', () {
    expect(getPairSyllables(pairVowels), isNot(contains('ЕБ')));
    expect(getPairSyllables(pairVowels), isNot(contains('ЁБ')));
    for (var seed = 0; seed < 50; seed++) {
      expect(round('Е,Ё', count: 12, seed: seed).letters.every((token) => token.pairKey != 'ЕБ' && token.pairKey != 'ЁБ'), isTrue);
    }
  });

  test('only the complete set of distinct correct pairs completes', () {
    final value = round('Ё', count: 2);
    final pairs = value.letters.map((token) => token.pairKey).toSet().map((key) => LetterConnection('$key-0', '$key-1')).toList();
    expect(isSyllablePairRoundComplete(value.letters, []), isFalse);
    expect(isSyllablePairRoundComplete(value.letters, pairs.take(1).toList()), isFalse);
    expect(isSyllablePairRoundComplete(value.letters, [pairs.first, pairs.first]), isFalse);
    expect(isSyllablePairRoundComplete(value.letters, pairs), isTrue);
  });

  test('seed 42 preserves Web order, colors and placement', () {
    final letters = round('А,О', count: 2, letterCase: 'lower').letters;
    expect(letters.map((token) => token.id), ['АМ-1', 'ОФ-1', 'АМ-0', 'ОФ-0']);
    expect(letters.map((token) => token.displayColor), ['#FB923C', '#D946EF', '#FDBA74', '#6366F1']);
    const positions = [
      [57.69912829622626, 35.83662360906601],
      [45.98101891577244, 77.45006145909429],
      [65.60521643608809, 89.5209190249443],
      [81.21585043147206, 44.55131759867072],
    ];
    for (var i = 0; i < letters.length; i++) {
      expect(letters[i].letter, letters[i].pairKey.toLowerCase());
      expect(letters[i].xPercent, closeTo(positions[i][0], 1e-9));
      expect(letters[i].yPercent, closeTo(positions[i][1], 1e-9));
    }
  });
}
