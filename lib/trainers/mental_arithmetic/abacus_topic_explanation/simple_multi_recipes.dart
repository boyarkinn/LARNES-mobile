import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_example.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_number_motion.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

const _rods = 6;
const simpleMultiLessonIds = <String>[
  'simple-tens',
  'simple-11-19',
  'simple-44',
  'simple-55',
  'simple-66',
  'simple-77',
  'simple-88',
  'simple-99',
  'simple-hundreds',
  'simple-000',
];

String simpleMultiCue(String lessonId, String slug) {
  if (slug == 'example-intro') {
    return 'explanation:abacus-topic:simple-1:example-intro';
  }
  if (RegExp(r'^(plus|minus)-\d+$').hasMatch(slug)) {
    return 'explanation:abacus-topic:action:$slug';
  }
  return 'explanation:abacus-topic:$lessonId:$slug';
}

class SimpleMultiRecipe {
  const SimpleMultiRecipe({
    required this.plan,
    required this.exampleValues,
    required this.audioKeys,
  });

  final PhysicalGesturePlan plan;
  final List<int> exampleValues;
  final List<String> audioKeys;
}

class _Operation {
  const _Operation(this.sign, this.amount);
  final String sign;
  final int amount;
}

_Operation _op(String sign, int amount) => _Operation(sign, amount);

class _LessonBuilder {
  _LessonBuilder(this.lessonId);

  final String lessonId;
  final steps = <PhysicalGestureStep>[];
  final checkpoints = <PhysicalGestureCheckpoint>[
    const PhysicalGestureCheckpoint(afterFrame: 0, value: 0),
  ];
  final keys = <String>{};
  final exampleValues = <int>[];
  List<RodState> rods = numberToAbacus(0, _rods);
  int frame = 0;

  int get value => abacusToNumber(rods);

  String key(String slug) {
    final result = simpleMultiCue(lessonId, slug);
    keys.add(result);
    return result;
  }

  void narration(String slug) {
    steps.add(NarrationGestureStep(audioKey: key(slug)));
  }

  void checkpoint(int nextValue) {
    checkpoints.add(
      PhysicalGestureCheckpoint(afterFrame: ++frame, value: nextValue),
    );
  }

  /// Establishes the condition while both hands remain at rest.
  void setup(int nextValue, [String? slug]) {
    if (nextValue == value) {
      if (slug != null) narration(slug);
      return;
    }
    final setup = physicalNumberSetup(rods, nextValue);
    steps.add(
      SetupGestureStep(
        changes: setup.changes,
        audioKey: slug == null ? null : key(slug),
        audioMode: slug == null
            ? PhysicalGestureAudioMode.before
            : PhysicalGestureAudioMode.parallel,
        pauseAfterMs: slug == null ? 450 : 0,
      ),
    );
    rods = setup.rods;
    checkpoint(nextValue);
  }

  /// One hand works on one rod per frame; two hands can share a frame.
  void moveTo(
    int nextValue,
    String slug,
    bool returnAfter, [
    bool example = false,
  ]) {
    if (nextValue < 0 || nextValue > 999 || nextValue == value) {
      throw RangeError('Invalid $lessonId transition $value -> $nextValue.');
    }
    final motion = physicalNumberMotion(rods, nextValue);
    rods = motion.rods;
    final frames = motion.frames;
    for (final value in motion.values) {
      checkpoint(value);
    }
    final audioKey = key(slug);
    final pauseAfterMs = returnAfter ? 450 : 120;
    if (frames.length == 1) {
      steps.add(
        GroupGestureStep(
          moves: frames.single,
          pauseAfterMs: pauseAfterMs,
          returnAfter: returnAfter,
          audioKey: audioKey,
          audioMode: PhysicalGestureAudioMode.parallel,
        ),
      );
    } else {
      steps.add(
        SeriesGestureStep(
          frames: frames,
          pauseAfterMs: pauseAfterMs,
          returnAfter: returnAfter,
          audioKey: audioKey,
          audioMode: PhysicalGestureAudioMode.parallel,
        ),
      );
    }
    if (value != nextValue) {
      throw StateError('Incomplete $lessonId movement to $nextValue.');
    }
    if (example) exampleValues.add(nextValue);
  }

  void operation(
    _Operation operation,
    bool returnAfter, [
    bool example = false,
  ]) {
    final positive = operation.sign == '+';
    final slug = '${positive ? 'plus' : 'minus'}-${operation.amount}';
    moveTo(
      value + (positive ? operation.amount : -operation.amount),
      slug,
      returnAfter,
      example,
    );
  }

  void example(List<_Operation> operations, int answer) {
    if (value != 0) setup(0);
    narration('example-intro');
    for (var index = 0; index < operations.length; index++) {
      operation(operations[index], index == operations.length - 1, true);
    }
    if (value != answer) {
      throw StateError('Wrong $lessonId example: $value, expected $answer.');
    }
    narration('answer-$answer');
  }

