import 'package:flutter/widgets.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/match_grid_layout.dart';

/// Web: `platform/src/trainers/reading/letter-case-match/case-match-layout.ts`

export 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/match_grid_layout.dart'
    show MatchGridSlotLayout, MatchSide, getMatchGridSlotLayout;

const caseMatchGridRowHeightSvhFraction = 0.14;
const caseMatchGridRowHeightMaxPx = 80.0;
const caseMatchFlexColumnGapSvhFraction = 0.015;
const caseMatchFlexColumnGapMaxPx = 10.0;
const caseMatchFlexColumnPaddingVerticalSvhFraction = 0.04;

bool usesCaseMatchGridLayout(int pairCount) {
  return pairCount >= 2 && pairCount <= 4;
}

MatchGridSlotLayout getCaseMatchGridSlotLayout({
  required int index,
  required int count,
  required MatchSide side,
}) {
  return getMatchGridSlotLayout(index: index, count: count, side: side);
}

double getCaseMatchGridRowHeight(double viewportHeight) {
  final svh = viewportHeight * caseMatchGridRowHeightSvhFraction;
  return svh < caseMatchGridRowHeightMaxPx ? svh : caseMatchGridRowHeightMaxPx;
}

double getCaseMatchGridRowGap(double viewportHeight) {
  return viewportHeight * 0.04;
}

double getCaseMatchGridColumnGap(double viewportHeight) {
  return viewportHeight * 0.03;
}

double getCaseMatchFlexColumnGap(double viewportHeight) {
  final gap = viewportHeight * caseMatchFlexColumnGapSvhFraction;
  return gap < caseMatchFlexColumnGapMaxPx ? gap : caseMatchFlexColumnGapMaxPx;
}

double getCaseMatchFlexColumnPaddingVertical(double viewportHeight) {
  return viewportHeight * caseMatchFlexColumnPaddingVerticalSvhFraction;
}

Alignment getCaseMatchFlexColumnAlignment(MatchSide side) {
  return side == MatchSide.left ? Alignment.centerRight : Alignment.centerLeft;
}
