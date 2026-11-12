import 'abacus_warmup_topics.dart';
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

final _topicByStep = Expando<String>('warmupTopic');
List<PhysicalGestureStep> _tagTopic(
  String id,
  List<PhysicalGestureStep> steps,
) {
  for (final step in steps) {
    _topicByStep[step] = id;
  }
  return steps;
}

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
  returnAfter: true,
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

List<PhysicalGestureStep> _simplePasses(AbacusHand hand, List<int> topics) {
  final outward = hand == AbacusHand.right ? _rightToLeft : _leftToRight;
  final returnPath = hand == AbacusHand.right ? _leftToRight : _rightToLeft;
  final steps = <PhysicalGestureStep>[];
  for (final digit in topics) {
    final start = steps.length;
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
    _tagTopic(
      '${hand == AbacusHand.right ? 'simple-9' : 'simple-tens'}:$digit',
      steps.sublist(start),
    );
  }
  return steps;
}

List<PhysicalGestureStep> _twoHandPasses(List<int> topics) {
  final steps = <PhysicalGestureStep>[];
  for (final digit in topics) {
    final start = steps.length;
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
          returnAfter: index == _mirrored.length - 1,
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
          returnAfter: index == _mirrored.length - 1,
        ),
      );
    }
    _tagTopic('simple-2digit:$digit', steps.sublist(start));
  }
  return steps;
}

const _brotherFingers = [AbacusFinger.thumb, AbacusFinger.indexFinger];

List<PhysicalGestureStep> _brotherHandPasses(AbacusHand hand, int digit) =>
    _tagTopic('brothers:${5 - digit}', [
      _pass(
        hand == AbacusHand.right ? _rightToLeft : _leftToRight,
        digit,
        hand,
        _brotherFingers,
        250,
        crabCue(hand.name, digit, 'close', context: 'brothers'),
      ),
      _pass(
        hand == AbacusHand.right ? _leftToRight : _rightToLeft,
        5,
        hand,
        _brotherFingers,
        350,
        crabCue(hand.name, digit, 'open', context: 'brothers'),
      ),
    ]);

List<PhysicalGestureStep> _brotherBothHandPasses(int digit) {
  final steps = <PhysicalGestureStep>[];
  for (final (index, (left, right)) in _mirrored.indexed) {
    steps.add(
      GroupGestureStep(
        moves: [
          _move(left, digit, AbacusHand.left, _brotherFingers),
          _move(right, digit, AbacusHand.right, _brotherFingers),
        ],
        pauseAfterMs: index == _mirrored.length - 1 ? 350 : 0,
        audioKey: index == 0
            ? crabCue('both', digit, 'close', context: 'brothers')
            : null,
        returnAfter: index == _mirrored.length - 1,
      ),
    );
  }
  for (final (index, (left, right)) in _mirrored.reversed.indexed) {
    steps.add(
      GroupGestureStep(
        moves: [
          _move(left, 5, AbacusHand.left, _brotherFingers),
          _move(right, 5, AbacusHand.right, _brotherFingers),
        ],
        pauseAfterMs: index == _mirrored.length - 1 ? 350 : 0,
        audioKey: index == 0
            ? crabCue('both', digit, 'open', context: 'brothers')
            : null,
        returnAfter: index == _mirrored.length - 1,
      ),
    );
  }
  return _tagTopic('brothers:${5 - digit}', steps);
}

List<PhysicalGestureStep> _brothersPasses(List<int> topics, bool fullBlock) {
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
  _tagTopic('brothers:${topics.first}', steps);
  final digits = topics.map((number) => 5 - number);
  if (fullBlock) {
    for (final hand in [AbacusHand.right, AbacusHand.left]) {
      for (final digit in digits) {
        steps.addAll(_brotherHandPasses(hand, digit));
      }
    }
    for (final digit in digits) {
      steps.addAll(_brotherBothHandPasses(digit));
    }
  } else {
    for (final digit in digits) {
      for (final hand in [AbacusHand.right, AbacusHand.left]) {
        steps.addAll(_brotherHandPasses(hand, digit));
      }
      steps.addAll(_brotherBothHandPasses(digit));
    }
  }
  return steps;
}

List<PhysicalGestureStep> _friendsPasses(List<int> topics) {
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
        returnAfter: index == seeds.length - 1,
      ),
    );
  }
  _tagTopic('friends:${topics.first}', steps);
  for (final number in topics) {
    final start = steps.length;
    final digit = 10 - number;
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
    for (var index = 0; index < _friendPairs.length; index++) {
      final (source, target) = _friendPairs[_friendPairs.length - 1 - index];
      steps.add(
        GroupGestureStep(
          moves: [
            _move(source, 1, AbacusHand.left, const [AbacusFinger.thumb]),
            _move(target, 0, AbacusHand.right, _fingersForClearing(digit)),
          ],
          pauseAfterMs: 900,
          returnAfter: index == _friendPairs.length - 1,
        ),
      );
    }
    _tagTopic('friends:$number', steps.sublist(start));
  }
  return steps;
}

