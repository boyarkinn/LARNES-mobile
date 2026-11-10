import 'package:larnes_mobile/trainers/mental_arithmetic/shared/example_parser.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

/// A physical movement with the complete abacus state after the gesture.
class AbacusGestureFrame {
  const AbacusGestureFrame({
    required this.actionIndex,
    required this.rodIndices,
    required this.rods,
    required this.value,
  });

  final int actionIndex;
  final List<int> rodIndices;
  final List<RodState> rods;
  final int value;
}

class AbacusPlaybackPlan {
  const AbacusPlaybackPlan({required this.actions, required this.gestures});

  final List<ExampleAction> actions;
  final List<AbacusGestureFrame> gestures;
}

enum AbacusPlaybackEventType { actionStart, gesture, actionComplete, complete }

class AbacusPlaybackEvent {
  const AbacusPlaybackEvent._({
    required this.type,
    this.actionIndex,
    this.action,
    this.gestureIndex,
    this.gesture,
    required this.value,
  });

  const AbacusPlaybackEvent.actionStart({
    required int actionIndex,
    required ExampleAction action,
    required int value,
  }) : this._(
         type: AbacusPlaybackEventType.actionStart,
         actionIndex: actionIndex,
         action: action,
         value: value,
       );

  AbacusPlaybackEvent.gesture({
    required int actionIndex,
    required int gestureIndex,
    required AbacusGestureFrame gesture,
  }) : this._(
         type: AbacusPlaybackEventType.gesture,
         actionIndex: actionIndex,
         gestureIndex: gestureIndex,
         gesture: gesture,
         value: gesture.value,
       );

  const AbacusPlaybackEvent.actionComplete({
    required int actionIndex,
    required int value,
  }) : this._(
         type: AbacusPlaybackEventType.actionComplete,
         actionIndex: actionIndex,
         value: value,
       );

  const AbacusPlaybackEvent.complete({required int value})
    : this._(type: AbacusPlaybackEventType.complete, value: value);

  final AbacusPlaybackEventType type;
  final int? actionIndex;
  final ExampleAction? action;
  final int? gestureIndex;
  final AbacusGestureFrame? gesture;
  final int value;
}

List<AbacusPlaybackEvent> buildAbacusPlaybackPlan(AbacusPlaybackPlan plan) {
  final events = <AbacusPlaybackEvent>[];
  var gestureIndex = 0;
  var value = 0;

  for (var actionIndex = 0; actionIndex < plan.actions.length; actionIndex++) {
    final action = plan.actions[actionIndex];
    events.add(
      AbacusPlaybackEvent.actionStart(
        actionIndex: actionIndex,
        action: action,
        value: value,
      ),
    );
    final firstGesture = gestureIndex;

    while (gestureIndex < plan.gestures.length &&
        plan.gestures[gestureIndex].actionIndex == actionIndex) {
      final gesture = plan.gestures[gestureIndex];
      events.add(
        AbacusPlaybackEvent.gesture(
          actionIndex: actionIndex,
          gestureIndex: gestureIndex,
          gesture: gesture,
        ),
      );
      gestureIndex++;
    }

    value += action.sign == '+' ? action.digit : -action.digit;
    if (gestureIndex == firstGesture ||
        plan.gestures[gestureIndex - 1].value != value) {
      throw StateError(
        'Неполный план движений для действия ${actionIndex + 1}.',
      );
    }
    events.add(
      AbacusPlaybackEvent.actionComplete(
        actionIndex: actionIndex,
        value: value,
      ),
    );
  }

  if (gestureIndex != plan.gestures.length) {
    throw StateError(
      'План движений содержит жест без арифметического действия.',
    );
  }

  events.add(AbacusPlaybackEvent.complete(value: value));
  return events;
}
