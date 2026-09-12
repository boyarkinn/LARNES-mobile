import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

const matchColorPalette = <Color>[
  Color(0xFFE45B4E),
  Color(0xFF7759D6),
  Color(0xFF36AFC2),
  Color(0xFFD99A2B),
  Color(0xFFB93F38),
  Color(0xFF5F43BA),
  Color(0xFF27869A),
  Color(0xFFA66D12),
];

class MatchColorPair {
  const MatchColorPair({required this.left, required this.right});

  final int left;
  final int right;
}

List<int> _shuffleIndices(int length, double Function() rng) {
  final indices = List<int>.generate(length, (index) => index);

  for (var index = indices.length - 1; index > 0; index--) {
    final swapIndex = (rng() * (index + 1)).floor();
    final temp = indices[index];
    indices[index] = indices[swapIndex];
    indices[swapIndex] = temp;
  }

  return indices;
}

List<int> pickUniqueMatchColors(int count, double Function() rng) {
  final indices = _shuffleIndices(matchColorPalette.length, rng).take(count);

  return indices
      .map((index) => matchColorPalette[index].toARGB32())
      .toList(growable: false);
}

List<MatchColorPair> pickMatchColorPairs(int pairCount, double Function() rng) {
  final colors = pickUniqueMatchColors(pairCount * 2, rng);

  return List.generate(pairCount, (index) {
    return MatchColorPair(
      left: colors[index * 2],
      right: colors[index * 2 + 1],
    );
  }, growable: false);
}

int buildMatchColorSeed(int masterSeed, int roundIndex) {
  return hashParamsSeed([masterSeed, roundIndex, 'flashcard-match-colors']);
}

List<MatchColorPair> colorPairsForRound(int pairCount, int colorSeed) {
  return pickMatchColorPairs(pairCount, createSeededRng(colorSeed));
}
