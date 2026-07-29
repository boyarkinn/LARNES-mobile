/// Web: `platform/src/trainers/mental-arithmetic/chain-generator/anzan-rules.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/classify.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/simple_rules.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/topics.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

List<int> _rangeInclusive(int from, int to) {
  return [for (var amount = from; amount <= to; amount++) amount];
}

({String width, SignMode? signMode})? _parseAnzanTopic(TopicId topicId) {
  final withSign =
      RegExp(r'^anzan-(1digit|2digit)-(add|sub|mix)$').firstMatch(topicId);
  if (withSign != null) {
    return (width: withSign.group(1)!, signMode: withSign.group(2)!);
  }

  if (topicId == 'anzan-3digit') {
    return (width: '3digit', signMode: null);
  }

  return null;
}

/// Если topic задаёт знак — вернуть его; иначе null.
SignMode? resolveAnzanSignMode(TopicId topicId) {
  return _parseAnzanTopic(topicId)?.signMode;
}

TopicChainValidator _createAnzanChainValidator(int totalRods) {
  return (steps, intermediates) {
    if (!hasEnoughSimpleTopicVariation(steps, 0)) {
      return false;
    }

    if (steps.length < 4) {
      return true;
    }

    for (var index = 0; index < steps.length; index += 1) {
      final technique =
          classifyStep(intermediates[index], steps[index], totalRods);
      if (technique.kind != TechniqueKind.direct) {
        return true;
      }
    }

    return false;
  };
}

({List<int> amounts, int rods}) _candidatesForWidth(String width) {
  if (width == '1digit') {
    return (amounts: _rangeInclusive(1, 9), rods: 1);
  }
  if (width == '2digit') {
    return (amounts: _rangeInclusive(1, 99), rods: 2);
  }
  return (amounts: _rangeInclusive(1, 999), rods: 3);
}

TopicRule? createAnzanTopicRule(
  TopicId topicId, [
  AmountScope amountScope = 'withLower',
]) {
  final meta = getTopicMeta(topicId);

  if (meta.block != TopicBlock.anzan) {
    return null;
  }

  final parsed = _parseAnzanTopic(topicId);
  if (parsed == null) {
    return null;
  }

  final candidates = _candidatesForWidth(parsed.width);

  return TopicRule(
    allows: (_, __, ___) => true,
    balanceAmounts: true,
    candidateAmounts: candidates.amounts,
    isValidChain: _createAnzanChainValidator(candidates.rods),
    totalRods: candidates.rods,
  );
}
