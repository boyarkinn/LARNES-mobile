import 'dart:async';

import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/trainer_playback_controller.dart';

enum PhysicalGestureSpeed { slow, medium, fast }

class PhysicalGestureTiming {
  const PhysicalGestureTiming({
    required this.transitionMs,
    required this.frameMs,
    required this.rate,
  });

  final int transitionMs;
  final int frameMs;
  final double rate;

  /// Existing gaps between physical movements follow the movement tempo.
  int pauseMs(int baseMs) => (baseMs / rate).round();

  /// A speech-only pause remains independent of movement speed.
  int narrationPauseMs(int baseMs) => baseMs;

  int movementMs(int baseMs) => (baseMs / rate).round();
}

PhysicalGestureTiming physicalGestureTiming(
  PhysicalGestureSpeed speed, {
  bool reducedMotion = false,
  int baseTransitionMs = 500,
  double tempoMultiplier = 1,
}) {
  if (baseTransitionMs <= 0) {
    throw RangeError('Неверная длительность движения косточки.');
  }
  if (!tempoMultiplier.isFinite || tempoMultiplier <= 0) {
    throw RangeError('Неверный темп жестов.');
  }
  final speedRate = switch (speed) {
    PhysicalGestureSpeed.slow => 0.75,
    PhysicalGestureSpeed.medium => 1.0,
    PhysicalGestureSpeed.fast => 1.5,
  };
  final rate = speedRate * tempoMultiplier;
  return PhysicalGestureTiming(
    transitionMs: reducedMotion ? 0 : (baseTransitionMs / rate).round(),
    frameMs: (baseTransitionMs / rate).round(),
    rate: rate,
  );
}

/// A cancelled cue stops its audio before another semantic step can begin.
class GestureCueSignal {
  bool _cancelled = false;
  final List<void Function()> _listeners = [];

  bool get cancelled => _cancelled;

  void onCancel(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final listener in _listeners) {
      listener();
    }
    _listeners.clear();
  }
}

sealed class _PlaybackEvent {
  const _PlaybackEvent();
}

class _StepStartEvent extends _PlaybackEvent {
  const _StepStartEvent(this.stepIndex);
  final int stepIndex;
}

class _CueEvent extends _PlaybackEvent {
  const _CueEvent(this.key, this.stepIndex);
  final String key;
  final int stepIndex; // -1 means opening speech.
}

class _ParallelCueEvent extends _PlaybackEvent {
  const _ParallelCueEvent(this.key, this.stepIndex);
  final String key;
  final int stepIndex;
}

class _FrameEvent extends _PlaybackEvent {
  const _FrameEvent(this.frame, this.frameIndex);
  final PhysicalGestureFrame frame;
  final int frameIndex;
}

class _PrepareEvent extends _PlaybackEvent {
  const _PrepareEvent(this.frame, this.frameIndex, this.parallelStepIndex);
  final PhysicalGestureFrame frame;
  final int frameIndex;
  final int? parallelStepIndex;
}

class _ReturnEvent extends _PlaybackEvent {
  const _ReturnEvent(this.frame, this.frameIndex);
  final PhysicalGestureFrame frame;
  final int frameIndex;
}

class _StepBoundaryEvent extends _PlaybackEvent {
  const _StepBoundaryEvent({
    required this.stepIndex,
    required this.frameEnd,
    required this.pauseAfterMs,
    required this.hasNextStep,
    required this.parallel,
    required this.narration,
  });

  final int stepIndex;
  final int frameEnd;
  final int pauseAfterMs;
  final bool hasNextStep;
  final bool parallel;
  final bool narration;
}

class _CompleteEvent extends _PlaybackEvent {
  const _CompleteEvent();
}

