import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_example.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_fingers.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

const _rodCount = 6;
const _unitRod = _rodCount - 1;
const _exampleIntro = 'explanation:abacus-topic:simple-1:example-intro';

class _BrotherLesson {
  const _BrotherLesson(this.id, this.subtract, this.bases, this.example);
  final String id;
  final int subtract;
  final List<int> bases;
  final List<int> example;
}

// Fixed demonstrations from videos 23–26; video 24's beads and answer show +6.
const _lessons = <_BrotherLesson>[
  _BrotherLesson('brother-4', 4, [6, 7, 8], [5, -4, 6, -4, 4, -7]),
  _BrotherLesson('brother-3', 3, [6, 7], [5, -3, 6, -3, -3, 3]),
  _BrotherLesson('brother-2', 2, [6], [5, -2, 2, 1, -2]),
  _BrotherLesson('brother-1', 1, [], [5, -1, 1, -1]),
];

final List<String> brotherLessonIds = List.unmodifiable(
  _lessons.map((lesson) => lesson.id),
);

String _cue(String id, String slug) => 'explanation:abacus-topic:$id:$slug';
String _actionCue(int amount) =>
    'explanation:abacus-topic:action:${amount > 0 ? 'plus' : 'minus'}-${amount.abs()}';

SetupGestureStep _setup(int to, {String? audioKey}) => SetupGestureStep(
  changes: [BeadOnlyMove(rodIndex: _unitRod, to: digitToBeads(to))],
  audioKey: audioKey,
  audioMode: audioKey == null
      ? PhysicalGestureAudioMode.before
      : PhysicalGestureAudioMode.parallel,
  pauseAfterMs: audioKey == null ? 450 : 0,
);

GroupGestureStep _show(int from, int amount, bool returnAfter) {
  final to = from + amount;
  if (to < 0 || to > 9 || amount == 0) {
    throw StateError('Недопустимое действие БРАТ: $from $amount.');
  }
  return GroupGestureStep(
    moves: [
      PhysicalBeadMove(
        rodIndex: _unitRod,
        to: digitToBeads(to),
        hand: AbacusHand.right,
        fingers: fingersForPhysicalRodTransition(
          digitToBeads(from),
          digitToBeads(to),
        ),
      ),
    ],
    audioKey: _actionCue(amount),
    audioMode: PhysicalGestureAudioMode.parallel,
    pauseAfterMs: returnAfter ? 450 : 120,
    returnAfter: returnAfter,
  );
}

PhysicalGesturePlan _buildLesson(_BrotherLesson lesson) {
  final id = lesson.id;
  final subtract = lesson.subtract;
  final steps = <PhysicalGestureStep>[
    NarrationGestureStep(audioKey: _cue(id, 'intro')),
    _setup(5, audioKey: _cue(id, 'subtract')),
    _show(5, -subtract, true),
    NarrationGestureStep(audioKey: _cue(id, 'add')),
    _show(5 - subtract, subtract, true),
  ];
  final expected = <int>[0, 5, 5 - subtract, 5];
  for (final base in lesson.bases) {
    steps.add(_setup(base, audioKey: _cue(id, 'from-$base')));
    steps.add(_show(base, -subtract, true));
    steps.add(_show(base - subtract, subtract, true));
    expected.addAll([base, base - subtract, base]);
  }
  steps.add(_setup(0));
  expected.add(0);
  steps.add(const NarrationGestureStep(audioKey: _exampleIntro));
  var current = 0;
  for (var index = 0; index < lesson.example.length; index++) {
    final amount = lesson.example[index];
    steps.add(_show(current, amount, index == lesson.example.length - 1));
    current += amount;
    expected.add(current);
  }
  steps.add(NarrationGestureStep(audioKey: _cue(id, 'answer-$current')));
  final plan = PhysicalGesturePlan(
    initialRods: numberToAbacus(0, _rodCount),
    beadTransitionMs: 400,
    steps: List.unmodifiable(steps),
  );
  validatePhysicalGestureExample(plan, [
    for (var afterFrame = 0; afterFrame < expected.length; afterFrame++)
      PhysicalGestureCheckpoint(
        afterFrame: afterFrame,
        value: expected[afterFrame],
      ),
  ]);
  return plan;
}

final Map<String, PhysicalGesturePlan> brotherPlans = Map.unmodifiable({
  for (final lesson in _lessons) lesson.id: _buildLesson(lesson),
});
