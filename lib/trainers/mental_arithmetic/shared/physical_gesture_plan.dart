import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

enum AbacusHand { left, right }

enum AbacusFinger { thumb, indexFinger, middle, ring, little }

class PhysicalBeadMove {
  const PhysicalBeadMove({
    required this.rodIndex,
    required this.to,
    required this.hand,
    required this.fingers,
  });

  final int rodIndex;
  final RodState to;
  final AbacusHand hand;
  final List<AbacusFinger> fingers;
}

sealed class PhysicalGestureStep {
  const PhysicalGestureStep({this.pauseAfterMs = 200, this.audioKey});

  final int pauseAfterMs;
  final String? audioKey;
}

class GroupGestureStep extends PhysicalGestureStep {
  const GroupGestureStep({
    required this.moves,
    super.pauseAfterMs,
    super.audioKey,
  });

  final List<PhysicalBeadMove> moves;
}

class RodPassGestureStep extends PhysicalGestureStep {
  const RodPassGestureStep({
    required this.rodIndices,
    required this.to,
    required this.hand,
    required this.fingers,
    super.pauseAfterMs,
    super.audioKey,
  });

  final List<int> rodIndices;
  final RodState to;
  final AbacusHand hand;
  final List<AbacusFinger> fingers;
}

class PhysicalGesturePlan {
  const PhysicalGesturePlan({required this.initialRods, required this.steps});

  final List<RodState> initialRods;
  final List<PhysicalGestureStep> steps;
}

class PhysicalGestureFrame {
  const PhysicalGestureFrame({
    required this.rods,
    required this.moves,
    required this.pauseAfterMs,
    this.audioKey,
  });

  final List<RodState> rods;
  final List<PhysicalBeadMove> moves;
  final int pauseAfterMs;
  final String? audioKey;
}

bool _validRod(RodState rod) => rod.earthCount >= 0 && rod.earthCount <= 4;

void _validateMove(PhysicalBeadMove move, List<RodState> rods, Set<int> used) {
  if (move.rodIndex < 0 || move.rodIndex >= rods.length) {
    throw RangeError('Стержень жеста вне абакуса.');
  }
  if (used.contains(move.rodIndex)) {
    throw StateError('Один стержень не может двигаться дважды одновременно.');
  }
  if (!_validRod(move.to)) {
    throw RangeError('Недопустимое положение косточек.');
  }
  if (move.fingers.isEmpty) {
    throw StateError('Укажите пальцы для каждого движения.');
  }
  if (rods[move.rodIndex] == move.to) {
    throw StateError('Жест не меняет положение косточек.');
  }
  used.add(move.rodIndex);
}

/// Expands a rod pass into sequential frames; moves in one group share a frame.
List<PhysicalGestureFrame> compilePhysicalGesturePlan(
  PhysicalGesturePlan plan,
) {
  if (plan.initialRods.isEmpty ||
      plan.initialRods.any((rod) => !_validRod(rod))) {
    throw RangeError('Начальное положение абакуса недопустимо.');
  }
  var rods = List<RodState>.of(plan.initialRods);
  final frames = <PhysicalGestureFrame>[];

  void append(
    List<PhysicalBeadMove> moves,
    int pauseAfterMs,
    String? audioKey,
  ) {
    if (moves.isEmpty) throw StateError('Группа жестов не может быть пустой.');
    final used = <int>{};
    for (final move in moves) {
      _validateMove(move, rods, used);
    }
    final next = List<RodState>.of(rods);
    for (final move in moves) {
      next[move.rodIndex] = move.to;
    }
    rods = next;
    frames.add(
      PhysicalGestureFrame(
        rods: List.unmodifiable(next),
        moves: List.unmodifiable(
          moves.map(
            (move) => PhysicalBeadMove(
              rodIndex: move.rodIndex,
              to: move.to,
              hand: move.hand,
              fingers: List.unmodifiable(move.fingers),
            ),
          ),
        ),
        pauseAfterMs: pauseAfterMs,
        audioKey: audioKey,
      ),
    );
  }

  for (final step in plan.steps) {
    if (step.pauseAfterMs < 0) {
      throw RangeError('Пауза после жеста должна быть неотрицательной.');
    }
    final audioKey = step.audioKey;
    if (audioKey != null && audioKey.trim().isEmpty) {
      throw StateError('Ключ речевого сопровождения не может быть пустым.');
    }
    switch (step) {
      case GroupGestureStep():
        append(step.moves, step.pauseAfterMs, audioKey);
      case RodPassGestureStep():
        if (step.rodIndices.isEmpty) {
          throw StateError('Проход по стержням не может быть пустым.');
        }
        for (var index = 0; index < step.rodIndices.length; index++) {
          append(
            [
              PhysicalBeadMove(
                rodIndex: step.rodIndices[index],
                to: step.to,
                hand: step.hand,
                fingers: step.fingers,
              ),
            ],
            step.pauseAfterMs,
            index == 0 ? audioKey : null,
          );
        }
    }
  }

  return List.unmodifiable(frames);
}
