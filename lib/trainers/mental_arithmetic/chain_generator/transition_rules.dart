/// Web: `platform/src/trainers/mental-arithmetic/chain-generator/transition-rules.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/simple_rules.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/topics.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

List<int> _rangeInclusive(int from, int to) {
  return [for (var amount = from; amount <= to; amount++) amount];
}

/// prev и next по разные стороны границы (0 = на границе).
bool stepCrossesBoundary(int prev, int next, int boundary) {
  if (prev == next) {
    return false;
  }
  return prev.compareTo(boundary).sign != next.compareTo(boundary).sign;
}

bool chainCrossesBoundary(List<int> intermediates, int boundary) {
  for (var index = 1; index < intermediates.length; index += 1) {
    if (stepCrossesBoundary(
      intermediates[index - 1],
      intermediates[index],
      boundary,
    )) {
      return true;
    }
  }
  return false;
}

TopicChainValidator _createTransitionChainValidator(int boundary) {
  return (steps, intermediates) {
    if (!chainCrossesBoundary(intermediates, boundary)) {
      return false;
    }
    return hasEnoughSimpleTopicVariation(steps, 0);
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
      allows: (_, __, ___) => true,
      balanceAmounts: true,
      candidateAmounts: _rangeInclusive(1, 99),
      crossBoundary: 50,
      isValidChain: _createTransitionChainValidator(50),
      totalRods: 2,
    );
  }

  if (topicId == 'transition-100') {
    return TopicRule(
      allows: (_, __, ___) => true,
      balanceAmounts: true,
      candidateAmounts: _rangeInclusive(1, 999),
      crossBoundary: 100,
      isValidChain: _createTransitionChainValidator(100),
      totalRods: 3,
    );
  }

  return null;
}