  SimpleMultiRecipe finish() {
    final plan = PhysicalGesturePlan(
      initialRods: numberToAbacus(0, _rods),
      steps: List.unmodifiable(steps),
      beadTransitionMs: 400,
    );
    validatePhysicalGestureExample(plan, checkpoints);
    return SimpleMultiRecipe(
      plan: plan,
      exampleValues: List.unmodifiable(exampleValues),
      audioKeys: List.unmodifiable(keys),
    );
  }
}

SimpleMultiRecipe _pairLesson(
  String id,
  int amount,
  List<_Operation> example,
  int answer, [
  List<int> bases = const [0],
  int repetitions = 1,
]) {
  final lesson = _LessonBuilder(id);
  lesson.narration('intro');
  lesson.narration('add');
  lesson.operation(_op('+', amount), true);
  lesson.narration('remove');
  lesson.operation(_op('-', amount), true);
  for (var repeat = 1; repeat < repetitions; repeat++) {
    lesson.operation(_op('+', amount), true);
    lesson.operation(_op('-', amount), true);
  }
  for (final base in bases.where((value) => value != 0)) {
    lesson.setup(base, 'from-$base');
    lesson.operation(_op('+', amount), true);
    lesson.operation(_op('-', amount), true);
  }
  lesson.example(example, answer);
  return lesson.finish();
}

SimpleMultiRecipe _ladderLesson(
  String id,
  List<int> amounts,
  List<_Operation> example,
  int answer,
) {
  final lesson = _LessonBuilder(id);
  lesson.narration('intro');
  lesson.narration('add');
  for (var index = 0; index < amounts.length; index++) {
    final amount = amounts[index];
    lesson.operation(_op('+', amount), true);
    if (index == 0) lesson.narration('remove');
    lesson.operation(_op('-', amount), true);
  }
  lesson.example(example, answer);
  return lesson.finish();
}

SimpleMultiRecipe _hundredsLesson() {
  final lesson = _LessonBuilder('simple-hundreds');
  lesson.narration('intro');
  lesson.narration('add');
  for (var number = 100; number <= 900; number += 100) {
    lesson.moveTo(number, 'number-$number', true);
  }
  lesson.example([
    _op('+', 100),
    _op('+', 800),
    _op('-', 900),
    _op('+', 700),
    _op('-', 600),
    _op('+', 800),
  ], 900);
  return lesson.finish();
}

SimpleMultiRecipe _threeDigitLesson() {
  final lesson = _LessonBuilder('simple-000');
  lesson.narration('intro');
  lesson.narration('explain');
  lesson.example([
    _op('+', 596),
    _op('-', 541),
    _op('+', 444),
    _op('-', 386),
  ], 113);
  return lesson.finish();
}

final Map<String, SimpleMultiRecipe> simpleMultiRecipes = Map.unmodifiable({
  'simple-tens': _ladderLesson(
    'simple-tens',
    [10, 20, 30, 40, 50, 60, 70, 80, 90],
    [
      _op('+', 20),
      _op('+', 70),
      _op('-', 80),
      _op('+', 60),
      _op('+', 20),
      _op('-', 90),
    ],
    0,
  ),
  'simple-11-19': _ladderLesson(
    'simple-11-19',
    [11, 12, 13, 14, 15, 16, 17, 18, 19],
    [
      _op('+', 11),
      _op('+', 8),
      _op('-', 19),
      _op('+', 14),
      _op('-', 13),
      _op('+', 15),
    ],
    16,
  ),
  'simple-44': _pairLesson(
    'simple-44',
    44,
    [_op('+', 22), _op('-', 11), _op('+', 33), _op('-', 44), _op('+', 42)],
    42,
    const [0],
    2,
  ),
  'simple-55': _pairLesson('simple-55', 55, [
    _op('+', 44),
    _op('+', 55),
    _op('-', 33),
    _op('-', 11),
    _op('-', 55),
    _op('+', 45),
  ], 45),
  'simple-66': _pairLesson(
    'simple-66',
    66,
    [_op('+', 66), _op('-', 55), _op('+', 66), _op('+', 22), _op('-', 66)],
    33,
    const [0, 11, 22, 33],
  ),
  'simple-77': _pairLesson(
    'simple-77',
    77,
    [_op('+', 77), _op('+', 11), _op('-', 77), _op('+', 73), _op('-', 74)],
    10,
    const [0, 11, 22],
  ),
  'simple-88': _pairLesson(
    'simple-88',
    88,
    [_op('+', 10), _op('+', 88), _op('-', 88), _op('+', 34), _op('-', 44)],
    0,
    const [0, 11],
  ),
  'simple-99': _pairLesson(
    'simple-99',
    99,
    [_op('+', 44), _op('+', 55), _op('-', 99), _op('+', 99)],
    99,
    const [0],
    2,
  ),
  'simple-hundreds': _hundredsLesson(),
  'simple-000': _threeDigitLesson(),
});

final Map<String, PhysicalGesturePlan> simpleMultiPlans = Map.unmodifiable({
  for (final id in simpleMultiLessonIds) id: simpleMultiRecipes[id]!.plan,
});
