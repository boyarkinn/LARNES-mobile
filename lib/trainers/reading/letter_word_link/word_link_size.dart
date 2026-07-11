import 'dart:math' as math;
import 'dart:ui';

import 'package:larnes_mobile/app/theme/parent_theme.dart';

/// Web: `platform/src/trainers/reading/letter-word-link/word-link-size.ts`

const wordLinkLineLockedColor = Color(0xFF22C55E);
const wordLinkLineDraftColor = ParentColors.shell;
const wordLinkLineWrongColor = Color(0xFFEF4444);

const _letterBoxSvh = 0.18;
const _letterBoxMaxVw = 0.22;
const _cardMinHeightSvh = 0.12;
const _cardMinHeightMaxPx = 72.0;

double getWordLinkLetterBoxSize(double viewportHeight, double viewportWidth) {
  if (!viewportHeight.isFinite || viewportHeight <= 0) {
    return 144;
  }

  final fromHeight = viewportHeight * _letterBoxSvh;
  final fromWidth =
      viewportWidth.isFinite && viewportWidth > 0
          ? viewportWidth * _letterBoxMaxVw
          : fromHeight;

  return math.min(fromHeight, fromWidth).roundToDouble();
}

double getWordLinkLetterFontSize(double letterBoxSize) {
  return (letterBoxSize * 0.72).roundToDouble();
}

double getWordLinkCardMinHeight(double viewportHeight) {
  if (!viewportHeight.isFinite || viewportHeight <= 0) {
    return _cardMinHeightMaxPx;
  }

  return math
      .min(viewportHeight * _cardMinHeightSvh, _cardMinHeightMaxPx)
      .roundToDouble();
}