final _recipeCache = <String, PhysicalGesturePlan>{};

/// Lesson data only: state changes and timing are compiled by the shared player.
PhysicalGesturePlan warmupRecipe(String type, [List<int>? selected]) {
  final topics = resolveWarmupTopics(type, selected);
  final fullBlock = topics.length == warmupTopicNumbers(type).length;
  final cacheKey = fullBlock ? type : '$type:${topics.join(",")}';
  return _recipeCache.putIfAbsent(cacheKey, () {
    final initialRods = emptyRods(warmupRodCount);
    return switch (type) {
      'simple-9' => PhysicalGesturePlan(
        initialRods: initialRods,
        steps: _simplePasses(AbacusHand.right, topics),
        beadTransitionMs: 400,
        openingAudioKey: warmupOpeningKey(type, topics),
      ),
      'simple-tens' => PhysicalGesturePlan(
        initialRods: initialRods,
        steps: _simplePasses(AbacusHand.left, topics),
        beadTransitionMs: 400,
        openingAudioKey: warmupOpeningKey(type, topics),
      ),
      'simple-2digit' => PhysicalGesturePlan(
        initialRods: initialRods,
        steps: _twoHandPasses(topics),
        openingAudioKey: warmupOpeningKey(type, topics),
      ),
      'brothers' => PhysicalGesturePlan(
        initialRods: initialRods,
        steps: _brothersPasses(topics, fullBlock),
        openingAudioKey: warmupOpeningKey(type, topics),
      ),
      'friends' => PhysicalGesturePlan(
        initialRods: initialRods,
        steps: _friendsPasses(topics),
        openingAudioKey: warmupOpeningKey(type, topics),
      ),
      _ => throw ArgumentError.value(type, 'type', 'Неизвестная разминка.'),
    };
  });
}

/// Mixed selections use the same family recipes and reset only between families.
PhysicalGesturePlan _warmupBasePlan(String type, [List<dynamic>? selected]) {
  if (selected == null || selected.every((value) => value is int)) {
    return warmupRecipe(type, selected?.cast<int>());
  }
  final ids = resolveWarmupSelection(type, selected);
  final families = warmupTypes
      .where((family) => ids.any((id) => id.startsWith('$family:')))
      .toList();
  List<int> numbers(String family) => ids
      .where((id) => id.startsWith('$family:'))
      .map((id) => int.parse(id.split(':')[1]))
      .toList();
  if (families.length == 1) {
    return warmupRecipe(families.single, numbers(families.single));
  }
  return _recipeCache.putIfAbsent('selection:${ids.join(",")}', () {
    final initial = emptyRods(warmupRodCount);
    var previous = initial;
    final steps = <PhysicalGestureStep>[];
    for (final family in families) {
      final changes = <BeadOnlyMove>[
        for (var index = 0; index < previous.length; index++)
          if (previous[index] != initial[index])
            BeadOnlyMove(rodIndex: index, to: initial[index]),
      ];
      if (changes.isNotEmpty) {
        steps.addAll(
          _tagTopic('$family:${numbers(family).first}', [
            SetupGestureStep(changes: changes, pauseAfterMs: 200),
          ]),
        );
      }
      final section = warmupRecipe(family, numbers(family));
      steps.addAll(section.steps);
      previous = compilePhysicalGesturePlan(section).last.rods;
    }
    return PhysicalGesturePlan(
      initialRods: initial,
      steps: steps,
      openingAudioKey: warmupInstructionKey,
      beadTransitionMs:
          families.every(
            (family) => family == 'simple-9' || family == 'simple-tens',
          )
          ? 400
          : null,
    );
  });
}

PhysicalGesturePlan warmupPlanForParams(
  String type, [
  List<dynamic>? selected,
  List<String>? narrated,
]) {
  final base = _warmupBasePlan(type, selected);
  if (narrated == null) return base;
  final ids = resolveWarmupSelection(type, selected);
  final voiced = resolveWarmupNarratedTopics(ids, narrated);
  if (voiced.length == ids.length) return base;
  return _recipeCache.putIfAbsent(
    'narration:${ids.join(",")}|${voiced.join(",")}',
    () {
      final playback = <int, PhysicalGestureStepPlayback>{};
      for (final (index, step) in base.steps.indexed) {
        final topic = _topicByStep[step];
        if (topic == null) {
          throw StateError('У шага разминки отсутствует тема.');
        }
        if (!voiced.contains(topic)) {
          playback[index] = const PhysicalGestureStepPlayback(
            narrationEnabled: false,
            tempoMultiplier: 2,
          );
        }
      }
      return PhysicalGesturePlan(
        initialRods: base.initialRods,
        steps: base.steps,
        beadTransitionMs: base.beadTransitionMs,
        openingAudioKey: base.openingAudioKey,
        audioSequences: base.audioSequences,
        stepPlayback: playback,
      );
    },
  );
}
