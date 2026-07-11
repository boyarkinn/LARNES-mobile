import 'dart:math' as math;

/// Web v2: `triple-scene.tsx` + `dot-group.tsx` svh/vw sizing.
///
/// All panel sizes are capped by the equal grid column width so portrait and
/// landscape stay inside their cells.

class TripleSceneLayout {
  const TripleSceneLayout({
    required this.cellWidth,
    required this.dotFrameWidth,
    required this.dotFrameHeight,
    required this.equalsFontSize,
    required this.digitCardSize,
    required this.digitFontSize,
    required this.abacusWidth,
    required this.abacusHeight,
  });

  final double cellWidth;
  final double dotFrameWidth;
  final double dotFrameHeight;
  final double equalsFontSize;
  final double digitCardSize;
  final double digitFontSize;
  final double abacusWidth;
  final double abacusHeight;
}

// --- Tunable caps (web parity, single SSOT) ---
const _equalsFontSvh = 0.10;
const _equalsFontMaxPx = 64.0;

const _dotFrameSvhSmall = 0.36;
const _dotFrameSvhLarge = 0.48;
const _dotFrameMaxSmallPx = 208.0;
const _dotFrameMaxLargePx = 288.0;

const _digitCardSvh = 0.28;
const _digitCardMaxPx = 128.0;
const _digitFontSvh = 0.28;
const _digitFontMaxPx = 128.0;
const _digitFontInCardRatio = 0.72;

const _abacusWidthVwPortrait = 0.40;
const _abacusWidthVwLandscape = 0.36;
const _abacusWidthVhCap = 0.40;
const _abacusWidthMaxPx = 256.0;
const _abacusHeightSvh = 0.50;
const _abacusHeightMaxPx = 208.0;

const _horizontalPaddingPx = 16.0;
const _columnGapPx = 8.0;
const _equalsSlotPaddingPx = 8.0;

TripleSceneLayout computeTripleSceneLayout({
  required double viewportWidth,
  required double viewportHeight,
  required int dotCount,
}) {
  final isLandscape = viewportWidth > viewportHeight;
  final equalsFontSize = _minSvh(viewportHeight, _equalsFontSvh, _equalsFontMaxPx);
  final equalsSlotWidth = equalsFontSize + _equalsSlotPaddingPx;
  final contentWidth = viewportWidth -
      _horizontalPaddingPx -
      _columnGapPx * 4 -
      equalsSlotWidth * 2;
  final cellWidth = math.max(contentWidth / 3, 48.0);

  final dotSvhCap = dotCount <= 9 ? _dotFrameSvhSmall : _dotFrameSvhLarge;
  final dotMaxPx = dotCount <= 9 ? _dotFrameMaxSmallPx : _dotFrameMaxLargePx;
  final dotSquare = _minSvh(viewportHeight, dotSvhCap, dotMaxPx);
  final dotFrameWidth = _fitCell(
    dotCount <= 9 ? dotSquare : _minSvh(viewportHeight, 0.44, 272),
    cellWidth,
  );
  final dotFrameHeight = _fitCell(
    dotCount <= 9 ? dotSquare : _minSvh(viewportHeight, 0.40, 240),
    cellWidth,
  );

  final digitCardSize = _fitCell(
    _minSvh(viewportHeight, _digitCardSvh, _digitCardMaxPx),
    cellWidth,
  );
  final digitFontSize = math.min(
    _minSvh(viewportHeight, _digitFontSvh, _digitFontMaxPx),
    digitCardSize * _digitFontInCardRatio,
  );

  final abacusWidthCap = isLandscape ? _abacusWidthVwLandscape : _abacusWidthVwPortrait;
  final abacusWidth = _fitCell(
    _minOf(
      viewportWidth * abacusWidthCap,
      viewportHeight * _abacusWidthVhCap,
      _abacusWidthMaxPx,
    ),
    cellWidth,
  );
  final abacusHeight = math.min(
    _minSvh(viewportHeight, _abacusHeightSvh, _abacusHeightMaxPx),
    math.max(abacusWidth * 1.15, cellWidth * 0.9),
  );

  return TripleSceneLayout(
    cellWidth: cellWidth,
    dotFrameWidth: dotFrameWidth,
    dotFrameHeight: dotFrameHeight,
    equalsFontSize: equalsFontSize,
    digitCardSize: digitCardSize,
    digitFontSize: digitFontSize,
    abacusWidth: abacusWidth,
    abacusHeight: abacusHeight,
  );
}

double _fitCell(double value, double cellWidth) {
  return math.min(value, cellWidth * 0.95);
}

double _minOf(double a, double b, double c) {
  return math.min(a, math.min(b, c));
}

double _minSvh(double viewportHeight, double fraction, double maxPx) {
  final svhValue = viewportHeight * fraction;
  return svhValue < maxPx ? svhValue : maxPx;
}

// Legacy helpers kept for tests / gradual migration — delegate to layout engine.

double tripleDotFrameWidth(double viewportWidth, double viewportHeight, int count) {
  return computeTripleSceneLayout(
    viewportWidth: viewportWidth,
    viewportHeight: viewportHeight,
    dotCount: count,
  ).dotFrameWidth;
}

double tripleDotFrameHeight(double viewportWidth, double viewportHeight, int count) {
  return computeTripleSceneLayout(
    viewportWidth: viewportWidth,
    viewportHeight: viewportHeight,
    dotCount: count,
  ).dotFrameHeight;
}

double tripleEqualsFontSize(double viewportHeight) {
  return _minSvh(viewportHeight, _equalsFontSvh, _equalsFontMaxPx);
}

double tripleDigitCardSize(
  double viewportWidth,
  double viewportHeight,
) {
  return computeTripleSceneLayout(
    viewportWidth: viewportWidth,
    viewportHeight: viewportHeight,
    dotCount: 1,
  ).digitCardSize;
}

double tripleDigitFontSize(
  double viewportWidth,
  double viewportHeight,
) {
  return computeTripleSceneLayout(
    viewportWidth: viewportWidth,
    viewportHeight: viewportHeight,
    dotCount: 1,
  ).digitFontSize;
}

double tripleAbacusHeight(double viewportWidth, double viewportHeight) {
  return computeTripleSceneLayout(
    viewportWidth: viewportWidth,
    viewportHeight: viewportHeight,
    dotCount: 1,
  ).abacusHeight;
}

double tripleAbacusMaxWidth(double viewportWidth, double viewportHeight) {
  return computeTripleSceneLayout(
    viewportWidth: viewportWidth,
    viewportHeight: viewportHeight,
    dotCount: 1,
  ).abacusWidth;
}
