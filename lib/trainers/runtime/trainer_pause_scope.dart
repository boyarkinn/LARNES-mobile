import 'package:flutter/widgets.dart';

class TrainerPauseScope extends InheritedWidget {
  const TrainerPauseScope({
    super.key,
    required this.paused,
    required super.child,
  });
  final bool paused;
  static bool isPaused(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TrainerPauseScope>()?.paused ??
      false;
  @override
  bool updateShouldNotify(TrainerPauseScope oldWidget) =>
      paused != oldWidget.paused;
}
