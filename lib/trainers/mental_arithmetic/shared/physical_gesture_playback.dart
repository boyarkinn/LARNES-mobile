import 'dart:async';

import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
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

  int pauseMs(int baseMs) => (baseMs / rate).round();
}

PhysicalGestureTiming physicalGestureTiming(
  PhysicalGestureSpeed speed, {
  bool reducedMotion = false,
  int baseTransitionMs = 500,
}) {
  if (baseTransitionMs <= 0) {
    throw RangeError('Неверная длительность движения косточки.');
  }
  final rate = switch (speed) {
    PhysicalGestureSpeed.slow => 0.75,
    PhysicalGestureSpeed.medium => 1.0,
    PhysicalGestureSpeed.fast => 1.5,
  };
  return PhysicalGestureTiming(
    transitionMs: reducedMotion ? 0 : (baseTransitionMs / rate).round(),
    frameMs: (baseTransitionMs / rate).round(),
    rate: rate,
  );
}

/// A cancelled cue stops its audio before another movement can begin.
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

class _CueEvent extends _PlaybackEvent {
  const _CueEvent(this.key);
  final String key;
}

class _FrameEvent extends _PlaybackEvent {
  const _FrameEvent(this.frame, this.frameIndex);
  final PhysicalGestureFrame frame;
  final int frameIndex;
}

class _CompleteEvent extends _PlaybackEvent {
  const _CompleteEvent();
}

/// Shared, cancellable sequence for speech followed by physical bead motion.
class PhysicalGesturePlayer {
  PhysicalGesturePlayer({
    required PhysicalGesturePlan plan,
    required PhysicalGestureSpeed speed,
    required void Function(PhysicalGestureFrame frame, int index) onFrame,
    Future<void> Function(String key, GestureCueSignal signal)? onCue,
    void Function()? onComplete,
    bool reducedMotion = false,
    int Function()? nowMs,
    TrainerTimerFactory? timerFactory,
  }) : frames = compilePhysicalGesturePlan(plan) {
    final timing = physicalGestureTiming(
      speed,
      reducedMotion: reducedMotion,
      baseTransitionMs: plan.beadTransitionMs ?? 500,
    );
    final events = <_PlaybackEvent>[];
    final frameStarts = <int>[];
    if (onCue != null && plan.openingAudioKey != null) {
      events.add(_CueEvent(plan.openingAudioKey!));
    }
    for (var frameIndex = 0; frameIndex < frames.length; frameIndex++) {
      frameStarts.add(frameIndex == 0 ? 0 : events.length);
      final frame = frames[frameIndex];
      if (onCue != null && frame.audioKey != null) {
        events.add(_CueEvent(frame.audioKey!));
      }
      events.add(_FrameEvent(frame, frameIndex));
    }
    frameStarts.add(events.length);
    _frameStarts = frameStarts;
    if (events.isNotEmpty) events.add(const _CompleteEvent());
    _controller = TrainerPlaybackController<_PlaybackEvent>(
      events: events,
      delayBeforeMs: (_, index) {
        if (index == 0) return 0;
        final previous = events[index - 1];
        if (previous is _CueEvent) return 0;
        if (previous is! _FrameEvent) {
          throw StateError('Нарушен порядок жестов.');
        }
        return timing.frameMs +
            (events[index] is _CompleteEvent
                ? 0
                : timing.pauseMs(previous.frame.pauseAfterMs));
      },
      onEvent: (event, _) {
        switch (event) {
          case _FrameEvent():
            _framePosition = event.frameIndex + 1;
            onFrame(event.frame, event.frameIndex);
          case _CueEvent():
            _controller.pause();
            final signal = GestureCueSignal();
            final generation = ++_cueGeneration;
            _cueSignal = signal;
            unawaited(
              Future.sync(
                () => onCue?.call(event.key, signal),
              ).then((_) {}, onError: (Object _) {}).whenComplete(() {
                if (generation != _cueGeneration ||
                    !identical(_cueSignal, signal)) {
                  return;
                }
                _cueSignal = null;
                if (_wantsPlay) _controller.play();
              }),
            );
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
  late final List<int> _frameStarts;
  late final TrainerPlaybackController<_PlaybackEvent> _controller;
  int _framePosition = 0;
  GestureCueSignal? _cueSignal;
  int _cueGeneration = 0;
  bool _wantsPlay = false;

  TrainerPlaybackStatus get status => _cueSignal != null && _wantsPlay
      ? TrainerPlaybackStatus.playing
      : _controller.status;
  int get position => _framePosition;

  void play() {
    _wantsPlay = true;
    if (_cueSignal == null) _controller.play();
  }

  void pause() {
    _wantsPlay = false;
    if (_cueSignal != null) {
      _stopCue();
      _controller.seek(_frameStarts[_framePosition]);
    } else {
      _controller.pause();
    }
  }

  void cancel() {
    _wantsPlay = false;
    _stopCue();
    _controller.cancel();
  }

  void seek(int position) {
    if (position < 0 || position > frames.length) {
      throw RangeError.range(position, 0, frames.length, 'position');
    }
    _wantsPlay = false;
    _stopCue();
    _framePosition = position;
    _controller.seek(_frameStarts[position]);
  }

  void _stopCue() {
    _cueGeneration++;
    _cueSignal?.cancel();
    _cueSignal = null;
  }
}
