import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_example.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

const simpleOneRodIndex = 12;
const _audioPrefix = 'explanation:abacus-topic:simple-1:';

String simpleOneCue(String slug) => '$_audioPrefix$slug';

GroupGestureStep _change(
  int digit,
  AbacusFinger finger, {
  String? cue,
  int? pauseAfterMs,
  bool returnAfter = false,
}) => GroupGestureStep(
  moves: [
    PhysicalBeadMove(
      rodIndex: simpleOneRodIndex,
      to: digitToBeads(digit),
      hand: AbacusHand.right,
      fingers: [finger],
    ),
  ],
  audioKey: cue == null ? null : simpleOneCue(cue),
  audioMode: cue == null
      ? PhysicalGestureAudioMode.before
      : PhysicalGestureAudioMode.parallel,
  pauseAfterMs: pauseAfterMs ?? (returnAfter ? 450 : 120),
  returnAfter: returnAfter,
);

/// The video starts at zero, demonstrates the technique at bases 0–3, then
/// solves +1 +1 +1 +1 −1 −1 −1 −1. Silent setup steps establish each base.
PhysicalGesturePlan _buildSimpleOne() {
  final steps = <PhysicalGestureStep>[
    NarrationGestureStep(audioKey: simpleOneCue('intro')),
    _change(1, AbacusFinger.thumb, cue: 'add-one'),
    _change(0, AbacusFinger.indexFinger, cue: 'remove-one', returnAfter: true),
  ];

  for (final (base, slug) in [
    (1, 'from-one'),
    (2, 'from-two'),
    (3, 'from-three'),
  ]) {
    steps.add(_change(base, AbacusFinger.thumb));
    steps.add(_change(base + 1, AbacusFinger.thumb, cue: slug));
    steps.add(
      _change(
        base,
        AbacusFinger.indexFinger,
        cue: 'example-minus-one',
        returnAfter: true,
      ),
    );
  }

  steps.add(_change(0, AbacusFinger.indexFinger, returnAfter: true));
  steps.add(NarrationGestureStep(audioKey: simpleOneCue('example-intro')));
  for (var digit = 1; digit <= 4; digit++) {
    steps.add(_change(digit, AbacusFinger.thumb, cue: 'example-plus-one'));
  }
  for (var digit = 3; digit >= 0; digit--) {
    steps.add(
      _change(
        digit,
        AbacusFinger.indexFinger,
        cue: 'example-minus-one',
        returnAfter: digit == 0,
      ),
    );
  }
  final plan = PhysicalGesturePlan(
    initialRods: numberToAbacus(0, 13),
    steps: List.unmodifiable(steps),
    beadTransitionMs: 400,
  );
  validatePhysicalGestureExample(plan, [
    const PhysicalGestureCheckpoint(afterFrame: 0, value: 0),
    for (var index = 0; index < simpleOneFrameValues.length; index++)
      PhysicalGestureCheckpoint(
        afterFrame: index + 1,
        value: simpleOneFrameValues[index],
      ),
  ]);
  return plan;
}

const simpleOneFrameValues = [
  1,
  0,
  1,
  2,
  1,
  2,
  3,
  2,
  3,
  4,
  3,
  0,
  1,
  2,
  3,
  4,
  3,
  2,
  1,
  0,
];

final PhysicalGesturePlan _simpleOne = _buildSimpleOne();

PhysicalGesturePlan topicExplanationRecipe(String lessonId) {
  if (lessonId == 'simple-1') return _simpleOne;
  throw ArgumentError.value(lessonId, 'lessonId', 'Неизвестный урок.');
}
