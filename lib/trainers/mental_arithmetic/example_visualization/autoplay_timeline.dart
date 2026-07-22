/// Web: `platform/src/trainers/mental-arithmetic/example-visualization/autoplay-timeline.ts`

const int beadAnimMs = 500;

enum AutoplayEventType { pause, anim, done }

class AutoplayTimelineEvent {
  const AutoplayTimelineEvent._({
    required this.type,
    this.actionIndex,
    this.rodStateIndex,
  });

  const AutoplayTimelineEvent.pause({required int actionIndex})
      : this._(type: AutoplayEventType.pause, actionIndex: actionIndex);

  const AutoplayTimelineEvent.anim({
    required int actionIndex,
    required int rodStateIndex,
  }) : this._(
          type: AutoplayEventType.anim,
          actionIndex: actionIndex,
          rodStateIndex: rodStateIndex,
        );

  const AutoplayTimelineEvent.done()
      : this._(type: AutoplayEventType.done);

  final AutoplayEventType type;
  final int? actionIndex;
  final int? rodStateIndex;
}

List<AutoplayTimelineEvent> buildAutoplayTimeline(int actionCount) {
  final events = <AutoplayTimelineEvent>[];

  for (var actionIndex = 0; actionIndex < actionCount; actionIndex++) {
    events.add(AutoplayTimelineEvent.pause(actionIndex: actionIndex));
    events.add(
      AutoplayTimelineEvent.anim(
        actionIndex: actionIndex,
        rodStateIndex: actionIndex + 1,
      ),
    );
  }

  events.add(const AutoplayTimelineEvent.done());
  return events;
}

int pauseMs(double stepPauseSec) {
  return (stepPauseSec * 1000).round();
}
