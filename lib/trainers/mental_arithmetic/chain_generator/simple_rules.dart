/// Web: `platform/src/trainers/mental-arithmetic/chain-generator/simple-rules.ts`
///
/// Просто N (1…9): операнды ±1…±N (direct); ≥1 шаг ±N;
/// при N>1 — не больше ⌊actionCount/2⌋ шагов ±N (остальное — пройденные 1…N−1).

import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/topics.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

List<int> _rangeInclusive(int from, int to) {
  return [for (var amount = from; amount <= to; amount++) amount];
}

List<int> _tensAmounts() => [10, 20, 30, 40, 50, 60, 70, 80, 90];

List<int> _hundredsAmounts() => [100, 200, 300, 400, 500, 600, 700, 800, 900];

int _nextValue(int value, ChainStep step) {
  return step.sign == '+' ? value + step.amount : value - step.amount;
}

bool _isDirect(Technique technique) => technique.kind == TechniqueKind.direct;

TopicRule _rule(
  int totalRods,
  List<int> candidateAmounts,
  TopicAllows allows, {
  List<int>? focusAmounts,
  bool? focusCap,
  TopicChainValidator? isValidChain,
}) {
  return TopicRule(
    allows: allows,
    candidateAmounts: candidateAmounts,
    totalRods: totalRods,
    focusAmounts: focusAmounts,
    focusCap: focusCap,
    isValidChain: isValidChain,
  );
}

bool _allowsDirectOnly(int value, ChainStep step, Technique technique) {
  return _isDirect(technique);
}

int? _parseSimpleDigitTopic(String topicId) {
  final match = RegExp(r'^simple-([0-9])$').firstMatch(topicId);
  return match == null ? null : int.parse(match.group(1)!);
}

TopicChainValidator _createSimpleDigitChainValidator(int digit) {
  return (steps, intermediates) {
    final focusCount = steps.where((step) => step.amount == digit).length;

    if (focusCount < 1) {
      return false;
    }

    if (digit == 1) {
      return true;
    }

    return focusCount <= (steps.length / 2).floor();
  };
}

TopicRule? createSimpleTopicRule(TopicId topicId, AmountScope amountScope) {
  final meta = getTopicMeta(topicId);

  if (meta.block != TopicBlock.simple) {
    return null;
  }

  final digit = _parseSimpleDigitTopic(topicId);

  if (digit == 0) {
    return _rule(1, _rangeInclusive(1, 4), (value, step, technique) {
      if (!_isDirect(technique)) {
        return false;
      }
      final next = _nextValue(value, step);
      return next >= 0 && next <= 4;
    });
  }

  if (digit != null) {
    return _rule(
      1,
      _rangeInclusive(1, digit),
      _allowsDirectOnly,
      focusAmounts: [digit],
      focusCap: digit > 1,
      isValidChain: _createSimpleDigitChainValidator(digit),
    );
  }

  if (topicId == 'simple-11-19') {
    return _rule(
      2,
      [..._rangeInclusive(1, 9), ..._rangeInclusive(11, 19)],
      (value, step, technique) {
        if (!_isDirect(technique)) {
          return false;
        }

        if (step.amount >= 11 && step.amount <= 19) {
          return true;
        }

        if (step.amount >= 1 && step.amount <= 9) {
          final next = _nextValue(value, step);
          return next >= 11 && next <= 19;
        }

        return false;
      },
    );
  }

  if (topicId == 'simple-tens') {
    return _rule(2, _tensAmounts(), _allowsDirectOnly);
  }

  if (topicId == 'simple-hundreds') {
    return _rule(3, _hundredsAmounts(), _allowsDirectOnly);
  }

  if (topicId == 'simple-2digit') {
    final candidates = amountScope == 'withLower'
        ? [..._rangeInclusive(1, 9), ..._rangeInclusive(10, 99)]
        : _rangeInclusive(10, 99);
    return _rule(2, candidates, _allowsDirectOnly);
  }

  if (topicId == 'simple-3digit') {
    final candidates = amountScope == 'withLower'
        ? [
            ..._rangeInclusive(1, 9),
            ..._rangeInclusive(10, 99),
            ..._rangeInclusive(100, 999),
          ]
        : _rangeInclusive(100, 999);
    return _rule(3, candidates, _allowsDirectOnly);
  }

  return null;
}
