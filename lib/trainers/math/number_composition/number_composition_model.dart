import 'package:larnes_mobile/trainers/shared/trainer_constants.dart';

const compositionPhases = [
  'demo-dots',
  'demo-digits',
  'practice-dots',
  'practice-digits',
];

const dotAnswerChoices = [0, 1, 2, 3];

typedef CompositionPhase = String;

class CompositionEquation {
  const CompositionEquation({
    required this.knownPart,
    required this.missingPart,
    required this.whole,
  });

  final int knownPart;
  final int missingPart;
  final int whole;

  @override
  bool operator ==(Object other) {
    return other is CompositionEquation &&
        other.knownPart == knownPart &&
        other.missingPart == missingPart &&
        other.whole == whole;
  }

  @override
  int get hashCode => Object.hash(knownPart, missingPart, whole);
}

int getMissingPart(int whole, int knownPart) => whole - knownPart;

List<int> getDigitAnswerChoices(int answerRangeStart) {
  return List.generate(4, (offset) => answerRangeStart + offset);
}

bool isValidComposition(int whole, int knownPart) {
  return whole >= 2 && knownPart >= 0 && knownPart < whole;
}

CompositionEquation getCompositionEquation(int whole, int knownPart) {
  return CompositionEquation(
    knownPart: knownPart,
    missingPart: getMissingPart(whole, knownPart),
    whole: whole,
  );
}

CompositionPhase? getNextPhase(CompositionPhase phase) {
  final index = compositionPhases.indexOf(phase);
  if (index < 0 || index >= compositionPhases.length - 1) {
    return null;
  }
  return compositionPhases[index + 1];
}

bool isPracticePhase(CompositionPhase phase) {
  return phase == 'practice-dots' || phase == 'practice-digits';
}

bool isDemoPhase(CompositionPhase phase) {
  return phase == 'demo-dots' || phase == 'demo-digits';
}

bool isMissingPartInDigitRange(int missingPart, int answerRangeStart) {
  return missingPart >= answerRangeStart && missingPart <= answerRangeStart + 3;
}

bool isMissingPartInDotRange(int missingPart) {
  return missingPart >= 0 && missingPart <= maxDotChoice;
}
