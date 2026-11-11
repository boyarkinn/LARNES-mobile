import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_gesture_cues.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

const warmupRodCount = 13;
final _leftToRight = List<int>.generate(warmupRodCount, (index) => index);
final _rightToLeft = _leftToRight.reversed.toList();
final _mirrored = List<(int, int)>.generate(
  6,
  (index) => (index, warmupRodCount - 1 - index),
);
final _friendPairs = List<(int, int)>.generate(
  6,
  (index) => (index * 2 + 1, index * 2 + 2),
);

List<AbacusFinger> _fingersForSetting(int digit) => digit < 5
    ? const [AbacusFinger.thumb]
    : digit == 5
    ? const [AbacusFinger.indexFinger]
    : const [AbacusFinger.thumb, AbacusFinger.indexFinger];

List<AbacusFinger> _fingersForClearing(int digit) => digit < 5
    ? const [AbacusFinger.indexFinger]
    : digit == 5
    ? const [AbacusFinger.indexFinger]
    : const [AbacusFinger.thumb, AbacusFinger.indexFinger];

RodPassGestureStep _pass(
  List<int> indices,
  int digit,
  AbacusHand hand,
  List<AbacusFinger> fingers, [
  int endPauseMs = 0,
  String? audioKey,
]) => RodPassGestureStep(
  rodIndices: indices,
  to: digitToBeads(digit),
  hand: hand,
  fingers: fingers,
  pauseAfterMs: 0,
  pauseAfterPassMs: endPauseMs,
  audioKey: audioKey,
);

PhysicalBeadMove _move(
  int rodIndex,
  int digit,
  AbacusHand hand,
  List<AbacusFinger> fingers,
) => PhysicalBeadMove(
  rodIndex: rodIndex,
  to: digitToBeads(digit),
  hand: hand,
  fingers: fingers,
);

List<PhysicalGestureStep> _simplePasses(AbacusHand hand) {
  final outward = hand == AbacusHand.right ? _rightToLeft : _leftToRight;
  final returnPath = hand == AbacusHand.right ? _leftToRight : _rightToLeft;
  final steps = <PhysicalGestureStep>[];
  for (var digit = 1; digit <= 9; digit++) {
    steps.add(
      _pass(
        outward,
        digit,
        hand,
        _fingersForSetting(digit),
        0,
        simpleSetCue(hand.name, digit),
      ),
    );
    steps.add(
      _pass(
        returnPath,
        0,
        hand,
        _fingersForClearing(digit),
        350,
        simpleClearCue(hand.name, digit),
      ),
    );
  }
  return steps;
}

List<PhysicalGestureStep> _twoHandPasses() {
  final steps = <PhysicalGestureStep>[];
  for (var digit = 1; digit <= 9; digit++) {
    for (var index = 0; index < _mirrored.length; index++) {
      final (left, right) = _mirrored[index];
      steps.add(
        GroupGestureStep(
          moves: [
            _move(left, digit, AbacusHand.left, _fingersForSetting(digit)),
            _move(right, digit, AbacusHand.right, _fingersForSetting(digit)),
          ],
          pauseAfterMs: index == _mirrored.length - 1 ? 600 : 100,
          audioKey: index == 0 ? simpleSetCue('both', digit) : null,
        ),
      );
    }
    for (var index = 0; index < _mirrored.length; index++) {
      final (left, right) = _mirrored[_mirrored.length - 1 - index];
      steps.add(
        GroupGestureStep(
          moves: [
            _move(left, 0, AbacusHand.left, _fingersForClearing(digit)),
            _move(right, 0, AbacusHand.right, _fingersForClearing(digit)),
          ],
          pauseAfterMs: index == _mirrored.length - 1 ? 600 : 100,
          audioKey: index == 0 ? simpleClearCue('both', digit) : null,
        ),
      );
    }
  }
  return steps;
}

