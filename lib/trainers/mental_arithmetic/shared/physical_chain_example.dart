import 'package:larnes_mobile/trainers/audio/number_bank.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_number_motion.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'physical_example_cues.dart';

/// Build a standalone worked example from the exact already-selected chain.
PhysicalGesturePlan physicalChainExamplePlan(
  Chain chain, {
  double stepSec = 3,
  String locale = 'ru-RU',
}) {
  if (!stepSec.isFinite || stepSec < 0.1 || stepSec > 30) {
    throw RangeError('Интервал разбора должен быть от 0,1 до 30 секунд.');
  }
  if (chain.steps.isEmpty ||
      chain.intermediates.length != chain.steps.length + 1 ||
      chain.intermediates.first != 0) {
    throw ArgumentError(
      'Разбор должен начинаться с нуля и содержать готовую цепочку.',
    );
  }
  final plan = withPhysicalChainExample(
    PhysicalGesturePlan(
      initialRods: List.generate(6, (_) => digitToBeads(0)),
      steps: const [],
      beadTransitionMs: 400,
    ),
    chain,
    introAudioKey: physicalExampleIntroKey,
    answerAudioKey: physicalExampleAnswerKey,
    locale: locale,
  );
  return PhysicalGesturePlan(
    initialRods: plan.initialRods,
    steps: plan.steps,
    beadTransitionMs: plan.beadTransitionMs,
    openingAudioKey: plan.openingAudioKey,
    audioSequences: plan.audioSequences,
    stepPlayback: {
      for (var index = 0; index < chain.steps.length; index++)
        index + 1: PhysicalGestureStepPlayback(
          minimumDurationMs: (stepSec * 1000).round(),
        ),
    },
  );
}

/// Scope introduction, operations and final answer without generating an example.
List<String> physicalChainExampleAudioKeys(
  Chain chain, [
  String locale = 'ru-RU',
]) => {
  physicalExampleIntroKey,
  for (final operation in chain.steps)
    ...stepAudioKeys(
      amount: operation.amount,
      sign: operation.sign,
      locale: locale,
    ),
  physicalExampleAnswerKey,
  ...amountAudioKeys(chain.answer, locale),
}.toList(growable: false);

PhysicalGesturePlan withPhysicalChainExample(
  PhysicalGesturePlan source,
  Chain chain, {
  required String introAudioKey,
  required String answerAudioKey,
  String locale = 'ru-RU',
}) {
  final boundary = source.steps.indexWhere(
    (step) => step.audioKey == introAudioKey,
  );
  final steps = <PhysicalGestureStep>[
    ...(boundary < 0 ? source.steps : source.steps.take(boundary)),
  ];
  final prefix = PhysicalGesturePlan(
    initialRods: source.initialRods,
    steps: steps,
    beadTransitionMs: source.beadTransitionMs,
    audioSequences: source.audioSequences,
  );
  final frames = compilePhysicalGesturePlan(prefix);
  var rods = frames.isEmpty ? source.initialRods : frames.last.rods;
  if (abacusToNumber(rods) != 0) {
    final setup = physicalNumberSetup(rods, 0);
    steps.add(SetupGestureStep(changes: setup.changes, pauseAfterMs: 450));
    rods = setup.rods;
  }
  steps.add(NarrationGestureStep(audioKey: introAudioKey));
  final audioSequences = <String, List<String>>{...source.audioSequences};
  for (var index = 0; index < chain.steps.length; index++) {
    final operation = chain.steps[index];
    final value =
        abacusToNumber(rods) +
        (operation.sign == '+' ? operation.amount : -operation.amount);
    if (value != chain.intermediates[index + 1]) {
      throw StateError('Цепочка не совпадает с промежуточными числами.');
    }
    final result = physicalNumberMotion(rods, value);
    rods = result.rods;
    final audioKey = '\$physical-example:operation:$index';
    audioSequences[audioKey] = stepAudioKeys(
      amount: operation.amount,
      sign: operation.sign,
      locale: locale,
    );
    final isLast = index == chain.steps.length - 1;
    steps.add(
      result.frames.length == 1
          ? GroupGestureStep(
              moves: result.frames.first,
              audioKey: audioKey,
              audioMode: PhysicalGestureAudioMode.parallel,
              pauseAfterMs: isLast ? 450 : 120,
              returnAfter: isLast,
            )
          : SeriesGestureStep(
              frames: result.frames,
              audioKey: audioKey,
              audioMode: PhysicalGestureAudioMode.parallel,
              pauseAfterMs: isLast ? 450 : 120,
              returnAfter: isLast,
            ),
    );
  }
  if (abacusToNumber(rods) != chain.answer) {
    throw StateError('Неверный итог примера.');
  }
  const answerKey = r'$physical-example:answer';
  audioSequences[answerKey] = [
    answerAudioKey,
    ...amountAudioKeys(chain.answer, locale),
  ];
  steps.add(const NarrationGestureStep(audioKey: answerKey));
  return PhysicalGesturePlan(
    initialRods: source.initialRods,
    steps: steps,
    beadTransitionMs: source.beadTransitionMs,
    openingAudioKey: source.openingAudioKey,
    audioSequences: audioSequences,
  );
}
