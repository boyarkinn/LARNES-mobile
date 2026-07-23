/// Web: `platform/src/trainers/mental-arithmetic/chain-generator/generate.ts`

import 'dart:math';

import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/classify.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/model.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/topics.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/topic_rule.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

const _maxChainRestarts = 800;
const _maxStepBacktracks = 12;

class GenerateConfigError implements Exception {
  GenerateConfigError(this.message);

  final String message;

  @override
  String toString() => 'GenerateConfigError: $message';
}

class GenerateNotImplementedError implements Exception {
  GenerateNotImplementedError(this.topicId);

  final String topicId;

  @override
  String toString() =>
      'GenerateNotImplementedError: generateChain is not implemented for topic "$topicId".';
}

class GenerateFailedError implements Exception {
  GenerateFailedError(this.topicId, [this.detail]);

  final String topicId;
  final String? detail;

  @override
  String toString() =>
      detail ?? 'GenerateFailedError: Failed to generate chain for topic "$topicId".';
}

GenerateConfig assertGenerateConfig(GenerateConfig config) {
  final topicId = config.topicId.trim();

  if (!isTopicId(topicId)) {
    throw GenerateConfigError('Unknown topicId: ${config.topicId}');
  }

  final actionCount = config.actionCount;

  if (actionCount < kActionCountMin || actionCount > kActionCountMax) {
    throw GenerateConfigError(
      'actionCount must be an integer from $kActionCountMin to $kActionCountMax.',
    );
  }

  if (!isSignMode(config.signMode)) {
    throw GenerateConfigError(
      'signMode must be one of: ${knownSignModes.join(', ')}.',
    );
  }

  final rawScope = config.amountScope;

  if (!isAmountScope(rawScope)) {
    throw GenerateConfigError(
      'amountScope must be one of: ${knownAmountScopes.join(', ')}.',
    );
  }

  getTopicMeta(topicId);

  return GenerateConfig(
    actionCount: actionCount,
    amountScope: rawScope,
    signMode: config.signMode,
    topicId: topicId,
  );
}

void _shuffleInPlace<T>(List<T> items, double Function() random) {
  for (var index = items.length - 1; index > 0; index -= 1) {
    final swapIndex = (random() * (index + 1)).floor();
    final tmp = items[index];
    items[index] = items[swapIndex];
    items[swapIndex] = tmp;
  }
}

List<String> _signsForMode(SignMode signMode, int value, int stepIndex) {
  if (signMode == 'add') {
    return ['+'];
  }

  if (signMode == 'sub') {
    if (stepIndex == 0) {
      return ['+'];
    }
    return ['-'];
  }

  if (value == 0) {
    return ['+'];
  }

  return ['+', '-'];
}

({List<ChainStep> target, List<ChainStep> setup, List<ChainStep> rest})
    _collectCandidates(
  int value,
  int stepIndex,
  SignMode signMode,
  TopicRule rule,
) {
  final target = <ChainStep>[];
  final setup = <ChainStep>[];
  final rest = <ChainStep>[];

  for (final sign in _signsForMode(signMode, value, stepIndex)) {
    for (final amount in rule.candidateAmounts) {
      final step = ChainStep(amount: amount, sign: sign);
      final next = tryApplyChainStep(value, step, rule.totalRods);

      if (next == null) {
        continue;
      }

      final technique = classifyStep(value, step, rule.totalRods);

      if (!rule.allows(value, step, technique)) {
        continue;
      }

      if (technique.kind == TechniqueKind.friend ||
          technique.kind == TechniqueKind.friendBrother) {
        target.add(step);
      } else if (technique.kind == TechniqueKind.brother) {
        setup.add(step);
      } else {
        rest.add(step);
      }
    }
  }

  return (target: target, setup: setup, rest: rest);
}

List<ChainStep> _pickCandidatePool(
  ({List<ChainStep> target, List<ChainStep> setup, List<ChainStep> rest}) groups,
  double Function() random,
) {
  if (groups.target.isNotEmpty) {
    return groups.target;
  }

  if (groups.setup.isNotEmpty && groups.rest.isNotEmpty) {
    return random() < 0.55 ? groups.setup : [...groups.setup, ...groups.rest];
  }

  if (groups.setup.isNotEmpty) {
    return groups.setup;
  }

  return groups.rest;
}

Chain? _tryBuildChain(
  GenerateConfig config,
  TopicRule rule,
  double Function() random,
) {
  final steps = <ChainStep>[];
  final intermediates = [0];
  var value = 0;

  for (var stepIndex = 0; stepIndex < config.actionCount; stepIndex += 1) {
    var placed = false;

    for (var backtrack = 0; backtrack < _maxStepBacktracks; backtrack += 1) {
      final groups =
          _collectCandidates(value, stepIndex, config.signMode, rule);
      final pool = _pickCandidatePool(groups, random);

      if (pool.isEmpty) {
        break;
      }

      _shuffleInPlace(pool, random);
      final step = pool[0];
      value = applyChainStep(value, step, rule.totalRods);
      steps.add(step);
      intermediates.add(value);
      placed = true;
      break;
    }

    if (!placed) {
      return null;
    }
  }

  final validator = rule.isValidChain;
  if (validator != null && !validator(steps, intermediates)) {
    return null;
  }

  return Chain(
    answer: value,
    intermediates: intermediates,
    steps: steps,
    topicId: config.topicId,
  );
}

class GenerateChainOptions {
  const GenerateChainOptions({this.random, this.rule});

  final double Function()? random;
  final TopicRule? rule;
}

Chain generateChain(
  GenerateConfig config, [
  GenerateChainOptions options = const GenerateChainOptions(),
]) {
  final normalized = assertGenerateConfig(config);
  final random = options.random ?? Random().nextDouble;

  late final TopicRule rule;

  if (options.rule != null) {
    rule = options.rule!;
  } else {
    try {
      rule = getTopicRule(normalized.topicId, normalized.amountScope);
    } on TopicRuleNotImplementedError catch (error) {
      throw GenerateNotImplementedError(error.topicId);
    }
  }

  for (var attempt = 0; attempt < _maxChainRestarts; attempt += 1) {
    final chain = _tryBuildChain(normalized, rule, random);
    if (chain != null) {
      return chain;
    }
  }

  throw GenerateFailedError(
    normalized.topicId,
    'Failed after $_maxChainRestarts restarts.',
  );
}
