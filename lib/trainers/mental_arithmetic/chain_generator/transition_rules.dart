/// Web: `platform/src/trainers/mental-arithmetic/chain-generator/transition-rules.ts`
///
/// Зона неба 50/100; квота zone ~⅓ длины (10 → 3…4).
/// При len≥5 также ≥1 direct + ≥1 brother. friendBrother запрещён.

import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/classify.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/simple_rules.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/topics.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

List<int> _rangeInclusive(int from, int to) {
  return [for (var amount = from; amount <= to; amount++) amount];
}

/// Учебный шаг перехода: с границы −1…9 или к границе из [boundary−9 … boundary−1].
bool isTransitionZoneStep(int value, ChainStep step, int boundary) {
  if (step.amount < 1 || step.amount > 9) {
    return false;
  }

  if (step.sign == '-' && value == boundary) {
    return true;
  }

  if (step.sign == '+' &&
      value >= boundary - 9 &&
      value <= boundary - 1 &&
      value + step.amount == boundary) {
    return true;
  }

  return false;
}

int countTransitionZoneSteps(
  List<ChainStep> steps,
  List<int> intermediates,
  int boundary,
) {
  var count = 0;
  for (var index = 0; index < steps.length; index++) {
    if (isTransitionZoneStep(intermediates[index], steps[index], boundary)) {
      count += 1;
    }
  }
  return count;
}

bool chainHasTransitionZoneStep(
  List<ChainStep> steps,
  List<int> intermediates,
  int boundary,
) {
  return countTransitionZoneSteps(steps, intermediates, boundary) > 0;
}

/// Жёстко: ≥1 zone, max ~⅓ (10 → 4). Walk целится в softMin…max (10 → 3…4).
({int min, int max, int softMin}) transitionZoneStepQuota(int actionCount) {
  const min = 1;
  final max = (actionCount + 2) ~/ 3 < 1 ? 1 : (actionCount + 2) ~/ 3;
  var softMin = actionCount ~/ 3 < 1 ? 1 : actionCount ~/ 3;
  if (softMin > max) {
    softMin = max;
  }
  return (min: min, max: max, softMin: softMin);
}

TopicChainValidator _createTransitionChainValidator(
  int boundary,
  int totalRods,
) {
  return (steps, intermediates) {
    final zoneCount = countTransitionZoneSteps(steps, intermediates, boundary);
    final quota = transitionZoneStepQuota(steps.length);
    if (zoneCount < quota.min || zoneCount > quota.max) {
      return false;
    }
    // Zone-пары 50−N / (50−N)+N — методические качели; как Просто 5 ≤25% reverse.
    if (!hasEnoughSimpleTopicVariation(steps, 5)) {
      return false;
    }

    if (steps.length >= 5) {
      var hasDirect = false;
      var hasBrother = false;
      for (var index = 0; index < steps.length; index++) {
        final technique =
            classifyStep(intermediates[index], steps[index], totalRods);
        if (technique.kind == TechniqueKind.direct) {
          hasDirect = true;
        }
        if (technique.kind == TechniqueKind.brother) {
          hasBrother = true;
        }
      }
      if (!hasDirect || !hasBrother) {
        return false;
      }
    }

    return true;
  };
}

/// Коридор transition-100: зона ~100, без сумм до 999.
const transition100IntermediateMax = 150;

TopicAllows _allowsTransition(int totalRods, [int? intermediateMax]) {
  return (value, step, _) {
    if (intermediateMax != null) {
      final next =
          step.sign == '+' ? value + step.amount : value - step.amount;
      if (next < 0 || next > intermediateMax) {
        return false;
      }
    }

    return everyPlaceTechnique(
      value,
      step,
      totalRods,
      (technique) => technique.kind != TechniqueKind.friendBrother,
    );
  };
}

/// `amountScope` игнорируется.
TopicRule? createTransitionTopicRule(
  TopicId topicId, [
  AmountScope amountScope = 'withLower',
]) {
  final meta = getTopicMeta(topicId);

  if (meta.block != TopicBlock.transition) {
    return null;
  }

  if (topicId == 'transition-50') {
    return TopicRule(
      allows: _allowsTransition(2),
      balanceAmounts: true,
      candidateAmounts: _rangeInclusive(1, 99),
      crossBoundary: 50,
      isValidChain: _createTransitionChainValidator(50, 2),
      // Иначе pickCandidatePool оставляет только friend — Просто/Братья не появляются.
      techniqueSummary: true,
      totalRods: 2,
    );
  }

  if (topicId == 'transition-100') {
    return TopicRule(
      allows: _allowsTransition(3, transition100IntermediateMax),
      balanceAmounts: true,
      candidateAmounts: _rangeInclusive(1, transition100IntermediateMax),
      crossBoundary: 100,
      isValidChain: _createTransitionChainValidator(100, 3),
      techniqueSummary: true,
      totalRods: 3,
    );
  }

  return null;
}
