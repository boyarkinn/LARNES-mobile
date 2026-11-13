import 'package:flutter/material.dart';

class TrainerTimeProgressController extends ChangeNotifier {
  Object? _owner;
  double? value;
  bool _disposed = false;
  void publish(Object owner, double? next) {
    if (_disposed) return;
    _owner = owner;
    if (value == next) return;
    value = next;
    notifyListeners();
  }

  void clear(Object owner) {
    if (identical(owner, _owner)) publish(owner, null);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class TrainerTimeProgressScope extends InheritedWidget {
  const TrainerTimeProgressScope({
    super.key,
    required this.controller,
    required super.child,
  });
  final TrainerTimeProgressController controller;
  static TrainerTimeProgressController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<TrainerTimeProgressScope>()
      ?.controller;
  @override
  bool updateShouldNotify(TrainerTimeProgressScope oldWidget) =>
      controller != oldWidget.controller;
}

class TrainerTimeProgressBar extends StatelessWidget {
  const TrainerTimeProgressBar({super.key, required this.value});
  final double value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Semantics(
      label: 'Время раунда',
      value: '${(value.clamp(0, 1) * 100).round()}%',
      child: SizedBox(
        height: 7,
        width: double.infinity,
        child: ColoredBox(
          color: const Color(0x26EAB308),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedFractionallySizedBox(
              widthFactor: value.clamp(0, 1),
              duration: const Duration(milliseconds: 100),
              curve: Curves.linear,
              child: const ColoredBox(color: Color(0xFFEAB308)),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Publishes into the shell HUD; a standalone lesson uses the same edge bar.
class TrainerTimeProgress extends StatefulWidget {
  const TrainerTimeProgress({super.key, required this.value});
  final double? value;
  @override
  State<TrainerTimeProgress> createState() => _TrainerTimeProgressState();
}

class _TrainerTimeProgressState extends State<TrainerTimeProgress> {
  final _owner = Object();
  TrainerTimeProgressController? _target;
  void _publish() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _target?.publish(_owner, widget.value);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _target = TrainerTimeProgressScope.maybeOf(context);
    _publish();
  }

  @override
  void didUpdateWidget(TrainerTimeProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _publish();
  }

  @override
  void dispose() {
    final target = _target;
    WidgetsBinding.instance.addPostFrameCallback((_) => target?.clear(_owner));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _target == null && widget.value != null
      ? Align(
          alignment: Alignment.topCenter,
          child: TrainerTimeProgressBar(value: widget.value!),
        )
      : const SizedBox.shrink();
}
