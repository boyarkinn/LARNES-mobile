import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/example_visualization/autoplay_timeline.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/example_visualization/example_parser.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/example_visualization/step_planner.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

/// Web v2: `platform/src/trainers/mental-arithmetic/example-visualization/component.tsx`
class ExampleVisualizationTrainer extends StatefulWidget {
  const ExampleVisualizationTrainer({
    super.key,
    required this.params,
  });

  final Map<String, dynamic> params;

  @override
  State<ExampleVisualizationTrainer> createState() =>
      _ExampleVisualizationTrainerState();
}

class _ExampleVisualizationTrainerState extends State<ExampleVisualizationTrainer> {
  late ExampleStepPlan _plan;
  late List<AutoplayTimelineEvent> _timeline;
  late List<RodState> _rods;
  String? _actionLabel;
  int _timelineIndex = 0;
  Timer? _timer;
  Object _runToken = Object();

  @override
  void initState() {
    super.initState();
    _restartAutoplay();
  }

  @override
  void didUpdateWidget(ExampleVisualizationTrainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params != widget.params) {
      _restartAutoplay();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restartAutoplay() {
    _timer?.cancel();
    final runToken = Object();
    _runToken = runToken;

    final example = widget.params['example'] as String? ?? '+2 -1';
    final totalRods = widget.params['totalRods'] as int? ?? 2;
    final stepPauseSec =
        (widget.params['stepPauseSec'] as num?)?.toDouble() ?? 2;

    _plan = planExampleSteps(example, totalRods);
    _timeline = buildAutoplayTimeline(_plan.actions.length);
    _rods = cloneExampleRods(_plan.rodStates.first);
    _actionLabel = null;
    _timelineIndex = 0;

    _scheduleNext(runToken, stepPauseSec);
  }

  void _scheduleNext(Object runToken, double stepPauseSec) {
    if (!mounted || !identical(runToken, _runToken)) {
      return;
    }

    if (_timelineIndex >= _timeline.length) {
      return;
    }

    final event = _timeline[_timelineIndex];
    _timelineIndex += 1;

    switch (event.type) {
      case AutoplayEventType.pause:
        setState(() {
          _actionLabel = formatExampleAction(_plan.actions[event.actionIndex!]);
        });
        _timer = Timer(Duration(milliseconds: pauseMs(stepPauseSec)), () {
          _scheduleNext(runToken, stepPauseSec);
        });
      case AutoplayEventType.anim:
        _timer = Timer(Duration.zero, () {
          if (!mounted || !identical(runToken, _runToken)) {
            return;
          }

          setState(() {
            _rods = cloneExampleRods(_plan.rodStates[event.rodStateIndex!]);
          });

          _timer = Timer(const Duration(milliseconds: beadAnimMs), () {
            _scheduleNext(runToken, stepPauseSec);
          });
        });
      case AutoplayEventType.done:
        setState(() => _actionLabel = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalRods = widget.params['totalRods'] as int? ?? 2;

    return TrainerScene(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.maxHeight * 0.72;
          final maxWidth = constraints.maxWidth * 0.96;

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 44,
                  child: Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _actionLabel == null ? 0 : 1,
                      child: Text(
                        _actionLabel ?? ' ',
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 28,
                          height: 1,
                          letterSpacing: -0.5,
                          color: Color(0xFF262626),
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: maxHeight,
                    maxWidth: maxWidth,
                  ),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: AbacusWidget(
                      rods: _rods,
                      totalRods: totalRods,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
