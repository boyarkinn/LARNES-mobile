import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_playback_plan.dart';

const abacusBeadAnimationMs = 500;
const digitalAbacusMinGestureMs = 700;

enum AbacusPlaybackMode { digital, visualization }

int abacusPlaybackDelayBefore(
  List<AbacusPlaybackEvent> events,
  int index,
  AbacusPlaybackMode mode,
  double stepPauseSec,
) {
  if (!stepPauseSec.isFinite || stepPauseSec < 0) {
    throw ArgumentError.value(stepPauseSec, 'stepPauseSec');
  }
  if (index < 0 || index >= events.length) {
    throw RangeError.index(index, events);
  }

  final event = events[index];
  final pause = (stepPauseSec * 1000).round();
  if (event.type == AbacusPlaybackEventType.gesture) {
    if (mode == AbacusPlaybackMode.digital) {
      return pause < digitalAbacusMinGestureMs
          ? digitalAbacusMinGestureMs
          : pause;
    }
    final previous = index > 0 ? events[index - 1] : null;
    return previous?.type == AbacusPlaybackEventType.actionStart
        ? pause
        : abacusBeadAnimationMs;
  }

  if (event.type == AbacusPlaybackEventType.actionComplete &&
      mode == AbacusPlaybackMode.visualization) {
    return abacusBeadAnimationMs;
  }

  return 0;
}
