import 'dart:math' as math;
import 'dart:ui';

import 'package:larnes_mobile/app/theme/parent_theme.dart';

/// Web: `platform/src/trainers/reading/letter-case-match/case-match-size.ts`

const caseMatchOutlineStrokeColor = Color(0xFF94A3B8);
const caseMatchLineLockedColor = Color(0xFF22C55E);
const caseMatchLineDraftColor = ParentColors.shell;
const caseMatchLineWrongColor = Color(0xFFEF4444);

const caseMatchOutlineStrokeWidth = 2.5;

double getCaseMatchLetterBoxSize(
  double viewportHeight,
  double viewportWidth,
  int pairCount,
) {
  if (pairCount <= 3) {
    return math.min(viewportHeight * 0.10, viewportWidth * 0.12);
  }

  if (pairCount <= 6) {
    return math.min(viewportHeight * 0.08, viewportWidth * 0.10);
  }

  return math.min(viewportHeight * 0.06, viewportWidth * 0.08);
}

double getCaseMatchLetterFontSize(
  double viewportHeight,
  double viewportWidth,
  int pairCount,
) {
  if (pairCount <= 3) {
    return math.min(viewportHeight * 0.09, viewportWidth * 0.11);
  }

  if (pairCount <= 6) {
    return math.min(viewportHeight * 0.07, viewportWidth * 0.09);
  }

  return math.min(viewportHeight * 0.055, viewportWidth * 0.07);
}
