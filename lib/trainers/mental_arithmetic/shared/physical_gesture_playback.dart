import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/shared/trainer_playback_controller.dart';

enum PhysicalGestureSpeed { slow, medium, fast }

class PhysicalGestureTiming {
  const PhysicalGestureTiming({required this.transitionMs, required this.rate});

  final int transitionMs;
  final double rate;

  int pauseMs(int baseMs) => (baseMs / rate).round();
}

/// Medium uses the plan's base transition; omitted plans keep the old 500 ms.
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
    rate: rate,
  );
}

/// Runs a physical gesture plan through the same cancellable trainer clock.
class PhysicalGesturePlayer {
  PhysicalGesturePlayer({
    required PhysicalGesturePlan plan,
    required PhysicalGestureSpeed speed,
    required void Function(PhysicalGestureFrame frame, int index) onFrame,
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
    final events = <PhysicalGestureFrame?>[...frames];
    if (events.isNotEmpty) {
      events.add(null); // Completion follows the final bead animation.
    }
    _controller = TrainerPlaybackController<PhysicalGestureFrame?>(
      events: events,
      delayBeforeMs: (_, index) {
        if (index == 0) return 0;
        final previous = events[index - 1];
        if (previous == null) throw StateError('Нарушен порядок жестов.');
        return timing.transitionMs +
            (events[index] == null ? 0 : timing.pauseMs(previous.pauseAfterMs));
      },
      onEvent: (frame, index) {
        if (frame != null) onFrame(frame, index);
      },
      onComplete: onComplete,
      nowMs: nowMs,
      timerFactory: timerFactory,
    );
  }

  final List<PhysicalGestureFrame> frames;
  late final TrainerPlaybackController<PhysicalGestureFrame?> _controller;

  TrainerPlaybackStatus get status => _controller.status;
  int get position => _controller.nextIndex < frames.length
      ? _controller.nextIndex
      : frames.length;

  void play() => _controller.play();
  void pause() => _controller.pause();
  void cancel() => _controller.cancel();
  void seek(int position) {
    if (position < 0 || position > frames.length) {
      throw RangeError.range(position, 0, frames.length, 'position');
    }
    _controller.seek(position);
  }
}
