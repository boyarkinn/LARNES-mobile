import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_example.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_number_motion.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

const _rods = 6;
const _exampleIntro = 'explanation:abacus-topic:simple-1:example-intro';

class _FriendLesson {
  const _FriendLesson(
    this.id,
    this.amount,
    this.pairs,
    this.bases,
    this.example,
    this.answer,
  );
  final String id;
  final int amount;
  final int pairs;
  final List<int> bases;
  final List<int> example;
  final int answer;
}

// Fixed demonstrations and example chains from videos 28–36.
const _lessons = <_FriendLesson>[
  _FriendLesson('friend-9', 9, 3, [], [10, -9, 6, 9], 16),
  _FriendLesson('friend-8', 8, 3, [], [1, 8, 8, -8], 9),
  _FriendLesson('friend-7', 7, 3, [], [10, -7, 6, 7], 16),
  _FriendLesson('friend-6', 6, 3, [], [10, -6, 5, 6], 15),
  _FriendLesson('friend-5', 5, 3, [], [10, -5, 4, 5], 14),
  _FriendLesson('friend-4', 4, 2, [11, 12, 13], [7, 4, 8, -6, -4], 9),
  _FriendLesson('friend-3', 3, 2, [11, 12], [7, 3, 2, -1, -3], 8),
  _FriendLesson('friend-2', 2, 2, [11], [9, 2, -3, -6, 9, -2], 9),
  _FriendLesson('friend-1', 1, 3, [], [9, 1, -4, 3, 1, -1], 9),
];

final List<String> friendLessonIds = List.unmodifiable(
  _lessons.map((lesson) => lesson.id),
);

String _cue(String id, String slug) => 'explanation:abacus-topic:$id:$slug';
String _actionCue(int amount) =>
    'explanation:abacus-topic:action:${amount > 0 ? 'plus' : 'minus'}-${amount.abs()}';

PhysicalGesturePlan _buildLesson(_FriendLesson lesson) {
  final steps = <PhysicalGestureStep>[];
  final checkpoints = <PhysicalGestureCheckpoint>[
    const PhysicalGestureCheckpoint(afterFrame: 0, value: 0),
  ];
  var rods = numberToAbacus(0, _rods);
  var frame = 0;
  int value() => abacusToNumber(rods);

  void setup(int next, [String? audioKey]) {
    if (next == value()) {
      if (audioKey != null) steps.add(NarrationGestureStep(audioKey: audioKey));
      return;
    }
    final result = physicalNumberSetup(rods, next);
    steps.add(
      SetupGestureStep(
        changes: result.changes,
        audioKey: audioKey,
        audioMode: audioKey == null
            ? PhysicalGestureAudioMode.before
            : PhysicalGestureAudioMode.parallel,
        pauseAfterMs: audioKey == null ? 450 : 0,
      ),
    );
    rods = result.rods;
    checkpoints.add(
      PhysicalGestureCheckpoint(afterFrame: ++frame, value: next),
    );
  }

  void move(int amount, bool returnAfter) {
    final next = value() + amount;
    if (next < 0 || next > 999 || amount == 0) {
      throw StateError('Недопустимое действие ДРУГ: ${value()} $amount.');
    }
    final result = physicalNumberMotion(rods, next);
    if (result.frames.isEmpty) {
      throw StateError('Пустое действие ДРУГ: ${lesson.id}.');
    }
    rods = result.rods;
    for (final current in result.values) {
      checkpoints.add(
        PhysicalGestureCheckpoint(afterFrame: ++frame, value: current),
      );
    }
    final audioKey = _actionCue(amount);
    final pauseAfterMs = returnAfter ? 450 : 120;
    if (result.frames.length == 1) {
      steps.add(
        GroupGestureStep(
          moves: result.frames.single,
          audioKey: audioKey,
          audioMode: PhysicalGestureAudioMode.parallel,
          pauseAfterMs: pauseAfterMs,
          returnAfter: returnAfter,
        ),
      );
    } else {
      steps.add(
        SeriesGestureStep(
          frames: result.frames,
          audioKey: audioKey,
          audioMode: PhysicalGestureAudioMode.parallel,
          pauseAfterMs: pauseAfterMs,
          returnAfter: returnAfter,
        ),
      );
    }
  }

  steps.add(NarrationGestureStep(audioKey: _cue(lesson.id, 'intro')));
  setup(10, _cue(lesson.id, 'subtract'));
  move(-lesson.amount, true);
  steps.add(NarrationGestureStep(audioKey: _cue(lesson.id, 'add')));
  move(lesson.amount, true);
  for (var repeat = 1; repeat < lesson.pairs; repeat++) {
    move(-lesson.amount, true);
    move(lesson.amount, true);
  }
  for (final base in lesson.bases) {
    setup(base, _cue(lesson.id, 'from-$base'));
    move(-lesson.amount, true);
    move(lesson.amount, true);
  }
  setup(0);
  steps.add(const NarrationGestureStep(audioKey: _exampleIntro));
  for (var index = 0; index < lesson.example.length; index++) {
    move(lesson.example[index], index == lesson.example.length - 1);
  }
  if (value() != lesson.answer) {
    throw StateError(
      'Неверный ответ ДРУГ ${lesson.id}: ${value()} вместо ${lesson.answer}.',
    );
  }
  steps.add(
    NarrationGestureStep(audioKey: _cue(lesson.id, 'answer-${lesson.answer}')),
  );
  final plan = PhysicalGesturePlan(
    initialRods: numberToAbacus(0, _rods),
    beadTransitionMs: 400,
    steps: List.unmodifiable(steps),
  );
  validatePhysicalGestureExample(plan, checkpoints);
  return plan;
}

final Map<String, PhysicalGesturePlan> friendPlans = Map.unmodifiable({
  for (final lesson in _lessons) lesson.id: _buildLesson(lesson),
});
