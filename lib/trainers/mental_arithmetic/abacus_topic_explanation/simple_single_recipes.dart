import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_example.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

const _rodCount = 6;
const _unitRod = _rodCount - 1;
const _exampleIntro = 'explanation:abacus-topic:simple-1:example-intro';

class _SingleLesson {
  const _SingleLesson(
    this.digit,
    this.bases,
    this.example, {
    this.zeroDemonstrations = 1,
  });

  final int digit;
  final int zeroDemonstrations;
  final List<int> bases;
  final List<int> example;
}

// The rapid examples in lessons 7 and 8 were confirmed against the bead frames.
const _lessons = <_SingleLesson>[
  _SingleLesson(2, [1, 2], [1, 2, -2, 2, -2], zeroDemonstrations: 2),
  _SingleLesson(3, [1], [1, 3, -3, 3, -3], zeroDemonstrations: 2),
  _SingleLesson(4, [], [4, -4, 4]),
  _SingleLesson(5, [], [5, 1, -5, -1, 5]),
  _SingleLesson(6, [1, 2, 3], [1, 6, 2, -6]),
  _SingleLesson(7, [1, 2], [7, 2, -7, -2]),
  _SingleLesson(8, [1], [8, -8, 1, 8, -8]),
  _SingleLesson(9, [], [9, -9, 9, -9], zeroDemonstrations: 2),
];

final List<String> simpleSingleLessonIds = List.unmodifiable(
  _lessons.map((lesson) => 'simple-${lesson.digit}'),
);

String _lessonCue(String lessonId, String slug) =>
    'explanation:abacus-topic:$lessonId:$slug';

String _actionCue(int amount) =>
    'explanation:abacus-topic:action:${amount > 0 ? 'plus' : 'minus'}-${amount.abs()}';

List<AbacusFinger> _fingers(int from, int to) {
  final before = digitToBeads(from);
  final after = digitToBeads(to);
  if (before.heavenUp != after.heavenUp &&
      before.earthCount != after.earthCount) {
    return const [AbacusFinger.thumb, AbacusFinger.indexFinger];
  }
  if (before.heavenUp != after.heavenUp) {
    return const [AbacusFinger.indexFinger];
  }
  return to > from
      ? const [AbacusFinger.thumb]
      : const [AbacusFinger.indexFinger];
}

GroupGestureStep _show(int from, int to, int amount, bool returnAfter) {
  if (to < 0 || to > 9 || to - from != amount) {
    throw StateError('Недопустимое действие в уроке ПРОСТО.');
  }
  return GroupGestureStep(
    moves: [
      PhysicalBeadMove(
        rodIndex: _unitRod,
        to: digitToBeads(to),
        hand: AbacusHand.right,
        fingers: _fingers(from, to),
      ),
    ],
    audioKey: _actionCue(amount),
    audioMode: PhysicalGestureAudioMode.parallel,
    pauseAfterMs: returnAfter ? 450 : 120,
    returnAfter: returnAfter,
  );
}

SetupGestureStep _setup(int to, {String? audioKey}) => SetupGestureStep(
  changes: [BeadOnlyMove(rodIndex: _unitRod, to: digitToBeads(to))],
  audioKey: audioKey,
  audioMode: audioKey == null
      ? PhysicalGestureAudioMode.before
      : PhysicalGestureAudioMode.parallel,
  pauseAfterMs: audioKey == null ? 450 : 0,
);

PhysicalGesturePlan _buildLesson(_SingleLesson lesson) {
  final digit = lesson.digit;
  final id = 'simple-$digit';
  final steps = <PhysicalGestureStep>[
    NarrationGestureStep(audioKey: _lessonCue(id, 'intro')),
    NarrationGestureStep(audioKey: _lessonCue(id, 'add')),
    _show(0, digit, digit, true),
    NarrationGestureStep(audioKey: _lessonCue(id, 'remove')),
    _show(digit, 0, -digit, true),
  ];
  final expected = <int>[0, digit, 0];
  for (var repeat = 1; repeat < lesson.zeroDemonstrations; repeat++) {
    steps.add(_show(0, digit, digit, true));
    steps.add(_show(digit, 0, -digit, true));
    expected.addAll([digit, 0]);
  }
  var current = 0;

  for (final base in lesson.bases) {
    if (base <= current || base + digit > 9) {
      throw StateError('Недопустимое исходное число урока $id.');
    }
    steps.add(_setup(base, audioKey: _lessonCue(id, 'from-$base')));
    expected.add(base);
    steps.add(_show(base, base + digit, digit, true));
    expected.add(base + digit);
    steps.add(_show(base + digit, base, -digit, true));
    expected.add(base);
    current = base;
  }

  if (current != 0) {
    steps.add(_setup(0));
    expected.add(0);
  }
  steps.add(const NarrationGestureStep(audioKey: _exampleIntro));
  current = 0;
  for (var index = 0; index < lesson.example.length; index++) {
    final amount = lesson.example[index];
    final next = current + amount;
    steps.add(_show(current, next, amount, index == lesson.example.length - 1));
    expected.add(next);
    current = next;
  }
  steps.add(NarrationGestureStep(audioKey: _lessonCue(id, 'answer-$current')));

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

final Map<String, PhysicalGesturePlan> simpleSinglePlans = Map.unmodifiable({
  for (final lesson in _lessons) 'simple-${lesson.digit}': _buildLesson(lesson),
});
