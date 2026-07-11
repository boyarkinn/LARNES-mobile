import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_find_tap_model.dart';

/// Web: `platform/src/trainers/reading/letter-colors.ts`
const letterColorPalette = [
  '#EF4444',
  '#F97316',
  '#F59E0B',
  '#EAB308',
  '#84CC16',
  '#22C55E',
  '#10B981',
  '#14B8A6',
  '#06B6D4',
  '#0EA5E9',
  '#3B82F6',
  '#6366F1',
  '#8B5CF6',
  '#A855F7',
  '#D946EF',
  '#EC4899',
  '#F43F5E',
  '#FB7185',
  '#FDA4AF',
  '#FDBA74',
  '#FCD34D',
  '#BEF264',
  '#4ADE80',
  '#2DD4BF',
  '#22D3EE',
  '#60A5FA',
  '#818CF8',
  '#C084FC',
  '#E879F9',
  '#F472B6',
  '#FB923C',
  '#A3E635',
  '#34D399',
];

String pickLetterDisplayColor(double Function() rng) {
  final index = (rng() * letterColorPalette.length).floor();
  return letterColorPalette[index.clamp(0, letterColorPalette.length - 1)];
}

List<LetterToken> assignLetterDisplayColors(
  List<LetterToken> tokens,
  double Function() rng,
) {
  return [
    for (final token in tokens)
      LetterToken(
        letter: token.letter,
        id: token.id,
        isTarget: token.isTarget,
        displayColor: pickLetterDisplayColor(rng),
      ),
  ];
}
