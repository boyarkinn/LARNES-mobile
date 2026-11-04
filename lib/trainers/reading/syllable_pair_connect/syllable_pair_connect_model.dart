import 'dart:math' as math;

import 'package:larnes_mobile/trainers/reading/letter_colors.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_find_tap_layout.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_find_tap_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/reading/wedge_tables/wedge_syllables.dart';

/// Parity with Web reading/syllable-pair-connect/model.ts, including RNG order.
const pairVowels = 'АОУЫЭЯЁЮИЕ';
const defaultPairVowels = 'А,О,У';
const syllableTypes = <String>['all', 'open', 'closed'];
List<String> parsePairVowels(String raw) => [
  for (final vowel in pairVowels.split('')) if (raw.toUpperCase().contains(vowel)) vowel,
];
List<String> getPairSyllables(String raw, {String syllableType = 'all'}) {
  final chosen = parsePairVowels(raw);
  return kWedgeSyllables.where((token) => token != 'ЕБ' && token != 'ЁБ' && token.length == 2 &&
    !token.contains(RegExp('[ЬЪ]')) &&
    pairVowels.contains(token[0]) != pairVowels.contains(token[1]) &&
    chosen.any(token.contains) &&
    (syllableType == 'all' || pairVowels.contains(token[1]) == (syllableType == 'open'))).toSet().toList();
}

class PairLetter extends PlacedLetter {
  const PairLetter({
    required super.id,
    required super.letter,
    required super.displayColor,
    required super.xPercent,
    required super.yPercent,
    required this.pairKey,
  }) : super(isTarget: false);

  final String pairKey;
}

class LetterConnection {
  const LetterConnection(this.firstId, this.secondId);
  final String firstId;
  final String secondId;
}

class SyllablePairRound {
  const SyllablePairRound(this.letters, this.gridColumns);
  final List<PairLetter> letters;
  final int? gridColumns;
}

SyllablePairRound buildSyllablePairRound({
  required String practiceLetters,
  required int pairCount,
  required String letterCase,
  String syllableType = 'all',
  required double Function() rng,
}) {
  final pool = getPairSyllables(practiceLetters, syllableType: syllableType);
  if (pairCount < 1 || pairCount > 12 || pairCount > pool.length) throw StateError('INVALID_SYLLABLE_PAIR_PARAMS');
  for (var index = pool.length - 1; index > 0; index--) {
    final other = (rng() * (index + 1)).floor();
    final item = pool[index]; pool[index] = pool[other]; pool[other] = item;
  }
  final tokens = [
    for (final letter in pool.take(pairCount))
      for (var copy = 0; copy < 2; copy++)
        LetterToken(
          id: '$letter-$copy',
          letter: applyLetterCase(letter, letterCase),
          isTarget: false,
        ),
  ];
  for (var index = tokens.length - 1; index > 0; index--) {
    final other = (rng() * (index + 1)).floor();
    final token = tokens[index];
    tokens[index] = tokens[other];
    tokens[other] = token;
  }
  final colored = assignLetterDisplayColors(tokens, rng);
  PairLetter fromPlaced(PlacedLetter token) => PairLetter(
    id: token.id,
    letter: token.letter,
    displayColor: token.displayColor,
    xPercent: token.xPercent,
    yPercent: token.yPercent,
    pairKey: token.letter.toUpperCase(),
  );
  if (tokens.length <= 12) {
    try {
      return SyllablePairRound(
        placeLetterTokens(colored, rng).map(fromPlaced).toList(),
        null,
      );
    } on StateError catch (error) {
      if (error.message != 'LETTER_FIELD_PLACEMENT_FAILED') rethrow;
    }
  }
  final columns = math.max(1, math.sqrt(tokens.length).ceil());
  final rows = math.max(1, (tokens.length / columns).ceil());
  return SyllablePairRound([
    for (var index = 0; index < colored.length; index++)
      PairLetter(
        id: colored[index].id,
        letter: colored[index].letter,
        displayColor: colored[index].displayColor,
        pairKey: colored[index].letter.toUpperCase(),
        xPercent: 10 + ((index % columns + 0.5 + (rng() - 0.5) * 0.2) / columns) * 80,
        yPercent: 10 + ((index ~/ columns + 0.5 + (rng() - 0.5) * 0.2) / rows) * 80,
      ),
  ], columns);
}

bool isMatchingSyllablePair(List<PairLetter> letters, String firstId, String secondId) {
  if (firstId == secondId) return false;
  final first = letters.where((letter) => letter.id == firstId).firstOrNull;
  final second = letters.where((letter) => letter.id == secondId).firstOrNull;
  return first != null && second != null && first.pairKey == second.pairKey;
}

Set<String> connectedLetterIds(List<LetterConnection> connections) => {
  for (final pair in connections) ...[pair.firstId, pair.secondId],
};

bool isSyllablePairRoundComplete(List<PairLetter> letters, List<LetterConnection> connections) {
  if (letters.isEmpty) return false;
  final used = <String>{};
  for (final pair in connections) {
    if (used.contains(pair.firstId) || used.contains(pair.secondId) ||
        !isMatchingSyllablePair(letters, pair.firstId, pair.secondId)) {
      return false;
    }
    used.addAll([pair.firstId, pair.secondId]);
  }
  return used.length == letters.length;
}
