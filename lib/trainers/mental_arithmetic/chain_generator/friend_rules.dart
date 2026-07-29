/// Web: `platform/src/trainers/mental-arithmetic/chain-generator/friend-rules.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/classify.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/simple_rules.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/topics.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

const _friendNs = [1, 2, 3, 4, 5, 6, 7, 8, 9];
const _brotherNs = [1, 2, 3, 4];

/// Порядок преподавания в школе (не 1→9).
const _friendSchoolOrder = [9, 8, 7, 6, 5, 4, 3, 2, 1];

bool _isFriendN(int value) => value >= 1 && value <= 9;

List<int> _priorFriendNs(int n) {
  final index = _friendSchoolOrder.indexOf(n);
  return index <= 0 ? const [] : _friendSchoolOrder.sublist(0, index);
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
  int? minFocusSteps,
  List<String>? preferDigitWidths,
}) {
  return TopicRule(
    allows: allows,
    candidateAmounts: candidateAmounts,
    focusCap: true,
    focusTechniqueN: focusTechniqueN,
    focusTechniques: const [TechniqueKind.friend, TechniqueKind.friendBrother],
    isValidChain: isValidChain,
    minFocusSteps: minFocusSteps,
    preferDigitWidths: preferDigitWidths,
    totalRods: totalRods,
  );
}

List<int> _placeAmountsForFriend(int n, int totalRods) {
  final amounts = [n];
  if (totalRods >= 2) {
    amounts.add(n * 10);
  }
  if (totalRods >= 3) {
    amounts.add(n * 100);
  }
  return amounts;
}

bool _isTargetFriendTechnique(Technique technique, int? n) {
  if (technique.kind != TechniqueKind.friend &&
      technique.kind != TechniqueKind.friendBrother) {
    return false;
  }

  return n == null || technique.n == n;
}

/// Запрет старой МА: переходы 41…49 ±1…9 ↔ 50.
bool violatesFriendFiftyZone(int value, ChainStep step) {
  if (step.amount < 1 || step.amount > 9) {
    return false;
  }

  if (step.sign == '+' && value >= 41 && value <= 49) {
    return value + step.amount == 50;
  }

  if (step.sign == '-' && value == 50) {
    return true;
  }

  return false;
}

bool _isAllowedFriendTechnique(Technique technique, int? n, List<int> priorNs) {
  if (technique.kind == TechniqueKind.friend ||
      technique.kind == TechniqueKind.friendBrother) {
    if (n == null) {
      return true;
    }
    return technique.n == n || priorNs.contains(technique.n);
  }

  if (technique.kind == TechniqueKind.brother) {
    return _brotherNs.contains(technique.n);
  }

  return technique.kind == TechniqueKind.direct;
}

TopicAllows _allowsFriend(int? n, List<int> priorNs, int totalRods) {
  return (value, step, _) {
    if (violatesFriendFiftyZone(value, step)) {
      return false;
    }
    return everyPlaceTechnique(
      value,
      step,
      totalRods,
      (technique) => _isAllowedFriendTechnique(technique, n, priorNs),
    );
  };
}

TopicChainValidator _createFriendChainValidator(
  int totalRods,
  int? n, {
  bool requireFocusOnOnesAndHigher = false,
}) {
  return (steps, intermediates) {
    final focusIndices = <int>[];
    var priorCount = 0;

    for (var index = 0; index < steps.length; index++) {
      final technique =
          classifyStep(intermediates[index], steps[index], totalRods);

      if (_isTargetFriendTechnique(technique, n)) {
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

    if (requireFocusOnOnesAndHigher &&
        !chainHasFocusOnOnesAndHigherPlaces(
          steps,
          intermediates,
          totalRods,
          (technique) => _isTargetFriendTechnique(technique, n),
        )) {
      return false;
    }

    if (!hasEnoughSimpleTopicVariation(steps, 0)) {
      return false;
    }

    return true;
  };
}

List<int> _candidatesForFriendDigit(
  int n,
  int placeWidth,
  List<int> priorNs, {
  required bool includeOnes,
}) {
  if (!includeOnes) {
    return _rangeInclusive(10, 99);
  }

  // Mix: 1…9 + полный 10…99 (не только N·10).
  if (placeWidth >= 2) {
    return [..._rangeInclusive(1, 9), ..._rangeInclusive(10, 99)];
  }

  final amounts = {..._rangeInclusive(1, 9)};

  for (final friendN in [n, ...priorNs]) {
    amounts.addAll(_placeAmountsForFriend(friendN, placeWidth));
    final complement = 10 - friendN;
    if (complement >= 1 && complement <= 9) {
      amounts.addAll(_placeAmountsForFriend(complement, placeWidth));
    }
  }

  for (final brotherN in _brotherNs) {
    amounts.addAll(_placeAmountsForFriend(brotherN, placeWidth));
  }

  return amounts.toList();
}

({int n, String width})? _parseFriendDigitTopic(String topicId) {
  final match =
      RegExp(r'^friend-([1-9])-(1digit|2digit-1digit|2digit)$').firstMatch(topicId);
  if (match == null) {
    return null;
  }

  final n = int.parse(match.group(1)!);
  if (!_isFriendN(n)) {
    return null;
  }

  return (n: n, width: match.group(2)!);
}

/// `amountScope` deprecated — 2/3 знака всегда с младшими.
TopicRule? createFriendTopicRule(
  String topicId, [
  AmountScope amountScope = 'withLower',
]) {
  final meta = getTopicMeta(topicId);

  if (meta.block != TopicBlock.friend) {
    return null;
  }

  final parsed = _parseFriendDigitTopic(topicId);

  if (parsed != null) {
    final n = parsed.n;
    final width = parsed.width;
    final placeWidth = width == '1digit' ? 1 : 2;
    final rods = width == '1digit' ? 2 : 3;
    final includeOnes = width != '2digit';
    final priorNs = _priorFriendNs(n);
    final candidates = _candidatesForFriendDigit(
      n,
      placeWidth,
      priorNs,
      includeOnes: includeOnes,
    );
    final techniqueValidator = _createFriendChainValidator(
      rods,
      n,
      requireFocusOnOnesAndHigher: width != '1digit',
    );
    final TopicChainValidator widthValidator = width == '2digit-1digit'
        ? (steps, _) => chainHasMixedDigitWidths(steps)
        : width == '2digit'
            ? (steps, _) => chainIsOnlyTwoDigitAmounts(steps)
            : (_, __) => true;

    return _rule(
      rods,
      candidates,
      _allowsFriend(n, priorNs, rods),
      andChainValidators([techniqueValidator, widthValidator]),
      focusTechniqueN: n,
      minFocusSteps: width != '1digit' ? 2 : null,
    );
  }

  final threeDigitWidth = parseThreeDigitWidth(topicId, 'friend');
  if (threeDigitWidth != null) {
    final candidates = candidatesForThreeDigitWidth(threeDigitWidth);

    return _rule(
      3,
      candidates,
      _allowsFriend(null, const [], 3),
      andChainValidators([
        _createFriendChainValidator(3, null, requireFocusOnOnesAndHigher: true),
        widthValidatorForThreeDigit(threeDigitWidth),
      ]),
      minFocusSteps: 2,
      preferDigitWidths: preferDigitWidthsForThreeDigit(threeDigitWidth),
    );
  }

  return null;
}
