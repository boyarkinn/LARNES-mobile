import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

enum AbacusHand { left, right }

enum AbacusFinger { thumb, indexFinger, middle, ring, little }

enum PhysicalGestureAudioMode { before, parallel }

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

/// A bead change used to establish a starting value without a hand gesture.
class BeadOnlyMove {
  const BeadOnlyMove({required this.rodIndex, required this.to});

  final int rodIndex;
  final RodState to;
}

sealed class PhysicalGestureStep {
  const PhysicalGestureStep({
    this.pauseAfterMs = 200,
    this.audioKey,
    this.returnAfter = false,
  });

  final int pauseAfterMs;
  final String? audioKey;

  /// Return the active hand(s) to their resting positions after this step.
  final bool returnAfter;
}

/// Speech-only semantic step. It does not change the abacus.
class NarrationGestureStep extends PhysicalGestureStep {
  const NarrationGestureStep({required String audioKey, super.pauseAfterMs = 0})
    : super(audioKey: audioKey);
}

/// Establishes the abacus state while both hands remain at rest.
class SetupGestureStep extends PhysicalGestureStep {
  const SetupGestureStep({
    required this.changes,
    this.audioMode = PhysicalGestureAudioMode.before,
    super.audioKey,
    super.pauseAfterMs = 0,
  });

  final List<BeadOnlyMove> changes;
  final PhysicalGestureAudioMode audioMode;
}

class GroupGestureStep extends PhysicalGestureStep {
  const GroupGestureStep({
    required this.moves,
    this.audioMode = PhysicalGestureAudioMode.before,
    super.pauseAfterMs,
    super.audioKey,
    super.returnAfter,
  });

  final List<PhysicalBeadMove> moves;
  final PhysicalGestureAudioMode audioMode;
}

/// A sequence of bead frames spoken under one cue and committed as one step.
class SeriesGestureStep extends PhysicalGestureStep {
  const SeriesGestureStep({
    required this.frames,
    this.audioMode = PhysicalGestureAudioMode.before,
    super.pauseAfterMs,
    super.audioKey,
    super.returnAfter,
  });

  final List<List<PhysicalBeadMove>> frames;
  final PhysicalGestureAudioMode audioMode;
}

class RodPassGestureStep extends PhysicalGestureStep {
  const RodPassGestureStep({
    required this.rodIndices,
    required this.to,
    required this.hand,
    required this.fingers,
    this.audioMode = PhysicalGestureAudioMode.before,
    super.pauseAfterMs,
    this.pauseAfterPassMs,
    super.audioKey,
    super.returnAfter,
  });

  final List<int> rodIndices;
  final RodState to;
  final AbacusHand hand;
  final List<AbacusFinger> fingers;
  final PhysicalGestureAudioMode audioMode;
  final int? pauseAfterPassMs;
}

class PhysicalGesturePlan {
  const PhysicalGesturePlan({
    required this.initialRods,
    required this.steps,
    this.beadTransitionMs,
    this.openingAudioKey,
  });

  final List<RodState> initialRods;
  final List<PhysicalGestureStep> steps;
  final int? beadTransitionMs;
  final String? openingAudioKey;
}

class PhysicalGestureFrame {
  const PhysicalGestureFrame({
    required this.rods,
    required this.moves,
    required this.pauseAfterMs,
    this.audioKey,
    this.returnAfter = false,
  });

  final List<RodState> rods;
  final List<PhysicalBeadMove> moves;
  final int pauseAfterMs;
  final String? audioKey;
  final bool returnAfter;
}

/// Catalog keys in first-use order; playback itself still follows the steps.
List<String> physicalGestureAudioKeys(PhysicalGesturePlan plan) {
  final keys = <String>[];
  final seen = <String>{};
  void add(String? key) {
    if (key != null && key.trim().isNotEmpty && seen.add(key)) keys.add(key);
  }

  add(plan.openingAudioKey);
  for (final step in plan.steps) {
    add(step.audioKey);
  }
  return List.unmodifiable(keys);
}

bool _validRod(RodState rod) => rod.earthCount >= 0 && rod.earthCount <= 4;

