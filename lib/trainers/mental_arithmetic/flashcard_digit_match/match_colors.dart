import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/shared/seeded_rng.dart';

const matchColorPalette = <Color>[
  Color(0xFFEF4444),
  Color(0xFFF97316),
  Color(0xFFF59E0B),
  Color(0xFFEAB308),
  Color(0xFF84CC16),
  Color(0xFF22C55E),
  Color(0xFF10B981),
  Color(0xFF14B8A6),
  Color(0xFF06B6D4),
  Color(0xFF0EA5E9),
  Color(0xFF3B82F6),
  Color(0xFF6366F1),
  Color(0xFF8B5CF6),
  Color(0xFFA855F7),
  Color(0xFFD946EF),
  Color(0xFFEC4899),
  Color(0xFFF43F5E),
  Color(0xFFFB7185),
  Color(0xFFFDA4AF),
  Color(0xFFFDBA74),
  Color(0xFFFCD34D),
  Color(0xFFBEF264),
  Color(0xFF4ADE80),
  Color(0xFF2DD4BF),
  Color(0xFF22D3EE),
  Color(0xFF60A5FA),
  Color(0xFF818CF8),
  Color(0xFFC084FC),
  Color(0xFFE879F9),
  Color(0xFFF472B6),
  Color(0xFFFB923C),
  Color(0xFFA3E635),
  Color(0xFF34D399),
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

  return indices.map((index) => matchColorPalette[index].toARGB32()).toList(growable: false);
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
