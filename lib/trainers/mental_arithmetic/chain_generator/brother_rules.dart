/// Web: `platform/src/trainers/mental-arithmetic/chain-generator/brother-rules.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/classify.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/simple_rules.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/topics.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

const _brotherNs = [1, 2, 3, 4];

/// Порядок преподавания в школе (не 1→4).
const _brotherSchoolOrder = [4, 3, 2, 1];

bool _isBrotherN(int value) {
  return value == 1 || value == 2 || value == 3 || value == 4;
}

List<int> _priorBrotherNs(int n) {
  final index = _brotherSchoolOrder.indexOf(n);
  return index <= 0 ? const [] : _brotherSchoolOrder.sublist(0, index);
}

List<int> _rangeInclusive(int from, int to) {
  return [for (var amount = from; amount <= to; amount++) amount];
}

TopicRule _rule(
  int totalRods,
  List<int> candidateAmounts,
  TopicAllows allows,
  TopicChainValidator isValidChain, {
  int? focusTechniqueN,
}) {
  return TopicRule(
    allows: allows,
    candidateAmounts: candidateAmounts,
    focusCap: true,
    focusTechniqueN: focusTechniqueN,
    focusTechniques: const [TechniqueKind.brother],
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

bool _isFocusBrother(Technique technique, int? n) {
  return technique.kind == TechniqueKind.brother &&
      (n == null || technique.n == n);
}

TopicAllows _allowsBrother(int? n, List<int> priorNs) {
  return (value, step, technique) {
    if (technique.kind == TechniqueKind.brother) {
      if (n == null) {
        return true;
      }

      return technique.n == n || priorNs.contains(technique.n);
    }

    if (technique.kind == TechniqueKind.direct) {
      return true;
    }

    return false;
  };
}

TopicChainValidator _createBrotherChainValidator(int totalRods, int? n) {
  return (steps, intermediates) {
    final focusIndices = <int>[];
    var priorCount = 0;

    for (var index = 0; index < steps.length; index++) {
      final technique =
          classifyStep(intermediates[index], steps[index], totalRods);

      if (_isFocusBrother(technique, n)) {
        focusIndices.add(index);
      } else {
        priorCount += 1;
      }
    }

    if (focusIndices.isEmpty) {
      return false;
    }

    if (focusIndices.length > (steps.length / 2).floor()) {
      return false;
    }

    if (steps.length >= 5 && !focusIndices.any((index) => index >= 2)) {
      return false;
    }

    if (steps.length >= 4 && priorCount < 1) {
      return false;
    }

    if (!hasEnoughSimpleTopicVariation(steps, 0)) {
      return false;
    }

    return true;
  };
}

List<int> _candidatesForBrotherDigit(int n, int rods, List<int> priorNs) {
  final amounts = {..._rangeInclusive(1, 9)};

  for (final brotherN in [n, ...priorNs]) {
    amounts.addAll(_placeAmountsForBrother(brotherN, rods));
  }

  return amounts.toList();
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

/// `amountScope` deprecated — 2/3 знака всегда с младшими.
TopicRule? createBrotherTopicRule(
  TopicId topicId, [
  AmountScope amountScope = 'withLower',
]) {
  final meta = getTopicMeta(topicId);

  if (meta.block != TopicBlock.brother) {
    return null;
  }

  final parsed = _parseBrotherDigitTopic(topicId);

  if (parsed != null) {
    final n = parsed.n;
    final rods = parsed.rods;
    final priorNs = _priorBrotherNs(n);
    final candidates = _candidatesForBrotherDigit(n, rods, priorNs);

    return _rule(
      rods,
      candidates,
      _allowsBrother(n, priorNs),
      _createBrotherChainValidator(rods, n),
      focusTechniqueN: n,
    );
  }

  if (topicId == 'brother-3digit') {
    final candidates = {
      ..._rangeInclusive(1, 9),
      ..._brotherNs.expand((n) => _placeAmountsForBrother(n, 2)),
      ..._brotherNs.expand((n) => _placeAmountsForBrother(n, 3)),
    }.toList();

    return _rule(
      3,
      candidates,
      _allowsBrother(null, const []),
      _createBrotherChainValidator(3, null),
    );
  }

  return null;
}
