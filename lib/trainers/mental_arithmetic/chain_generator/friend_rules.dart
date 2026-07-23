/// Web: `platform/src/trainers/mental-arithmetic/chain-generator/friend-rules.ts`

import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/classify.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/topics.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

const _friendNs = [1, 2, 3, 4, 5, 6, 7, 8, 9];

bool _isFriendN(int value) => value >= 1 && value <= 9;

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

bool _isFriendOperandAmount(int amount, int? n) {
  if (n != null) {
    return amount == n || amount == n * 10 || amount == n * 100;
  }

  return _friendNs.any((friendN) => _isFriendOperandAmount(amount, friendN));
}

List<int> _setupAmountsForFriend(int? n, int placeWidth) {
  if (n == null) {
    return _friendNs
        .expand((friendN) => _placeAmountsForFriend(friendN, placeWidth))
        .toList();
  }

  final amounts = _placeAmountsForFriend(n, placeWidth);
  final complement = 10 - n;

  if (complement >= 1 && complement <= 9 && complement != n) {
    amounts.addAll(_placeAmountsForFriend(complement, placeWidth));
  }

  return {...amounts}.toList();
}

bool _isTargetFriendTechnique(Technique technique, int? n) {
  if (technique.kind != TechniqueKind.friend &&
      technique.kind != TechniqueKind.friendBrother) {
    return false;
  }

  return n == null || technique.n == n;
}

TopicAllows _allowsFriend(int? n, List<int> setupAmounts) {
  return (value, step, technique) {
    if (_isTargetFriendTechnique(technique, n)) {
      return n == null || _isFriendOperandAmount(step.amount, n);
    }

    if (!setupAmounts.contains(step.amount)) {
      return false;
    }

    if (technique.kind == TechniqueKind.direct) {
      return true;
    }

    if (technique.kind == TechniqueKind.brother &&
        _isFriendOperandAmount(step.amount, n) &&
        (n == null || technique.n == n)) {
      return true;
    }

    return false;
  };
}

TopicChainValidator _createFriendChainValidator(int totalRods, int? n) {
  return (steps, intermediates) {
    for (var index = 0; index < steps.length; index++) {
      final technique =
          classifyStep(intermediates[index], steps[index], totalRods);

      if (_isTargetFriendTechnique(technique, n)) {
        return true;
      }
    }

    return false;
  };
}

({int n, String width})? _parseFriendDigitTopic(String topicId) {
  final match = RegExp(r'^friend-([1-9])-(1digit|2digit)$').firstMatch(topicId);
  if (match == null) {
    return null;
  }

  final n = int.parse(match.group(1)!);
  if (!_isFriendN(n)) {
    return null;
  }

  return (n: n, width: match.group(2)!);
}

TopicRule? createFriendTopicRule(String topicId, AmountScope amountScope) {
  final meta = getTopicMeta(topicId);

  if (meta.block != TopicBlock.friend) {
    return null;
  }

  final parsed = _parseFriendDigitTopic(topicId);

  if (parsed != null) {
    final n = parsed.n;
    final width = parsed.width;
    final placeWidth = width == '1digit' ? 1 : 2;
    final setupAmounts = _setupAmountsForFriend(n, placeWidth);
    final candidates = amountScope == 'withLower' && width == '2digit'
        ? {..._setupAmountsForFriend(n, 1), ...setupAmounts}.toList()
        : setupAmounts;

    return _rule(
      2,
      candidates,
      _allowsFriend(n, candidates),
      _createFriendChainValidator(2, n),
    );
  }

  if (topicId == 'friend-3digit') {
    final topicOnly =
        _friendNs.expand((n) => _placeAmountsForFriend(n, 3)).toList();
    final candidates = amountScope == 'withLower'
        ? {
            ..._setupAmountsForFriend(null, 1),
            ..._setupAmountsForFriend(null, 2),
            ...topicOnly,
          }.toList()
        : {...topicOnly}.toList();

    return _rule(
      3,
      candidates,
      _allowsFriend(null, candidates),
      _createFriendChainValidator(3, null),
    );
  }

  return null;
}