/// Shared, cancellable sequence with a barrier at each semantic step.
class PhysicalGesturePlayer {
  PhysicalGesturePlayer({
    required PhysicalGesturePlan plan,
    required PhysicalGestureSpeed speed,
    double tempoMultiplier = 1,
    required void Function(PhysicalGestureFrame frame, int index) onFrame,
    void Function(PhysicalGestureFrame frame, int index)? onPrepare,
    void Function(PhysicalGestureFrame frame, int index)? onReturn,
    this.onReset,
    int prepareMs = 120,
    int returnMs = 320,
    Future<void> Function(String key, GestureCueSignal signal)? onCue,
    void Function()? onComplete,
    bool reducedMotion = false,
    int Function()? nowMs,
    TrainerTimerFactory? timerFactory,
  }) : frames = compilePhysicalGesturePlan(plan),
       _nowMsOverride = nowMs,
       _initialRods = List.unmodifiable(plan.initialRods) {
    final timing = physicalGestureTiming(
      speed,
      reducedMotion: reducedMotion,
      baseTransitionMs: plan.beadTransitionMs ?? 500,
      tempoMultiplier: tempoMultiplier,
    );
    PhysicalGestureTiming timingForFrame(PhysicalGestureFrame frame) =>
        physicalGestureTiming(
          speed,
          reducedMotion: reducedMotion,
          baseTransitionMs: plan.beadTransitionMs ?? 500,
          tempoMultiplier: tempoMultiplier * frame.tempoMultiplier,
        );
    final events = <_PlaybackEvent>[];
    final stepStarts = <int>[];
    final stepFrameStarts = <int>[];
    final hasOpening = onCue != null && plan.openingAudioKey != null;
    _settledStepIndex = hasOpening ? -1 : 0;
    if (hasOpening) events.add(_CueEvent(plan.openingAudioKey!, -1));

    var frameIndex = 0;
    for (var stepIndex = 0; stepIndex < plan.steps.length; stepIndex++) {
      final step = plan.steps[stepIndex];
      final allowCue = plan.stepPlayback[stepIndex]?.narrationEnabled != false;
      stepStarts.add(events.length);
      stepFrameStarts.add(frameIndex);
      if ((plan.stepPlayback[stepIndex]?.minimumDurationMs ?? 0) > 0) {
        events.add(_StepStartEvent(stepIndex));
      }
      final parallel =
          allowCue &&
          (switch (step) {
            SetupGestureStep(:final audioMode) ||
            GroupGestureStep(:final audioMode) ||
            SeriesGestureStep(:final audioMode) ||
            RodPassGestureStep(
              :final audioMode,
            ) => audioMode == PhysicalGestureAudioMode.parallel,
            NarrationGestureStep() => false,
          });
      if (!parallel && allowCue && onCue != null && step.audioKey != null) {
        events.add(_CueEvent(step.audioKey!, stepIndex));
      }

      final frameCount = switch (step) {
        NarrationGestureStep() => 0,
        SetupGestureStep() => 1,
        GroupGestureStep() => 1,
        SeriesGestureStep(:final frames) => frames.length,
        RodPassGestureStep(:final rodIndices) => rodIndices.length,
      };
      for (var i = 0; i < frameCount; i++) {
        final frame = frames[frameIndex];
        if (onPrepare != null && !reducedMotion && frame.moves.isNotEmpty) {
          events.add(
            _PrepareEvent(
              frame,
              frameIndex,
              parallel && i == 0 ? stepIndex : null,
            ),
          );
        }
        if (parallel && i == 0) {
          events.add(_ParallelCueEvent(step.audioKey!, stepIndex));
        }
        events.add(_FrameEvent(frame, frameIndex));
        if (onReturn != null &&
            !reducedMotion &&
            frame.moves.isNotEmpty &&
            frame.returnAfter) {
          events.add(_ReturnEvent(frame, frameIndex));
        }
        frameIndex++;
      }
      events.add(
        _StepBoundaryEvent(
          stepIndex: stepIndex,
          frameEnd: frameIndex,
          pauseAfterMs: frameCount == 0
              ? step.pauseAfterMs
              : frames[frameIndex - 1].pauseAfterMs,
          hasNextStep: stepIndex + 1 < plan.steps.length,
          parallel: parallel,
          narration: frameCount == 0,
        ),
      );
    }
    stepStarts.add(events.length);
    stepFrameStarts.add(frameIndex);
    _stepStarts = List.unmodifiable(stepStarts);
    _stepFrameStarts = List.unmodifiable(stepFrameStarts);
    if (events.isNotEmpty) events.add(const _CompleteEvent());
    _hasEvents = events.isNotEmpty;

    _controller = TrainerPlaybackController<_PlaybackEvent>(
      events: events,
      delayBeforeMs: (event, index) {
        final previous = index == 0 ? null : events[index - 1];
        final frameTiming = switch (previous) {
          _PrepareEvent(:final frame) ||
          _ReturnEvent(:final frame) ||
          _FrameEvent(:final frame) => timingForFrame(frame),
          _ => timing,
        };
        if (event is _StepBoundaryEvent) {
          int padded(int naturalMs) {
            final minimum =
                plan.stepPlayback[event.stepIndex]?.minimumDurationMs ?? 0;
            final elapsed =
                _timedStepIndex == event.stepIndex && _stepStartedAt != null
                ? _nowMilliseconds() - _stepStartedAt!
                : 0;
            final remaining = minimum - elapsed;
            return remaining > naturalMs ? remaining : naturalMs;
          }

          if (event.narration) {
            return padded(frameTiming.narrationPauseMs(event.pauseAfterMs));
          }
          if (previous is _ReturnEvent) {
            return padded(
              frameTiming.movementMs(returnMs) >
                      frameTiming.pauseMs(event.pauseAfterMs)
                  ? frameTiming.movementMs(returnMs)
                  : frameTiming.pauseMs(event.pauseAfterMs),
            );
          }
          if (previous is _FrameEvent) {
            return padded(
              frameTiming.frameMs +
                  (event.hasNextStep
                      ? frameTiming.pauseMs(event.pauseAfterMs)
                      : 0),
            );
          }
          throw StateError('Нарушена граница жеста.');
        }
        if (index == 0 ||
            previous is _CueEvent ||
            previous is _ParallelCueEvent ||
            previous is _StepStartEvent ||
            previous is _StepBoundaryEvent) {
          return 0;
        }
        if (previous is _PrepareEvent) {
          return frameTiming.movementMs(prepareMs);
        }
        if (previous is _FrameEvent) {
          if (event is _ReturnEvent) return frameTiming.frameMs;
          return frameTiming.frameMs +
              frameTiming.pauseMs(previous.frame.pauseAfterMs);
        }
        throw StateError('Нарушен порядок жестов.');
      },
      onEvent: (event, _) {
        switch (event) {
          case _StepStartEvent():
            _timedStepIndex = event.stepIndex;
            _stepStartedAt = _nowMilliseconds();
            _stepPausedAt = null;
          case _CueEvent():
            _controller.pause();
            _blockingCueStepIndex = event.stepIndex;
            _startCue(event.key, onCue, blocking: true);
          case _ParallelCueEvent():
            _activeParallelStepIndex = event.stepIndex;
            _startCue(event.key, onCue, blocking: false);
          case _PrepareEvent():
            if (event.parallelStepIndex != null) {
              _activeParallelStepIndex = event.parallelStepIndex;
            }
            onPrepare?.call(event.frame, event.frameIndex);
          case _FrameEvent():
            _framePosition = event.frameIndex + 1;
            onFrame(event.frame, event.frameIndex);
          case _ReturnEvent():
            onReturn?.call(event.frame, event.frameIndex);
          case _StepBoundaryEvent():
            if (event.parallel && _cueSignal != null) {
              _controller.pause();
              _waitingBoundary = event;
            } else {
              _settleBoundary(event);
            }
          case _CompleteEvent():
            break;
        }
      },
      onComplete: onComplete,
      nowMs: nowMs,
      timerFactory: timerFactory,
    );
  }

