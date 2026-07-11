import 'dart:math' as math;

import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_find_tap_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_model.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

/// Web: `platform/src/trainers/reading/letter-odd-one-out/model.ts`

const minOddOneOutLetterCount = 6;
const maxOddOneOutLetterCount = 12;

class BuildOddOneOutInput {
  const BuildOddOneOutInput({
    required this.letter,
    required this.letterCase,
    required this.letterCount,
    required this.oddLetter,
    required this.rng,
  });

  final String letter;
  final String letterCase;
  final int letterCount;
  final Object oddLetter;
  final double Function() rng;
}

String resolveOddLetter(
  String mainLetter,
  Object oddLetter,
  double Function() rng,
) {
  final main = normalizeTargetLetter(mainLetter);

  if (oddLetter != 'random') {
    final normalized = normalizeTargetLetter(oddLetter.toString());

    if (normalized != main) {
      return normalized;
    }
  }

  final pool =
      russianLettersUpper.where((letter) => letter != main).toList();

  if (pool.isEmpty) {
    return 'Б';
  }

  return pool[(rng() * pool.length).floor()];
}

List<LetterToken> buildOddOneOutTokens(BuildOddOneOutInput input) {
  final mainLetter = normalizeTargetLetter(input.letter);
  final odd = resolveOddLetter(mainLetter, input.oddLetter, input.rng);
  final displayMain = applyLetterCase(mainLetter, input.letterCase);
  final displayOdd = applyLetterCase(odd, input.letterCase);
  final mainCount = math.max(1, input.letterCount - 1);

  final tokens = <LetterToken>[
    LetterToken(
      id: 'odd-0',
      isTarget: true,
      letter: displayOdd,
    ),
    for (var index = 0; index < mainCount; index++)
      LetterToken(
        id: 'main-$index',
        isTarget: false,
        letter: displayMain,
      ),
  ];

  return _shuffleTokens(tokens, input.rng);
}

bool isOddLetterFound(Set<String> foundIds, List<LetterToken> tokens) {
  for (final token in tokens) {
    if (token.isTarget) {
      return foundIds.contains(token.id);
    }
  }

  return false;
}

int buildOddOneOutRoundSeed(List<Object> parts) {
  return hashParamsSeed([...parts, 'letter-odd-one-out']);
}

List<T> _shuffleTokens<T>(List<T> items, double Function() rng) {
  final next = [...items];

  for (var index = next.length - 1; index > 0; index--) {
    final swapIndex = (rng() * (index + 1)).floor();
    final temp = next[index];
    next[index] = next[swapIndex];
    next[swapIndex] = temp;
  }

  return next;
}
