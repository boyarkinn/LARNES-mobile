/// Web: `platform/src/trainers/mental-arithmetic/chain-generator/simple-rules.ts`
///
/// Просто N: focus ±N + prior ±1…±(N−1); анти-откат жёсткий кроме Просто 5;
/// 2/3 знака всегда с младшими; десятки/сотни — исключения без prior.

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

/// Как в старой МА: Просто 1–4 → ≤4; 5–9 → ≤9.
int simpleIntermediateMax(int digit) => digit <= 4 ? 4 : 9;

bool isImmediateReverse(ChainStep? previous, ChainStep next) {
  return previous != null &&
      previous.amount == next.amount &&
      previous.sign != next.sign;
}

int _countImmediateReversePairs(List<ChainStep> steps) {
  var pairs = 0;
  for (var index = 1; index < steps.length; index++) {
    if (isImmediateReverse(steps[index - 1], steps[index])) {
      pairs += 1;
    }
  }
  return pairs;
}

/// Просто 5 — мягкий ≤25%; остальные N>1 — без immediate +X −X.
bool hasEnoughSimpleTopicVariation(List<ChainStep> steps, [int digit = 5]) {
  if (steps.length <= 1) {
    return true;
  }

  final pairs = _countImmediateReversePairs(steps);
  if (pairs == 0) {
    return true;
  }

  if (digit == 5) {
    if (steps.length <= 3) {
      return false;
    }
    return pairs / (steps.length - 1) <= 0.25;
  }

  return false;
}

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
  final intermediateMax = simpleIntermediateMax(digit);

  return (steps, intermediates) {
    final focusCount = steps.where((step) => step.amount == digit).length;
    final priorCount = steps.where((step) => step.amount != digit).length;

    if (focusCount < 1) {
      return false;
    }

    if (digit > 1 && focusCount > (steps.length / 2).floor()) {
      return false;
    }

    if (digit > 1 && steps.length >= 4 && priorCount < 1) {
      return false;
    }

    for (final value in intermediates) {
      if (value < 0 || value > intermediateMax) {
        return false;
      }
    }

    final answer = intermediates.isEmpty ? null : intermediates.last;
    if (answer == null) {
      return false;
    }

    final hasSub = steps.any((step) => step.sign == '-');
    if (hasSub && answer > digit) {
      return false;
    }

    if (digit > 1 && !hasEnoughSimpleTopicVariation(steps, digit)) {
      return false;
    }

    return true;
  };
}

TopicChainValidator _createRangeFocusChainValidator(bool Function(int amount) isFocusAmount) {
  return (steps, intermediates) {
    final focusCount = steps.where((step) => isFocusAmount(step.amount)).length;
    final priorCount = steps.where((step) => !isFocusAmount(step.amount)).length;

    if (focusCount < 1) {
      return false;
    }

    if (focusCount > (steps.length / 2).floor()) {
      return false;
    }

    if (steps.length >= 4 && priorCount < 1) {
      return false;
    }

    return hasEnoughSimpleTopicVariation(steps, 0);
  };
}

/// `amountScope` deprecated — 2/3 знака всегда с младшими.
TopicRule? createSimpleTopicRule(TopicId topicId, [AmountScope amountScope = 'withLower']) {
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
    final intermediateMax = simpleIntermediateMax(digit);

    return _rule(
      1,
      _rangeInclusive(1, digit),
      (value, step, technique) {
        if (!_isDirect(technique)) {
          return false;
        }
        final next = _nextValue(value, step);
        return next >= 0 && next <= intermediateMax;
      },
      focusAmounts: [digit],
      focusCap: digit > 1,
      isValidChain: _createSimpleDigitChainValidator(digit),
    );
  }

  if (topicId == 'simple-11-19') {
    final focusAmounts = _rangeInclusive(11, 19);
    return _rule(
      2,
      [..._rangeInclusive(1, 9), ...focusAmounts],
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
      focusAmounts: focusAmounts,
      focusCap: true,
      isValidChain: _createRangeFocusChainValidator(
        (amount) => amount >= 11 && amount <= 19,
      ),
    );
  }

  if (topicId == 'simple-tens') {
    return _rule(2, _tensAmounts(), _allowsDirectOnly);
  }

  if (topicId == 'simple-hundreds') {
    return _rule(3, _hundredsAmounts(), _allowsDirectOnly);
  }

  if (topicId == 'simple-2digit') {
    final focusAmounts = _rangeInclusive(10, 99);
    return _rule(
      2,
      [..._rangeInclusive(1, 9), ...focusAmounts],
      _allowsDirectOnly,
      focusAmounts: focusAmounts,
      focusCap: true,
      isValidChain: _createRangeFocusChainValidator(
        (amount) => amount >= 10 && amount <= 99,
      ),
    );
  }

  if (topicId == 'simple-3digit') {
    final focusAmounts = _rangeInclusive(100, 999);
    return _rule(
      3,
      [..._rangeInclusive(1, 9), ..._rangeInclusive(10, 99), ...focusAmounts],
      _allowsDirectOnly,
      focusAmounts: focusAmounts,
      focusCap: true,
      isValidChain: _createRangeFocusChainValidator(
        (amount) => amount >= 100 && amount <= 999,
      ),
    );
  }

  return null;
}
