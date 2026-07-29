/// Web: `platform/src/trainers/mental-arithmetic/chain-generator/generate.ts`

import 'dart:math';

import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/anzan_rules.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/classify.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/model.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/simple_rules.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/topics.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/topic_rule.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/transition_rules.dart';
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

  // Curriculum: default withLower; param deprecated.
  final rawScope = config.amountScope;

  if (!isAmountScope(rawScope)) {
    throw GenerateConfigError(
      'amountScope must be one of: ${knownAmountScopes.join(', ')}.',
    );
  }

  getTopicMeta(topicId);

  final anzanSign = resolveAnzanSignMode(topicId);

  return GenerateConfig(
    actionCount: actionCount,
    amountScope: rawScope,
    signMode: anzanSign ?? config.signMode,
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

bool _isFocusStep(ChainStep step, List<int>? focusAmounts) {
  return focusAmounts != null && focusAmounts.contains(step.amount);
}

bool _isImmediateReverse(ChainStep? previous, ChainStep next) {
  return previous != null &&
      previous.amount == next.amount &&
      previous.sign != next.sign;
}

/// Запас ≥1 на каждый оставшийся шаг (длинный add/sub анзан и др.).
List<ChainStep> _preferHeadroomSteps(
  List<ChainStep> pool,
  int value,
  int stepIndex,
  int actionCount,
  int totalRods,
  SignMode signMode,
) {
  final remainingAfter = actionCount - stepIndex - 1;

  if (remainingAfter <= 0 || pool.length <= 1) {
    return pool;
  }

  if (signMode == 'add' || signMode == 'mix') {
    final maxAmount = maxValueForRods(totalRods) - value - remainingAfter;
    if (maxAmount >= 1) {
      final safe = pool
          .where((step) => step.sign == '-' || step.amount <= maxAmount)
          .toList();
      if (safe.isNotEmpty) {
        return safe;
      }
    }
  }

  if (signMode == 'sub') {
    if (stepIndex == 0) {
      final safe = pool
          .where((step) => step.sign == '+' && step.amount >= remainingAfter)
          .toList();
      return safe.isNotEmpty ? safe : pool;
    }

    final safe = pool
        .where(
          (step) =>
              step.sign == '+' || value - step.amount >= remainingAfter,
        )
        .toList();
    return safe.isNotEmpty ? safe : pool;
  }

  return pool;
}

/// Pre-slot: minFocus…⌊actionCount/2⌋ разных индексов (Просто N>1).
Set<int> _sampleFocusSlots(
  int actionCount,
  double Function() random, [
  int minFocus = 1,
]) {
  final maxFocus = (actionCount / 2).floor();
  if (maxFocus < 1) {
    return <int>{};
  }

  final minCount = maxFocus < minFocus ? maxFocus : (minFocus < 1 ? 1 : minFocus);
  final focusCount =
      minCount + (random() * (maxFocus - minCount + 1)).floor();
  final indices = [for (var index = 0; index < actionCount; index++) index];
  _shuffleInPlace(indices, random);

  // При длине ≥5 — ≥1 слот вне 0–1 (анти front-load после restart-bias).
  if (actionCount >= 5) {
    final later = indices.where((index) => index >= 2).toList();
    final early = indices.where((index) => index <= 1).toList();
    final slots = <int>{later.first};
    final restPool = [...later.skip(1), ...early];
    _shuffleInPlace(restPool, random);

    for (final index in restPool) {
      if (slots.length >= focusCount) {
        break;
      }
      slots.add(index);
    }

    return slots;
  }

  return indices.take(focusCount).toSet();
}

bool _isFocusTechniqueStep(
  int value,
  ChainStep step,
  int totalRods,
  List<TechniqueKind> focusTechniques,
  int? focusTechniqueN,
) {
  final technique = classifyStep(value, step, totalRods);

  if (!focusTechniques.contains(technique.kind)) {
    return false;
  }

  if (focusTechniqueN == null) {
    return true;
  }

  return technique.n == focusTechniqueN;
}

List<ChainStep> _pickCandidatePool(
  ({List<ChainStep> target, List<ChainStep> setup, List<ChainStep> rest}) groups,
  double Function() random, {
  required List<int>? focusAmounts,
  required List<TechniqueKind>? focusTechniques,
  required int? focusTechniqueN,
  required Set<int>? focusSlots,
  required int stepIndex,
  required int value,
  required int totalRods,
}) {
  if (focusSlots != null &&
      focusTechniques != null &&
      focusTechniques.isNotEmpty) {
    final all = [...groups.target, ...groups.setup, ...groups.rest];
    final focusSteps = all
        .where(
          (step) => _isFocusTechniqueStep(
            value,
            step,
            totalRods,
            focusTechniques,
            focusTechniqueN,
          ),
        )
        .toList();
    final otherSteps = all
        .where(
          (step) => !_isFocusTechniqueStep(
            value,
            step,
            totalRods,
            focusTechniques,
            focusTechniqueN,
          ),
        )
        .toList();

    // Focus-слот жёстко; prior — soft fallback (как Просто curriculum).
    if (focusSlots.contains(stepIndex)) {
      return focusSteps;
    }

    return otherSteps.isNotEmpty ? otherSteps : focusSteps;
  }

  if (groups.target.isNotEmpty) {
    return groups.target;
  }

  if (groups.setup.isNotEmpty && groups.rest.isNotEmpty) {
    return random() < 0.55 ? groups.setup : [...groups.setup, ...groups.rest];
  }

  if (groups.setup.isNotEmpty) {
    return groups.setup;
  }

  if (focusAmounts == null || focusAmounts.isEmpty || focusSlots == null) {
    return groups.rest;
  }

  final focusSteps =
      groups.rest.where((step) => _isFocusStep(step, focusAmounts)).toList();
  final priorSteps =
      groups.rest.where((step) => !_isFocusStep(step, focusAmounts)).toList();

  if (focusSlots.contains(stepIndex)) {
    return focusSteps;
  }

  return priorSteps.isNotEmpty ? priorSteps : focusSteps;
}

Chain? _tryBuildChain(
  GenerateConfig config,
  TopicRule rule,
  double Function() random,
) {
  final steps = <ChainStep>[];
  final intermediates = [0];
  var value = 0;
  final focusAmounts = rule.focusAmounts;
  final focusTechniques = rule.focusTechniques;
  final useAmountSlots =
      (focusAmounts?.isNotEmpty ?? false) && rule.focusCap != false;
  final useTechniqueSlots =
      (focusTechniques?.isNotEmpty ?? false) && rule.focusCap != false;
  final useFocusSlots = useAmountSlots || useTechniqueSlots;
  final focusSlots =
      useFocusSlots
          ? _sampleFocusSlots(
              config.actionCount,
              random,
              rule.minFocusSteps ?? 1,
            )
          : null;

  for (var stepIndex = 0; stepIndex < config.actionCount; stepIndex += 1) {
    var placed = false;

    final forced = rule.forcedFirstStep;
    if (stepIndex == 0 && forced != null) {
      final next = tryApplyChainStep(value, forced, rule.totalRods);
      if (next == null) {
        return null;
      }
      value = next;
      steps.add(forced);
      intermediates.add(value);
      continue;
    }

    for (var backtrack = 0; backtrack < _maxStepBacktracks; backtrack += 1) {
      final groups =
          _collectCandidates(value, stepIndex, config.signMode, rule);
      final pool = _pickCandidatePool(
        groups,
        random,
        focusAmounts: focusAmounts,
        focusTechniques: focusTechniques,
        focusTechniqueN: rule.focusTechniqueN,
        focusSlots: focusSlots,
        stepIndex: stepIndex,
        value: value,
        totalRods: rule.totalRods,
      );

      if (pool.isEmpty) {
        break;
      }

      _shuffleInPlace(pool, random);
      if (rule.balanceAmounts == true) {
        final amountCounts = <int, int>{};
        for (final placedStep in steps) {
          amountCounts[placedStep.amount] =
              (amountCounts[placedStep.amount] ?? 0) + 1;
        }
        pool.sort(
          (left, right) =>
              (amountCounts[left.amount] ?? 0)
                  .compareTo(amountCounts[right.amount] ?? 0),
        );
      }

      final headroomPool = _preferHeadroomSteps(
        pool,
        value,
        stepIndex,
        config.actionCount,
        rule.totalRods,
        config.signMode,
      );
      // Не clear()+addAll на том же списке — потеряем кандидатов.
      if (!identical(headroomPool, pool)) {
        pool
          ..clear()
          ..addAll(headroomPool);
      }

      final boundary = rule.crossBoundary;
      if (boundary != null &&
          !chainCrossesBoundary(intermediates, boundary)) {
        final crossing = pool.where((candidate) {
          final next = tryApplyChainStep(value, candidate, rule.totalRods);
          return next != null &&
              stepCrossesBoundary(value, next, boundary);
        }).toList();
        if (crossing.isNotEmpty) {
          final urgent =
              stepIndex >= config.actionCount - 2 || random() < 0.55;
          if (urgent) {
            pool
              ..clear()
              ..addAll(crossing);
          }
        }
      }

      final preferWidths = rule.preferDigitWidths;
      if (preferWidths != null && preferWidths.isNotEmpty) {
        final present = <String>{
          for (final step in steps)
            if (digitWidthClass(step.amount) != null)
              digitWidthClass(step.amount)!,
        };
        final missing =
            preferWidths.where((width) => !present.contains(width)).toList();
        if (missing.isNotEmpty) {
          final matching = pool.where((candidate) {
            final width = digitWidthClass(candidate.amount);
            return width != null && missing.contains(width);
          }).toList();
          if (matching.isNotEmpty) {
            final urgent = stepIndex >= config.actionCount - missing.length ||
                random() < 0.65;
            if (urgent) {
              pool
                ..clear()
                ..addAll(matching);
            }
          }
        }
      }

      var step = pool[0];
      if (useFocusSlots) {
        final previous = steps.isEmpty ? null : steps.last;
        final preferred = pool
            .where((candidate) => !_isImmediateReverse(previous, candidate))
            .toList();
        step = preferred.isNotEmpty ? preferred[0] : pool[0];
      }
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
