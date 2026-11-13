import 'package:flutter/widgets.dart';
import 'package:larnes_mobile/core/auth/auth_scope.dart';

class TrainerResultScope extends InheritedWidget {
  const TrainerResultScope({
    super.key,
    required this.runContext,
    required this.trainerKey,
    required super.child,
  });
  final Map<String, dynamic>? runContext;
  final String trainerKey;
  static TrainerResultScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TrainerResultScope>();
  String? get storageKey {
    final c = runContext;
    if (c == null) return null;
    final scope = c['source'] == 'direct'
        ? 'direct:${c['childId']}:${c['launchId']}'
        : c['source'] == 'homework'
        ? 'homework:${c['childId']}:${c['assignmentId']}:${c['stepIndex']}'
        : 'lesson:${c['runId']}:${c['stepIndex']}';
    return 'trainer-checkpoint:$trainerKey:$scope';
  }

  Future<void> save(BuildContext context, Map<String, dynamic> result) async {
    if (runContext != null) {
      await AuthScope.of(
        context,
      ).trainerResultsApi.save(trainerKey, runContext!, result);
    }
  }

  @override
  bool updateShouldNotify(TrainerResultScope oldWidget) =>
      runContext != oldWidget.runContext || trainerKey != oldWidget.trainerKey;
}
