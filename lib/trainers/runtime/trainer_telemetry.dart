import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:larnes_mobile/features/parent/models/parent_homework.dart';

typedef TrainerTelemetrySender = Future<void> Function(
  LessonTrainerTelemetryDescriptor descriptor,
  Map<String, dynamic> event,
);

final Map<String, int> _lastSequenceByRun = {};
final Map<String, Future<void>> _sendQueueByRun = {};

Future<void> _enqueueTrainerTelemetry(
  LessonTrainerTelemetryDescriptor descriptor,
  TrainerTelemetrySender sender,
  Map<String, dynamic> event,
) {
  final previous = _sendQueueByRun[descriptor.runId] ?? Future<void>.value();
  final next = previous
      .catchError((_) {})
      .then((_) => sender(descriptor, event));
  _sendQueueByRun[descriptor.runId] = next;
  return next;
}

int _nextTrainerTelemetrySequence(String runId) {
  final clock = DateTime.now().millisecondsSinceEpoch * 1000;
  final previous = _lastSequenceByRun[runId] ?? 0;
  final next = clock > previous ? clock : previous + 1;
  _lastSequenceByRun[runId] = next;
  return next;
}

Future<void> reportTrainerAbandoned({
  required LessonTrainerTelemetryDescriptor descriptor,
  required TrainerTelemetrySender sender,
  required int stepIndex,
}) async {
  final eventSeq = _nextTrainerTelemetrySequence(descriptor.runId);
  await _enqueueTrainerTelemetry(descriptor, sender, {
    'eventId': '${descriptor.runId}-$eventSeq',
    'eventSeq': eventSeq,
    'eventType': 'abandoned',
    'occurredAt': DateTime.now().toUtc().toIso8601String(),
    'stepIndex': stepIndex,
  });
}

class TrainerTelemetryScope extends StatefulWidget {
  const TrainerTelemetryScope({
    super.key,
    required this.child,
    required this.descriptor,
    required this.sender,
    required this.stepIndex,
    required this.totalSteps,
    required this.trainerKey,
    required this.trainerTitle,
  });

  final Widget child;
  final LessonTrainerTelemetryDescriptor descriptor;
  final TrainerTelemetrySender sender;
  final int stepIndex;
  final int totalSteps;
  final String trainerKey;
  final String trainerTitle;

  static TrainerTelemetryController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_TrainerTelemetryInherited>()
        ?.controller;
  }

  @override
  State<TrainerTelemetryScope> createState() => _TrainerTelemetryScopeState();
}

class _TrainerTelemetryScopeState extends State<TrainerTelemetryScope> {
  late final TrainerTelemetryController _controller;
  Timer? _heartbeat;

  @override
  void initState() {
    super.initState();
    _controller = TrainerTelemetryController._(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _report(
          widget.stepIndex == 0 ? 'started' : 'progress',
          progressCurrent: 0,
          progressTotal: 1,
        );
      }
    });
    _heartbeat = Timer.periodic(const Duration(seconds: 15), (_) {
      _report('heartbeat');
    });
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    super.dispose();
  }

  void _report(
    String eventType, {
    bool? correct,
    String? errorCode,
    int? progressCurrent,
    int? progressTotal,
  }) {
    final eventSeq = _nextTrainerTelemetrySequence(widget.descriptor.runId);
    final event = <String, dynamic>{
      'eventId': '${widget.descriptor.runId}-$eventSeq',
      'eventSeq': eventSeq,
      'eventType': eventType,
      'occurredAt': DateTime.now().toUtc().toIso8601String(),
      'stepIndex': widget.stepIndex,
      'trainerKey': widget.trainerKey,
      'trainerTitle': widget.trainerTitle,
      if (correct != null) 'correct': correct,
      if (errorCode != null) 'errorCode': errorCode,
      if (progressCurrent != null) 'progressCurrent': progressCurrent,
      if (progressTotal != null) 'progressTotal': progressTotal,
    };

    unawaited(
      _enqueueTrainerTelemetry(widget.descriptor, widget.sender, event)
          .catchError((_) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _TrainerTelemetryInherited(
      controller: _controller,
      child: widget.child,
    );
  }
}

class TrainerTelemetryController {
  const TrainerTelemetryController._(this._state);

  final _TrainerTelemetryScopeState _state;

  void complete() {
    _state._report(
      _state.widget.stepIndex >= _state.widget.totalSteps - 1
          ? 'completed'
          : 'progress',
    );
  }

  void interaction({
    required bool correct,
    String? errorCode,
    int? progressCurrent,
    int? progressTotal,
  }) {
    _state._report(
      'interaction',
      correct: correct,
      errorCode: errorCode,
      progressCurrent: progressCurrent,
      progressTotal: progressTotal,
    );
  }

  void progress({required int current, required int total}) {
    _state._report(
      'progress',
      progressCurrent: current,
      progressTotal: total,
    );
  }
}

class _TrainerTelemetryInherited extends InheritedWidget {
  const _TrainerTelemetryInherited({
    required this.controller,
    required super.child,
  });

  final TrainerTelemetryController controller;

  @override
  bool updateShouldNotify(_TrainerTelemetryInherited oldWidget) {
    return oldWidget.controller != controller;
  }
}
