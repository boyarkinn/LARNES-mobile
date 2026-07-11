import 'dart:math' as math;

/// Web v2: `answer-bar.tsx` — min-h 3.5rem / sm 4.25rem, text-4xl / sm text-5xl.

class FruitAnswerBarLayout {
  const FruitAnswerBarLayout({
    required this.buttonHeight,
    required this.fontSize,
    required this.paddingTop,
    required this.paddingBottom,
    required this.horizontalPadding,
  });

  final double buttonHeight;
  final double fontSize;
  final double paddingTop;
  final double paddingBottom;
  final double horizontalPadding;

  double get totalHeight =>
      paddingTop + buttonHeight + paddingBottom;
}

const _buttonHeightSvh = 0.055;
const _buttonHeightMaxPx = 68.0;
const _buttonHeightMinPx = 32.0;
const _fontMaxPx = 36.0;
const _footerHeightFraction = 0.16;
const _paddingTopPx = 12.0;
const _paddingBottomPx = 8.0;
const _horizontalPaddingPx = 12.0;
const _fontInButtonRatio = 0.65;

FruitAnswerBarLayout computeFruitAnswerBarLayout({
  required double viewportWidth,
  required double viewportHeight,
}) {
  final footerBudget = viewportHeight * _footerHeightFraction;
  final svhButton = _minSvh(viewportHeight, _buttonHeightSvh, _buttonHeightMaxPx);
  final maxButtonFromViewport =
      footerBudget - _paddingTopPx - _paddingBottomPx;
  final rawButton = math.min(svhButton, maxButtonFromViewport);
  final buttonHeight = rawButton.clamp(_buttonHeightMinPx, _buttonHeightMaxPx);
  final fontSize = math.min(
    buttonHeight * _fontInButtonRatio,
    _minSvh(viewportHeight, 0.05, _fontMaxPx),
  );

  return FruitAnswerBarLayout(
    buttonHeight: buttonHeight,
    fontSize: fontSize,
    paddingTop: _paddingTopPx,
    paddingBottom: _paddingBottomPx,
    horizontalPadding: _horizontalPaddingPx,
  );
}

double _minSvh(double viewportHeight, double fraction, double maxPx) {
  final svhValue = viewportHeight * fraction;
  return svhValue < maxPx ? svhValue : maxPx;
}
