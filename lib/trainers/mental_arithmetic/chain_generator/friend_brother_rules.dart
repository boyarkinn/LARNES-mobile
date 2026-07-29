/// Web: `platform/src/trainers/mental-arithmetic/chain-generator/friend-brother-rules.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/classify.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/friend_rules.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/simple_rules.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/topics.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

const _brotherNs = [1, 2, 3, 4];
const _friendBrotherSchoolOrder = [6, 7, 8, 9];

bool _isFriendBrotherN(int value) =>
    value == 6 || value == 7 || value == 8 || value == 9;

List<int> _priorFriendBrotherNs(int n) {
  final index = _friendBrotherSchoolOrder.indexOf(n);
  return index <= 0 ? const [] : _friendBrotherSchoolOrder.sublist(0, index);
}

List<int> _rangeInclusive(int from, int to) {
  return [for (var amount = from; amount <= to; amount++) amount];
}

TopicRule _rule(
  int totalRods,
  List<int> candidateAmounts,
  TopicAllows allows,
  TopicChainValidator isValidChain, {
  required int focusTechniqueN,
}) {
  return TopicRule(
    allows: allows,
    candidateAmounts: candidateAmounts,
    focusCap: true,
    focusTechniqueN: focusTechniqueN,
    focusTechniques: const [TechniqueKind.friendBrother],
    isValidChain: isValidChain,
    totalRods: totalRods,
  );
}

List<int> _placeAmounts(int n, int totalRods) {
  final amounts = [n];
  if (totalRods >= 2) {
    amounts.add(n * 10);
  }
  return amounts;
}

bool _isFocusFriendBrother(Technique technique, int n) {
  return technique.kind == TechniqueKind.friendBrother && technique.n == n;
}

bool _isAllowedFriendBrotherTechnique(
  Technique technique,
  int n,
  List<int> priorNs,
) {
  if (technique.kind == TechniqueKind.friendBrother) {
    return technique.n == n || priorNs.contains(technique.n);
  }
  if (technique.kind == TechniqueKind.friend) {
    return true;
  }
  if (technique.kind == TechniqueKind.brother) {
    return _brotherNs.contains(technique.n);
  }
  return technique.kind == TechniqueKind.direct;
}

TopicAllows _allowsFriendBrother(int n, List<int> priorNs, int totalRods) {
  return (value, step, _) {
    if (violatesFriendFiftyZone(value, step)) {
      return false;
    }
    return everyPlaceTechnique(
      value,
      step,
      totalRods,
      (technique) => _isAllowedFriendBrotherTechnique(technique, n, priorNs),
    );
  };
}

TopicChainValidator _createFriendBrotherChainValidator(int totalRods, int n) {
  return (steps, intermediates) {
    final focusIndices = <int>[];
    var priorCount = 0;

    for (var index = 0; index < steps.length; index += 1) {
      final technique =
          classifyStep(intermediates[index], steps[index], totalRods);

      if (_isFocusFriendBrother(technique, n)) {
        focusIndices.add(index);
      } else {
        priorCount += 1;
      }
    }

    if (focusIndices.isEmpty) {
      return false;
    }

    if (focusIndices.length > steps.length ~/ 2) {
      return false;
    }

    if (steps.length >= 5 && !focusIndices.any((index) => index >= 2)) {
      return false;
    }

    if (steps.length >= 4 && priorCount < 1) {
      return false;
    }

    return hasEnoughSimpleTopicVariation(steps, 0);
  };
}

List<int> _candidatesForFriendBrother(
  int n,
  int placeWidth,
  List<int> priorNs, {
  required bool includeOnes,
}) {
  if (!includeOnes) {
    return _rangeInclusive(10, 99);
  }

  final amounts = {..._rangeInclusive(1, 9)};

  for (final focusN in [n, ...priorNs]) {
    amounts.addAll(_placeAmounts(focusN, placeWidth));
    final complement = 10 - focusN;
    if (complement >= 1 && complement <= 9) {
      amounts.addAll(_placeAmounts(complement, placeWidth));
    }
  }

  for (final brotherN in _brotherNs) {
    amounts.addAll(_placeAmounts(brotherN, placeWidth));
  }

  return amounts.toList();
}

({int n, String width})? _parseFriendBrotherTopic(String topicId) {
  final match =
      RegExp(r'^friend-brother-([6-9])-(1digit|2digit)$').firstMatch(topicId);
  if (match == null) {
    return null;
  }

  final n = int.parse(match.group(1)!);
  if (!_isFriendBrotherN(n)) {
    return null;
  }

  return (n: n, width: match.group(2)!);
}

TopicRule? createFriendBrotherTopicRule(
  TopicId topicId, [
  AmountScope amountScope = 'withLower',
]) {
  final meta = getTopicMeta(topicId);

  if (meta.block != TopicBlock.friendBrother) {
    return null;
  }

  final parsed = _parseFriendBrotherTopic(topicId);
  if (parsed == null) {
    return null;
  }

  final n = parsed.n;
  final width = parsed.width;
  final placeWidth = width == '1digit' ? 1 : 2;
  final includeOnes = width != '2digit';
  final priorNs = _priorFriendBrotherNs(n);
  final candidates = _candidatesForFriendBrother(
    n,
    placeWidth,
    priorNs,
    includeOnes: includeOnes,
  );
  final techniqueValidator = _createFriendBrotherChainValidator(2, n);
  final TopicChainValidator widthValidator = width == '2digit'
      ? (steps, _) => chainIsOnlyTwoDigitAmounts(steps)
      : (_, __) => true;

  return _rule(
    2,
    candidates,
    _allowsFriendBrother(n, priorNs, 2),
    andChainValidators([techniqueValidator, widthValidator]),
    focusTechniqueN: n,
  );
}
