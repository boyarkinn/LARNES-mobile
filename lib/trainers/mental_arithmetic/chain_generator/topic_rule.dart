/// Web: `platform/src/trainers/mental-arithmetic/chain-generator/topic-rule.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/anzan_rules.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/brother_rules.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/friend_brother_rules.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/friend_rules.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/simple_rules.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/topics.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/transition_rules.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

class TopicRuleNotImplementedError implements Exception {
  TopicRuleNotImplementedError(this.topicId);

  final String topicId;

  @override
  String toString() =>
      'TopicRuleNotImplementedError: Topic rule is not implemented for "$topicId".';
}

List<int> _rangeAmounts(int maxInclusive) {
  return [for (var amount = 1; amount <= maxInclusive; amount++) amount];
}

List<int> _tensAmounts() => [10, 20, 30, 40, 50, 60, 70, 80, 90];

List<int> _hundredsAmounts() => [100, 200, 300, 400, 500, 600, 700, 800, 900];

TopicRule createOpenTopicRule(int totalRods) {
  late final List<int> candidateAmounts;

  if (totalRods == 1) {
    candidateAmounts = _rangeAmounts(9);
  } else if (totalRods == 2) {
    candidateAmounts = [..._rangeAmounts(9), ..._tensAmounts()];
  } else {
    candidateAmounts = [
      ..._rangeAmounts(9),
      ..._tensAmounts(),
      ..._hundredsAmounts(),
    ];
  }

  return TopicRule(
    candidateAmounts: candidateAmounts,
    totalRods: totalRods,
    allows: (_, __, ___) => true,
  );
}

TopicRule getTopicRule(String topicId, [AmountScope amountScope = 'withLower']) {
  final simpleRule = createSimpleTopicRule(topicId, amountScope);
  if (simpleRule != null) {
    return simpleRule;
  }

  final brotherRule = createBrotherTopicRule(topicId, amountScope);
  if (brotherRule != null) {
    return brotherRule;
  }

  final friendRule = createFriendTopicRule(topicId, amountScope);
  if (friendRule != null) {
    return friendRule;
  }

  final transitionRule = createTransitionTopicRule(topicId, amountScope);
  if (transitionRule != null) {
    return transitionRule;
  }

  final friendBrotherRule = createFriendBrotherTopicRule(topicId, amountScope);
  if (friendBrotherRule != null) {
    return friendBrotherRule;
  }

  final anzanRule = createAnzanTopicRule(topicId, amountScope);
  if (anzanRule != null) {
    return anzanRule;
  }

  getTopicMeta(topicId);
  throw TopicRuleNotImplementedError(topicId);
}
