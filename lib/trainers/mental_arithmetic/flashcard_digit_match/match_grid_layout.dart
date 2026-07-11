import 'dart:math' as math;

/// Web v2: `platform/src/trainers/mental-arithmetic/flashcard-digit-match/match-grid-layout.ts`
import 'package:flutter/widgets.dart';

enum MatchSide { left, right }

class MatchGridSlotLayout {
  const MatchGridSlotLayout({
    required this.column,
    required this.row,
    this.columnSpan = 1,
    this.rowSpan = 1,
    required this.alignment,
  });

  final int column;
  final int row;
  final int columnSpan;
  final int rowSpan;
  final Alignment alignment;
}

class MatchBoardLayout {
  const MatchBoardLayout({
    required this.rowHeight,
    required this.rowGap,
    required this.columnGap,
    required this.abacusHeight,
    required this.digitSize,
    required this.digitFontSize,
    required this.paddingTop,
    required this.paddingBottom,
    required this.gridHeight,
  });

  final double rowHeight;
  final double rowGap;
  final double columnGap;
  final double abacusHeight;
  final double digitSize;
  final double digitFontSize;
  final double paddingTop;
  final double paddingBottom;
  final double gridHeight;

  double get totalHeight => paddingTop + gridHeight + paddingBottom;
}

// --- Tunable caps (web parity) ---
const _rowHeightSvh = 0.51;
const _rowHeightMaxPx = 18.75 * 16;
const _abacusHeightSvh = 0.45;
const _abacusHeightMaxPx = 15.75 * 16;
const _digitSizeSvh = 0.24;
const _digitSizeMaxPx = 7.5 * 16;
const _digitFontSvh = 0.16;
const _digitFontMaxPx = 4.5 * 16;
const _flashCardChromePx = 24.0;
const _paddingTopFraction = 0.04;
const _paddingBottomFraction = 0.08;
const _rowGapSvh = 0.05;
const _columnGapSvh = 0.03;

const _leftGridPositions = <int, List<({int col, int row, int colSpan, int rowSpan})>>{
  2: [
    (col: 0, row: 0, colSpan: 1, rowSpan: 1),
    (col: 0, row: 1, colSpan: 1, rowSpan: 1),
  ],
  3: [
    (col: 0, row: 0, colSpan: 1, rowSpan: 1),
    (col: 0, row: 1, colSpan: 1, rowSpan: 1),
    (col: 1, row: 0, colSpan: 1, rowSpan: 2),
  ],
  4: [
    (col: 0, row: 0, colSpan: 1, rowSpan: 1),
    (col: 0, row: 1, colSpan: 1, rowSpan: 1),
    (col: 1, row: 0, colSpan: 1, rowSpan: 1),
    (col: 1, row: 1, colSpan: 1, rowSpan: 1),
  ],
};

const _rightGridPositions = <int, List<({int col, int row, int colSpan, int rowSpan})>>{
  2: [
    (col: 1, row: 0, colSpan: 1, rowSpan: 1),
    (col: 1, row: 1, colSpan: 1, rowSpan: 1),
  ],
  3: [
    (col: 1, row: 0, colSpan: 1, rowSpan: 1),
    (col: 1, row: 1, colSpan: 1, rowSpan: 1),
    (col: 0, row: 0, colSpan: 1, rowSpan: 2),
  ],
  4: [
    (col: 0, row: 0, colSpan: 1, rowSpan: 1),
    (col: 0, row: 1, colSpan: 1, rowSpan: 1),
    (col: 1, row: 0, colSpan: 1, rowSpan: 1),
    (col: 1, row: 1, colSpan: 1, rowSpan: 1),
  ],
};