  final List<PhysicalGestureFrame> frames;
  final List<RodState> _initialRods;
  final Stopwatch _activeClock = Stopwatch()..start();
  final int Function()? _nowMsOverride;
  int? _timedStepIndex;
  int? _stepStartedAt;
  int? _stepPausedAt;
  final void Function(List<RodState> rods, int framePosition)? onReset;
  late final List<int> _stepStarts;
  late final List<int> _stepFrameStarts;
  late final bool _hasEvents;
  late final TrainerPlaybackController<_PlaybackEvent> _controller;
  int _framePosition = 0;
  int _settledFramePosition = 0;
  int _settledStepIndex = 0;
  int? _activeParallelStepIndex;
  int? _blockingCueStepIndex;
  _StepBoundaryEvent? _waitingBoundary;
  GestureCueSignal? _cueSignal;
  int _cueGeneration = 0;
  bool _wantsPlay = false;

  int _nowMilliseconds() =>
      _nowMsOverride?.call() ?? _activeClock.elapsedMilliseconds;

  void _resetStepTiming() {
    _timedStepIndex = null;
    _stepStartedAt = null;
    _stepPausedAt = null;
  }

  bool get hasEvents => _hasEvents;
  int get position => _framePosition;
  int get checkpointStepIndex => _settledStepIndex;
  int get checkpointFramePosition => _settledFramePosition;
  List<RodState> get checkpointRods => _rodsAt(_settledFramePosition);

