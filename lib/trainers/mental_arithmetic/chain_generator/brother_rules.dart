/// Web: `platform/src/trainers/mental-arithmetic/chain-generator/brother-rules.ts`

import 'classify.dart';
import 'topics.dart';
import 'types.dart';

const _brotherNs = [1, 2, 3, 4];

bool _isBrotherN(int value) {
  return value == 1 || value == 2 || value == 3 || value == 4;
}

TopicRule _rule(
  int totalRods,
  List<int> candidateAmounts,
  TopicAllows allows,
  TopicChainValidator isValidChain,
) {
  return TopicRule(
    allows: allows,
    candidateAmounts: candidateAmounts,
    isValidChain: isValidChain,
    totalRods: totalRods,
  );
}

List<int> _placeAmountsForBrother(int n, int totalRods) {
  final amounts = [n];

  if (totalRods >= 2) {
    amounts.add(n * 10);
  }

  if (totalRods >= 3) {
    amounts.add(n * 100);
  }

  return amounts;
}

bool _isBrotherOperandAmount(int amount, int? n) {
  if (n != null) {
    return amount == n || amount == n * 10 || amount == n * 100;
  }

  return _brotherNs.any((brotherN) => _isBrotherOperandAmount(amount, brotherN));
}

TopicAllows _allowsBrother(int? n) {
  return (value, step, technique) {
    if (technique.kind == TechniqueKind.brother) {
      return n == null || technique.n == n;
    }

    if (technique.kind == TechniqueKind.direct &&
        _isBrotherOperandAmount(step.amount, n)) {
      return true;
    }

    return false;
  };
}

TopicChainValidator _createBrotherChainValidator(int totalRods, int? n) {
  return (steps, intermediates) {
    for (var index = 0; index < steps.length; index++) {
      final technique =
          classifyStep(intermediates[index], steps[index], totalRods);

      if (technique.kind != TechniqueKind.brother) {
        continue;
      }

      if (n == null || technique.n == n) {
        return true;
      }
    }

    return false;
  };
}

({int n, int rods})? _parseBrotherDigitTopic(TopicId topicId) {
  final match =
      RegExp(r'^brother-([1-4])-(1digit|2digit)$').firstMatch(topicId);

  if (match == null) {
    return null;
  }

  final n = int.parse(match.group(1)!);

  if (!_isBrotherN(n)) {
    return null;
  }

  return (n: n, rods: match.group(2) == '1digit' ? 1 : 2);
}

TopicRule? createBrotherTopicRule(TopicId topicId, AmountScope amountScope) {
  final meta = getTopicMeta(topicId);

  if (meta.block != TopicBlock.brother) {
    return null;
  }

  final parsed = _parseBrotherDigitTopic(topicId);

  if (parsed != null) {
    final n = parsed.n;
    final rods = parsed.rods;
    final topicAmounts = _placeAmountsForBrother(n, rods);
    final candidates = amountScope == 'withLower' && rods == 2
        ? [
            ..._placeAmountsForBrother(n, 1),
            ...topicAmounts.where((amount) => amount >= 10),
          ]
        : topicAmounts;

    final unique = candidates.toSet().toList();

    return _rule(
      rods,
      unique,
      _allowsBrother(n),
      _createBrotherChainValidator(rods, n),
    );
  }

  if (topicId == 'brother-3digit') {
    final topicAmounts =
        _brotherNs.expand((n) => _placeAmountsForBrother(n, 3)).toList();
    final candidates = amountScope == 'withLower'
        ? [
            ..._brotherNs.expand((n) => _placeAmountsForBrother(n, 1)),
            ..._brotherNs.expand((n) => _placeAmountsForBrother(n, 2)),
            ...topicAmounts,
          ]
        : topicAmounts;
    final unique = candidates.toSet().toList();

    return _rule(
      3,
      unique,
      _allowsBrother(null),
      _createBrotherChainValidator(3, null),
    );
  }

  return null;
}