MatchBoardLayout computeMatchBoardLayout({
  required double viewportWidth,
  required double viewportHeight,
}) {
  final paddingTop = viewportHeight * _paddingTopFraction;
  final paddingBottom = viewportHeight * _paddingBottomFraction;
  final usableHeight = math.max(viewportHeight - paddingTop - paddingBottom, 0);
  final sideWidth = math.max(viewportWidth / 2, 0);

  final rowGap = math.min(
    viewportHeight * _rowGapSvh,
    usableHeight * 0.06,
  );
  final columnGap = math.min(
    viewportHeight * _columnGapSvh,
    sideWidth * 0.04,
  );

  final svhRowCap = _minSvh(viewportHeight, _rowHeightSvh, _rowHeightMaxPx);
  final fitRowHeight = usableHeight > rowGap
      ? (usableHeight - rowGap) / 2
      : usableHeight / 2;
  final rowHeight = math.min(fitRowHeight, svhRowCap);
  final gridHeight = rowHeight * 2 + rowGap;

  final abacusHeight = math.min(
    math.max(rowHeight - _flashCardChromePx, 0.0),
    _minSvh(viewportHeight, _abacusHeightSvh, _abacusHeightMaxPx),
  );
  final digitSize = math.min(
    rowHeight * 0.85,
    _minSvh(viewportHeight, _digitSizeSvh, _digitSizeMaxPx),
  );
  final digitFontSize = math.min(
    digitSize * 0.65,
    _minSvh(viewportHeight, _digitFontSvh, _digitFontMaxPx),
  );

  return MatchBoardLayout(
    rowHeight: rowHeight,
    rowGap: rowGap,
    columnGap: columnGap,
    abacusHeight: abacusHeight,
    digitSize: digitSize,
    digitFontSize: digitFontSize,
    paddingTop: paddingTop,
    paddingBottom: paddingBottom,
    gridHeight: gridHeight,
  );
}

MatchGridSlotLayout getMatchGridSlotLayout({
  required int index,
  required int count,
  required MatchSide side,
}) {
  final positions = side == MatchSide.left
      ? _leftGridPositions[count]
      : _rightGridPositions[count];

  if (positions == null || index < 0 || index >= positions.length) {
    return MatchGridSlotLayout(
      column: 0,
      row: 0,
      alignment: side == MatchSide.left ? Alignment.centerLeft : Alignment.centerRight,
    );
  }

  final slot = positions[index];
  final alignment = side == MatchSide.left
      ? (slot.rowSpan > 1 ? Alignment.centerLeft : Alignment.centerLeft)
      : (slot.rowSpan > 1 ? Alignment.centerRight : Alignment.centerRight);

  return MatchGridSlotLayout(
    column: slot.col,
    row: slot.row,
    columnSpan: slot.colSpan,
    rowSpan: slot.rowSpan,
    alignment: alignment,
  );
}

double matchGridRowHeight(double viewportWidth, double viewportHeight) {
  return computeMatchBoardLayout(
    viewportWidth: viewportWidth,
    viewportHeight: viewportHeight,
  ).rowHeight;
}

double matchAbacusHeight(double viewportWidth, double viewportHeight) {
  return computeMatchBoardLayout(
    viewportWidth: viewportWidth,
    viewportHeight: viewportHeight,
  ).abacusHeight;
}

double matchDigitTargetSize(double viewportWidth, double viewportHeight) {
  return computeMatchBoardLayout(
    viewportWidth: viewportWidth,
    viewportHeight: viewportHeight,
  ).digitSize;
}

double matchDigitFontSize(double viewportWidth, double viewportHeight) {
  return computeMatchBoardLayout(
    viewportWidth: viewportWidth,
    viewportHeight: viewportHeight,
  ).digitFontSize;
}

double matchSidePaddingTop(double viewportHeight) => viewportHeight * _paddingTopFraction;

double matchSidePaddingBottom(double viewportHeight) =>
    viewportHeight * _paddingBottomFraction;

double matchGridColumnGap(double viewportWidth, double viewportHeight) {
  return computeMatchBoardLayout(
    viewportWidth: viewportWidth,
    viewportHeight: viewportHeight,
  ).columnGap;
}

double matchGridRowGap(double viewportWidth, double viewportHeight) {
  return computeMatchBoardLayout(
    viewportWidth: viewportWidth,
    viewportHeight: viewportHeight,
  ).rowGap;
}

double _minSvh(double viewportHeight, double fraction, double maxPx) {
  final svhValue = viewportHeight * fraction;
  return svhValue < maxPx ? svhValue : maxPx;
}