void _validateTarget(
  int rodIndex,
  RodState to,
  List<RodState> rods,
  Set<int> used,
) {
  if (rodIndex < 0 || rodIndex >= rods.length) {
    throw RangeError('Стержень жеста вне абакуса.');
  }
  if (used.contains(rodIndex)) {
    throw StateError('Один стержень не может двигаться дважды одновременно.');
  }
  if (!_validRod(to)) {
    throw RangeError('Недопустимое положение косточек.');
  }
  if (rods[rodIndex] == to) {
    throw StateError('Жест не меняет положение косточек.');
  }
  used.add(rodIndex);
}

void _validateMove(PhysicalBeadMove move, List<RodState> rods, Set<int> used) {
  _validateTarget(move.rodIndex, move.to, rods, used);
  if (move.fingers.isEmpty) {
    throw StateError('Укажите пальцы для каждого движения.');
  }
}

/// Expands a rod pass into sequential frames; moves in one group share a frame.
List<PhysicalGestureFrame> compilePhysicalGesturePlan(
  PhysicalGesturePlan plan,
) {
  if (plan.beadTransitionMs != null && plan.beadTransitionMs! <= 0) {
    throw RangeError(
      'Длительность движения косточки должна быть положительной.',
    );
  }
  if (plan.openingAudioKey != null && plan.openingAudioKey!.trim().isEmpty) {
    throw StateError('Ключ вступительной фразы не может быть пустым.');
  }
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
    bool returnAfter,
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
        returnAfter: returnAfter,
      ),
    );
  }

  void appendSetup(
    List<BeadOnlyMove> changes,
    int pauseAfterMs,
    String? audioKey,
  ) {
    if (changes.isEmpty) {
      throw StateError('Подготовка абакуса не может быть пустой.');
    }
    final used = <int>{};
    for (final change in changes) {
      _validateTarget(change.rodIndex, change.to, rods, used);
    }
    final next = List<RodState>.of(rods);
    for (final change in changes) {
      next[change.rodIndex] = change.to;
    }
    rods = next;
    frames.add(
      PhysicalGestureFrame(
        rods: List.unmodifiable(next),
        moves: const [],
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
      case NarrationGestureStep():
        if (audioKey == null) {
          throw StateError('Для речевого шага нужен ключ аудио.');
        }
      case SetupGestureStep():
        if (step.audioMode == PhysicalGestureAudioMode.parallel &&
            audioKey == null) {
          throw StateError('Для параллельной речи нужен ключ аудио.');
        }
        appendSetup(step.changes, step.pauseAfterMs, audioKey);
      case GroupGestureStep():
        if (step.audioMode == PhysicalGestureAudioMode.parallel &&
            audioKey == null) {
          throw StateError('Для параллельной речи нужен ключ аудио.');
        }
        append(step.moves, step.pauseAfterMs, audioKey, step.returnAfter);
      case SeriesGestureStep():
        if (step.audioMode == PhysicalGestureAudioMode.parallel &&
            audioKey == null) {
          throw StateError('Для параллельной речи нужен ключ аудио.');
        }
        if (step.frames.isEmpty) {
          throw StateError('Серия жестов не может быть пустой.');
        }
        for (var index = 0; index < step.frames.length; index++) {
          append(
            step.frames[index],
            step.pauseAfterMs,
            index == 0 ? audioKey : null,
            index == step.frames.length - 1 && step.returnAfter,
          );
        }
      case RodPassGestureStep():
        if (step.audioMode == PhysicalGestureAudioMode.parallel &&
            audioKey == null) {
          throw StateError('Для параллельной речи нужен ключ аудио.');
        }
        if (step.rodIndices.isEmpty) {
          throw StateError('Проход по стержням не может быть пустым.');
        }
        final endPause = step.pauseAfterPassMs ?? step.pauseAfterMs;
        if (endPause < 0) {
          throw RangeError('Пауза после прохода должна быть неотрицательной.');
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
            index == step.rodIndices.length - 1 ? endPause : step.pauseAfterMs,
            index == 0 ? audioKey : null,
            index == step.rodIndices.length - 1 && step.returnAfter,
          );
        }
    }
  }

  return List.unmodifiable(frames);
}
