import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_example.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_number_motion.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

const _rods = 6;

class _FriendBrotherLesson {
  const _FriendBrotherLesson(
    this.id,
    this.amount,
    this.addBases,
    this.subtractBases,
  );
  final String id;
  final int amount;
  final List<int> addBases;
  final List<int> subtractBases;
}

// Fixed cases from videos 37–40, without an invented final example chain.
const _lessons = <_FriendBrotherLesson>[
  _FriendBrotherLesson('friend-brother-6', 6, [5, 6, 7, 8], [11, 12, 13, 14]),
  _FriendBrotherLesson('friend-brother-7', 7, [5, 6, 7], [12, 13, 14]),
  _FriendBrotherLesson('friend-brother-8', 8, [5, 6], [13, 14]),
  _FriendBrotherLesson('friend-brother-9', 9, [5], [14]),
];

final List<String> friendBrotherLessonIds = List.unmodifiable(
  _lessons.map((lesson) => lesson.id),
);

String _cue(String id, String slug) => 'explanation:abacus-topic:$id:$slug';
String _actionCue(int amount) =>
    'explanation:abacus-topic:action:${amount > 0 ? 'plus' : 'minus'}-${amount.abs()}';

PhysicalGesturePlan _buildLesson(_FriendBrotherLesson lesson) {
  final steps = <PhysicalGestureStep>[
    NarrationGestureStep(audioKey: _cue(lesson.id, 'intro')),
  ];
  final checkpoints = <PhysicalGestureCheckpoint>[
    const PhysicalGestureCheckpoint(afterFrame: 0, value: 0),
  ];
  var rods = numberToAbacus(0, _rods);
  var frame = 0;

  void setup(int value, String audioKey) {
    if (abacusToNumber(rods) == value) {
      steps.add(NarrationGestureStep(audioKey: audioKey));
      return;
    }
    final result = physicalNumberSetup(rods, value);
    steps.add(
      SetupGestureStep(
        changes: result.changes,
        audioKey: audioKey,
        audioMode: PhysicalGestureAudioMode.parallel,
        pauseAfterMs: 0,
      ),
    );
    rods = result.rods;
    checkpoints.add(
      PhysicalGestureCheckpoint(afterFrame: ++frame, value: value),
    );
  }

  void move(int delta) {
    final next = abacusToNumber(rods) + delta;
    final result = physicalNumberMotion(rods, next);
    if (result.frames.length != 1 || result.frames.single.length != 2) {
      throw StateError('Ожидалось движение двух рук: ${lesson.id}, $next.');
    }
    steps.add(
      GroupGestureStep(
        moves: result.frames.single,
        audioKey: _actionCue(delta),
        audioMode: PhysicalGestureAudioMode.parallel,
        pauseAfterMs: 450,
        returnAfter: true,
      ),
    );
    rods = result.rods;
    checkpoints.add(
      PhysicalGestureCheckpoint(afterFrame: ++frame, value: next),
    );
  }

  for (final base in lesson.addBases) {
    setup(base, _cue(lesson.id, 'plus-from-$base'));
    move(lesson.amount);
  }
  for (final base in lesson.subtractBases) {
    setup(base, _cue(lesson.id, 'minus-from-$base'));
    move(-lesson.amount);
  }

  final plan = PhysicalGesturePlan(
    initialRods: numberToAbacus(0, _rods),
    beadTransitionMs: 400,
    steps: List.unmodifiable(steps),
  );
  validatePhysicalGestureExample(plan, checkpoints);
  return plan;
}

final Map<String, PhysicalGesturePlan> friendBrotherPlans = Map.unmodifiable({
  for (final lesson in _lessons) lesson.id: _buildLesson(lesson),
});
