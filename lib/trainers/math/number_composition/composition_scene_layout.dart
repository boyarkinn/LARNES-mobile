import 'dart:math' as math;

import 'package:larnes_mobile/trainers/math/number_composition/composition_sizes.dart';

/// Web v2 parity + mobile caps (fruit_answer_bar_layout / triple_scene_layout pattern).

class CompositionSceneLayout {
  const CompositionSceneLayout({
    required this.dotSlotSize,
    required this.digitSize,
    required this.operatorSize,
    required this.choiceButtonHeight,
    required this.choiceFontSize,
    required this.dotChoiceSize,
    required this.equationScale,
  });

  final double dotSlotSize;
  final double digitSize;
  final double operatorSize;
  final double choiceButtonHeight;
  final double choiceFontSize;
  final double dotChoiceSize;
  final double equationScale;
}

class CompositionChoiceBarLayout {
  const CompositionChoiceBarLayout({
    required this.buttonHeight,
    required this.fontSize,
    required this.dotChoiceSize,
    required this.paddingTop,
    required this.paddingBottom,
    required this.horizontalPadding,
  });

  final double buttonHeight;
  final double fontSize;
  final double dotChoiceSize;
  final double paddingTop;
  final double paddingBottom;
  final double horizontalPadding;
}

const _equationGapPx = 12.0;
const _equationGaps = 4;
const _equationHorizontalPaddingPx = 24.0;
const _digitBeatWidthRatio = 0.72;
const _operatorWidthRatio = 0.58;

const _choiceFooterFraction = 0.16;
const _choicePaddingTopPx = 12.0;
const _choicePaddingBottomPx = 8.0;
const _choiceHorizontalPaddingPx = 12.0;
const _choiceButtonMinPx = 32.0;
const _choiceButtonMaxPx = 72.0;
const _choiceFontInButtonRatio = 0.65;
const _choiceFontMaxPx = 40.0;
const _dotInButtonRatio = 0.82;

CompositionSceneLayout computeCompositionSceneLayout({
  required double viewportWidth,
  required double viewportHeight,
  required bool showDigits,
  required bool isPractice,
}) {
  final rawDotSlot = compositionDotSlotSize(viewportHeight);
  final rawDigit = compositionDigitFontSize(viewportHeight);
  final rawOperator = compositionOperatorFontSize(viewportHeight);

  final estimatedWidth = _estimateEquationWidth(
    showDigits: showDigits,
    isPractice: isPractice,
    dotSlotSize: rawDotSlot,
    digitSize: rawDigit,
    operatorSize: rawOperator,
  );

  final widthBudget = viewportWidth - _equationHorizontalPaddingPx;
  final widthScale = estimatedWidth > 0
      ? math.min(1.0, widthBudget / estimatedWidth)
      : 1.0;

  final maxSlotByHeight = viewportHeight * 0.28;
  final dotSlotSize = math.min(rawDotSlot * widthScale, maxSlotByHeight);

  return CompositionSceneLayout(
    dotSlotSize: dotSlotSize,
    digitSize: rawDigit * widthScale,
    operatorSize: rawOperator * widthScale,
    choiceButtonHeight: compositionChoiceButtonHeight(viewportHeight),
    choiceFontSize: compositionDigitFontSize(viewportHeight),
    dotChoiceSize: compositionDotChoiceSize(viewportHeight),
    equationScale: widthScale,
  );
}

CompositionChoiceBarLayout computeCompositionChoiceBarLayout({
  required double viewportWidth,
  required double viewportHeight,
  required bool showDigits,
}) {
  final footerBudget = viewportHeight * _choiceFooterFraction;
  final svhButton = compositionChoiceButtonHeight(viewportHeight);
  final maxButtonFromViewport =
      footerBudget - _choicePaddingTopPx - _choicePaddingBottomPx;
  final buttonHeight = math
      .min(svhButton, maxButtonFromViewport)
      .clamp(_choiceButtonMinPx, _choiceButtonMaxPx);

  final fontSize = showDigits
      ? math.min(
          buttonHeight * _choiceFontInButtonRatio,
          math.min(
            compositionDigitFontSize(viewportHeight) * 0.55,
            _choiceFontMaxPx,
          ),
        )
      : 0.0;

  final dotChoiceSize = math.min(
    compositionDotChoiceSize(viewportHeight),
    buttonHeight * _dotInButtonRatio,
  );

  return CompositionChoiceBarLayout(
    buttonHeight: buttonHeight,
    fontSize: fontSize,
    dotChoiceSize: dotChoiceSize,
    paddingTop: _choicePaddingTopPx,
    paddingBottom: _choicePaddingBottomPx,
    horizontalPadding: _choiceHorizontalPaddingPx,
  );
}

double _estimateEquationWidth({
  required bool showDigits,
  required bool isPractice,
  required double dotSlotSize,
  required double digitSize,
  required double operatorSize,
}) {
  final operatorBeat = operatorSize * _operatorWidthRatio;
  final digitBeat = digitSize * _digitBeatWidthRatio;
  final dotBeat = dotSlotSize;
  final gaps = _equationGapPx * _equationGaps;

  if (showDigits) {
    if (isPractice) {
      return digitBeat + operatorBeat + dotSlotSize + operatorBeat + digitBeat + gaps;
    }
    return digitBeat * 3 + operatorBeat * 2 + gaps;
  }

  if (isPractice) {
    return dotBeat + operatorBeat + dotSlotSize + operatorBeat + dotBeat + gaps;
  }

  return dotBeat * 3 + operatorBeat * 2 + gaps;
}
