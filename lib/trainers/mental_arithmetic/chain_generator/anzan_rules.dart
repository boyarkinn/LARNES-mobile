/// Web: `platform/src/trainers/mental-arithmetic/chain-generator/anzan-rules.ts`
///
/// 1digit: add|sub|mix; 2/3 знака — только mix, матрица ширин как у Просто.

import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/classify.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/simple_rules.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/topics.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

List<int> _rangeInclusive(int from, int to) {
  return [for (var amount = from; amount <= to; amount++) amount];
}

({
  String kind,
  SignMode? signMode,
  bool? onlyTwoDigit,
  ThreeDigitWidth? threeWidth,
})? _parseAnzanTopic(TopicId topicId) {
  final oneDigit = RegExp(r'^anzan-1digit-(add|sub|mix)$').firstMatch(topicId);
  if (oneDigit != null) {
    return (
      kind: '1digit',
      signMode: oneDigit.group(1)!,
      onlyTwoDigit: null,
      threeWidth: null,
    );
  }

  if (topicId == 'anzan-2digit-1digit') {
    return (
      kind: '2digit',
      signMode: null,
      onlyTwoDigit: false,
      threeWidth: null,
    );
  }
  if (topicId == 'anzan-2digit') {
    return (
      kind: '2digit',
      signMode: null,
      onlyTwoDigit: true,
      threeWidth: null,
    );
  }

  final threeDigitWidth = parseThreeDigitWidth(topicId, 'anzan');
  if (threeDigitWidth != null) {
    return (
      kind: '3digit',
      signMode: null,
      onlyTwoDigit: null,
      threeWidth: threeDigitWidth,
    );
  }

  return null;
}

/// Если topic задаёт знак — вернуть его; иначе null.
SignMode? resolveAnzanSignMode(TopicId topicId) {
  return _parseAnzanTopic(topicId)?.signMode;
}

TopicChainValidator _createAnzanTechniqueValidator(int totalRods) {
  return (steps, intermediates) {
    if (!hasEnoughSimpleTopicVariation(steps, 0)) {
      return false;
    }

    var hasDirect = false;
    var hasBrother = false;
    var hasFriend = false;
    var hasNonDirect = false;

    for (var index = 0; index < steps.length; index += 1) {
      final technique =
          classifyStep(intermediates[index], steps[index], totalRods);

      if (technique.kind == TechniqueKind.direct) {
        hasDirect = true;
      } else {
        hasNonDirect = true;
      }

      if (technique.kind == TechniqueKind.brother) {
        hasBrother = true;
      }

      if (technique.kind == TechniqueKind.friend) {
        hasFriend = true;
      }
    }

    if (steps.length >= 5) {
      return hasDirect && hasBrother && hasFriend;
    }

    if (steps.length >= 4) {
      return hasNonDirect;
    }

    return true;
  };
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

  if (parsed.kind == '1digit') {
    return TopicRule(
      allows: (_, __, ___) => true,
      balanceAmounts: false,
      candidateAmounts: _rangeInclusive(1, 9),
      forcedFirstStep: parsed.signMode == 'sub'
          ? const ChainStep(amount: 99, sign: '+')
          : null,
      isValidChain: _createAnzanTechniqueValidator(2),
      techniqueSummary: true,
      totalRods: 2,
    );
  }

  if (parsed.kind == '2digit') {
    final onlyTwo = parsed.onlyTwoDigit == true;
    final TopicChainValidator widthValidator = onlyTwo
        ? (steps, _) => chainIsOnlyTwoDigitAmounts(steps)
        : (steps, _) => chainHasMixedDigitWidths(steps);

    return TopicRule(
      allows: (_, __, ___) => true,
      balanceAmounts: true,
      candidateAmounts:
          onlyTwo ? _rangeInclusive(10, 99) : _rangeInclusive(1, 99),
      isValidChain: andChainValidators([
        _createAnzanTechniqueValidator(2),
        widthValidator,
      ]),
      preferDigitWidths: onlyTwo ? null : const ['2', '1'],
      techniqueSummary: true,
      totalRods: 2,
    );
  }

  final threeWidth = parsed.threeWidth!;
  return TopicRule(
    allows: (_, __, ___) => true,
    balanceAmounts: true,
    candidateAmounts: candidatesForThreeDigitWidth(threeWidth),
    isValidChain: andChainValidators([
      _createAnzanTechniqueValidator(3),
      widthValidatorForThreeDigit(threeWidth),
    ]),
    preferDigitWidths: preferDigitWidthsForThreeDigit(threeWidth),
    techniqueSummary: true,
    totalRods: 3,
  );
}