List<PhysicalGestureStep> _brothersPasses() {
  const crab = [AbacusFinger.thumb, AbacusFinger.indexFinger];
  final steps = <PhysicalGestureStep>[
    _pass(
      _rightToLeft,
      5,
      AbacusHand.right,
      const [AbacusFinger.indexFinger],
      400,
      heavenCue('right', 'down'),
    ),
  ];
  for (final hand in [AbacusHand.right, AbacusHand.left]) {
    final outward = hand == AbacusHand.right ? _rightToLeft : _leftToRight;
    final returnPath = hand == AbacusHand.right ? _leftToRight : _rightToLeft;
    for (var digit = 1; digit <= 4; digit++) {
      steps.add(
        _pass(
          outward,
          digit,
          hand,
          crab,
          250,
          crabCue(hand.name, digit, 'close', context: 'brothers'),
        ),
      );
      steps.add(
        _pass(
          returnPath,
          5,
          hand,
          crab,
          350,
          crabCue(hand.name, digit, 'open', context: 'brothers'),
        ),
      );
    }
  }
  for (var digit = 1; digit <= 4; digit++) {
    for (var index = 0; index < _mirrored.length; index++) {
      final (left, right) = _mirrored[index];
      steps.add(
        GroupGestureStep(
          moves: [
            _move(left, digit, AbacusHand.left, crab),
            _move(right, digit, AbacusHand.right, crab),
          ],
          pauseAfterMs: index == _mirrored.length - 1 ? 350 : 0,
          audioKey: index == 0
              ? crabCue('both', digit, 'close', context: 'brothers')
              : null,
        ),
      );
    }
    for (var index = 0; index < _mirrored.length; index++) {
      final (left, right) = _mirrored[_mirrored.length - 1 - index];
      steps.add(
        GroupGestureStep(
          moves: [
            _move(left, 5, AbacusHand.left, crab),
            _move(right, 5, AbacusHand.right, crab),
          ],
          pauseAfterMs: index == _mirrored.length - 1 ? 350 : 0,
          audioKey: index == 0
              ? crabCue('both', digit, 'open', context: 'brothers')
              : null,
        ),
      );
    }
  }
  return steps;
}

List<PhysicalGestureStep> _friendsPasses() {
  final steps = <PhysicalGestureStep>[];
  // The video seeds every other rod; each seeded rod is paired with its right neighbour.
  const seeds = [(1, 11), (3, 9), (5, 7)];
  for (var index = 0; index < seeds.length; index++) {
    final (left, right) = seeds[index];
    steps.add(
      GroupGestureStep(
        moves: [
          _move(left, 1, AbacusHand.left, const [AbacusFinger.thumb]),
          _move(right, 1, AbacusHand.right, const [AbacusFinger.thumb]),
        ],
        pauseAfterMs: index == 2 ? 600 : 200,
        audioKey: index == 0 ? friendsSeedCue : null,
      ),
    );
  }
  for (var digit = 1; digit <= 9; digit++) {
    for (var index = 0; index < _friendPairs.length; index++) {
      final (source, target) = _friendPairs[index];
      steps.add(
        GroupGestureStep(
          moves: [
            _move(source, 0, AbacusHand.left, const [AbacusFinger.indexFinger]),
            _move(target, digit, AbacusHand.right, _fingersForSetting(digit)),
          ],
          pauseAfterMs: 900,
          audioKey: index == 0 ? friendsCue(digit) : null,
        ),
      );
    }
    for (final (source, target) in _friendPairs.reversed) {
      steps.add(
        GroupGestureStep(
          moves: [
            _move(source, 1, AbacusHand.left, const [AbacusFinger.thumb]),
            _move(target, 0, AbacusHand.right, _fingersForClearing(digit)),
          ],
          pauseAfterMs: 900,
        ),
      );
    }
  }
  return steps;
}

final _recipeCache = <String, PhysicalGesturePlan>{};

/// Lesson data only: state changes and timing are compiled by the shared player.
PhysicalGesturePlan warmupRecipe(String type) =>
    _recipeCache.putIfAbsent(type, () {
      final initialRods = emptyRods(warmupRodCount);
      return switch (type) {
        'simple-9' => PhysicalGesturePlan(
          initialRods: initialRods,
          steps: _simplePasses(AbacusHand.right),
          beadTransitionMs: 400,
          openingAudioKey: warmupIntroCue(type),
        ),
        'simple-tens' => PhysicalGesturePlan(
          initialRods: initialRods,
          steps: _simplePasses(AbacusHand.left),
          beadTransitionMs: 400,
          openingAudioKey: warmupIntroCue(type),
        ),
        'simple-2digit' => PhysicalGesturePlan(
          initialRods: initialRods,
          steps: _twoHandPasses(),
          openingAudioKey: warmupIntroCue(type),
        ),
        'brothers' => PhysicalGesturePlan(
          initialRods: initialRods,
          steps: _brothersPasses(),
          openingAudioKey: warmupIntroCue(type),
        ),
        'friends' => PhysicalGesturePlan(
          initialRods: initialRods,
          steps: _friendsPasses(),
          openingAudioKey: warmupIntroCue(type),
        ),
        _ => throw ArgumentError.value(type, 'type', 'Неизвестная разминка.'),
      };
    });
