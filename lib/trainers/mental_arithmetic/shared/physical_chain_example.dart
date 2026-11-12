import 'package:larnes_mobile/trainers/mental_arithmetic/shared/spoken_arithmetic.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_number_motion.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

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
    audioSequences[audioKey] = spokenArithmeticStepKeys(
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
    ...spokenArithmeticAmountKeys(chain.answer, locale),
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
