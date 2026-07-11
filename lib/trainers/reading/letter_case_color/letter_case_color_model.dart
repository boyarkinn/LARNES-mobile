import 'package:larnes_mobile/trainers/reading/letter_model.dart';

/// Web: `platform/src/trainers/reading/letter-case-color/model.ts`

const caseColorFontSizeLarge = 72.0;
const caseColorFontSizeSmall = 52.0;
const caseColorLowerRevealDelayMs = 180;

class DisplayCasePair {
  const DisplayCasePair({
    required this.lower,
    required this.upper,
  });

  final String lower;
  final String upper;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DisplayCasePair &&
            lower == other.lower &&
            upper == other.upper;
  }

  @override
  int get hashCode => Object.hash(lower, upper);
}

DisplayCasePair getDisplayCasePair(String letter) {
  final normalized = normalizeTargetLetter(letter);

  return DisplayCasePair(
    lower: applyLetterCase(normalized, 'lower'),
    upper: applyLetterCase(normalized, 'upper'),
  );
}
