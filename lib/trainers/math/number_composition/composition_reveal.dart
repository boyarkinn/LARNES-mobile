import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';

/// Web v2: `platform/src/trainers/math/number-composition/composition-reveal.ts`

const compositionBeatPopMs = 250;
const compositionRevealBudgetMs = 2000;
const demoHoldAfterRevealMs = 2500;
const demoEquationBeatCount = 5;

int getCompositionBeatStaggerMs(int beatCount) {
  if (beatCount <= 1) {
    return 0;
  }

  return ((compositionRevealBudgetMs - compositionBeatPopMs) / (beatCount - 1))
      .floor();
}

int getCompositionBeatDelayMs(int beatIndex, {int beatCount = demoEquationBeatCount}) {
  if (beatIndex <= 0 || beatCount <= 0) {
    return 0;
  }

  return beatIndex * getCompositionBeatStaggerMs(beatCount);
}

int getCompositionRevealTotalMs({int beatCount = demoEquationBeatCount}) {
  if (beatCount <= 0) {
    return 0;
  }

  if (beatCount == 1) {
    return compositionBeatPopMs;
  }

  return (beatCount - 1) * getCompositionBeatStaggerMs(beatCount) +
      compositionBeatPopMs;
}

int getDemoPhaseDurationMs({int beatCount = demoEquationBeatCount}) {
  return getCompositionRevealTotalMs(beatCount: beatCount) + demoHoldAfterRevealMs;
}

int getPracticeInteractionReadyMs(int answerCount) {
  return getCompositionRevealTotalMs() + getAnswerRevealTotalMs(answerCount);
}