  TrainerPlaybackStatus get status => _cueSignal != null && _wantsPlay
      ? TrainerPlaybackStatus.playing
      : _controller.status;

  void _startCue(
    String key,
    Future<void> Function(String key, GestureCueSignal signal)? onCue, {
    required bool blocking,
  }) {
    if (onCue == null) return;
    final signal = GestureCueSignal();
    final generation = ++_cueGeneration;
    _cueSignal = signal;
    unawaited(
      Future.sync(
        () => onCue(key, signal),
      ).then((_) {}, onError: (Object _) {}).whenComplete(() {
        if (generation != _cueGeneration || !identical(_cueSignal, signal)) {
          return;
        }
        _cueSignal = null;
        if (blocking) {
          if (_blockingCueStepIndex == -1) _settledStepIndex = 0;
          _blockingCueStepIndex = null;
          if (_wantsPlay) _controller.play();
        } else {
          final boundary = _waitingBoundary;
          if (boundary != null) {
            _settleBoundary(boundary);
            if (_wantsPlay) _controller.play();
          }
        }
      }),
    );
  }

  void _settleBoundary(_StepBoundaryEvent event) {
    _resetStepTiming();
    _settledStepIndex = event.stepIndex + 1;
    _settledFramePosition = event.frameEnd;
    _activeParallelStepIndex = null;
    _waitingBoundary = null;
  }

  List<RodState> _rodsAt(int framePosition) =>
      framePosition == 0 ? _initialRods : frames[framePosition - 1].rods;

  void play() {
    if (_stepPausedAt != null && _stepStartedAt != null) {
      _stepStartedAt = _stepStartedAt! + (_nowMilliseconds() - _stepPausedAt!);
      _stepPausedAt = null;
    }
    _wantsPlay = true;
    if (_cueSignal == null) _controller.play();
  }

  void pause() {
    _wantsPlay = false;
    final activeParallel = _activeParallelStepIndex;
    if (activeParallel != null) {
      _rewindToStep(activeParallel, notify: true);
    } else if (_cueSignal != null) {
      _rewindToStep(_blockingCueStepIndex ?? _settledStepIndex, notify: true);
    } else {
      _controller.pause();
      if (_stepStartedAt != null) _stepPausedAt ??= _nowMilliseconds();
    }
  }

  void cancel() {
    _resetStepTiming();
    _wantsPlay = false;
    _stopCue();
    _controller.cancel();
  }

  /// Restore a confirmed semantic boundary, including a speech-only boundary.
  void seekToStep(int stepIndex) {
    if (stepIndex < -1 || stepIndex > _stepStarts.length - 1) {
      throw RangeError.range(stepIndex, -1, _stepStarts.length - 1);
    }
    _wantsPlay = false;
    _rewindToStep(stepIndex, notify: false);
  }

  /// Legacy frame seek. Mid-step seeks replay that semantic step.
  void seek(int position) {
    if (position < 0 || position > frames.length) {
      throw RangeError.range(position, 0, frames.length, 'position');
    }
    if (position == 0) {
      seekToStep(_settledStepIndex == -1 ? -1 : 0);
      return;
    }
    for (
      var stepIndex = 0;
      stepIndex < _stepFrameStarts.length - 1;
      stepIndex++
    ) {
      if (position <= _stepFrameStarts[stepIndex + 1] &&
          _stepFrameStarts[stepIndex + 1] > _stepFrameStarts[stepIndex]) {
        seekToStep(stepIndex);
        return;
      }
    }
    seekToStep(_stepStarts.length - 1);
  }

  void _rewindToStep(int stepIndex, {required bool notify}) {
    _resetStepTiming();
    _stopCue();
    _activeParallelStepIndex = null;
    _blockingCueStepIndex = null;
    _waitingBoundary = null;
    final framePosition = stepIndex < 0 ? 0 : _stepFrameStarts[stepIndex];
    _framePosition = framePosition;
    _settledFramePosition = framePosition;
    _settledStepIndex = stepIndex;
    _controller.seek(stepIndex < 0 ? 0 : _stepStarts[stepIndex]);
    if (notify) onReset?.call(_rodsAt(framePosition), framePosition);
  }

  void _stopCue() {
    _cueGeneration++;
    _cueSignal?.cancel();
    _cueSignal = null;
  }
}
