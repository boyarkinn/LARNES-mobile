import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:larnes_mobile/features/parent/models/parent_homework.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_chain_example_widget.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_flash/topic_chain_flash_trainer.dart';
import 'package:larnes_mobile/trainers/runtime/topic_chain_run_scope.dart';
import 'package:larnes_mobile/trainers/runtime/topic_chain_run_state.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_telemetry.dart';

const _prefix = topicChainStatePrefix;
const _chain = {
  'topicId': 'simple-1',
  'steps': [
    {'amount': 1, 'sign': '+'},
    {'amount': 1, 'sign': '+'},
  ],
  'intermediates': [0, 1, 2],
  'answer': 2,
};
const _params = {
  'topicId': 'simple-1',
  'actionCount': 2,
  'exampleCount': 1,
  'stepPauseSec': 0.1,
  'reviewErrors': true,
  'errorReviewStepSec': 3,
};
const _snapshot = {
  'version': 1,
  'mode': 'materialized',
  'trainerKey': 'topic-chain-flash',
  'payload': {
    'chains': [_chain],
  },
};
Map<String, dynamic> _copy(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
Map<String, dynamic> _state({
  String phase = 'answer',
  bool reviewCompleted = false,
  bool submitting = false,
  int? retryAnswer,
}) => {
  '${_prefix}phase': phase,
  '${_prefix}chain': _chain,
  '${_prefix}exampleIndex': 0,
  '${_prefix}answerDraft': '',
  '${_prefix}isSubmitting': submitting,
  '${_prefix}isCorrect': false,
  '${_prefix}flashStepIndex': -1,
  '${_prefix}attempts': {
    '0': {
      'chain': _chain,
      'firstAnswer': 99,
      'reviewCompleted': reviewCompleted,
      'retryAnswer': retryAnswer,
    },
  },
};

void main() {
  late Map<String, dynamic> server;
  var offline = false;
  late List<Map<String, dynamic>> primary;
  Future<Map<String, dynamic>> request(Map<String, dynamic> command) async {
    if (offline) throw StateError('offline');
    if (command['action'] == 'save') {
      server['revision'] = (server['revision'] as int) + 1;
      server['state'] = _copy(
        Map<String, dynamic>.from(command['state'] as Map),
      );
      server['completed'] =
          (server['state'] as Map)['${_prefix}phase'] == 'complete';
    }
    return {'status': 'ok', 'run': _copy(server)};
  }

  TopicChainRunController makeController() => TopicChainRunController(
    request: request,
    context: {
      'source': 'homework',
      'childId': 'child-a',
      'assignmentId': 'assignment-a',
      'stepIndex': 0,
    },
    ownerId: 'adult-a',
    locale: 'ru',
  );
  Widget app(TopicChainRunController controller, VoidCallback complete) =>
      MaterialApp(
        home: Scaffold(
          body: TopicChainRunScope(
            controller: controller,
            child: TrainerTelemetryScope(
              descriptor: LessonTrainerTelemetryDescriptor(
                reportToken: 'unit',
                reportUrl: '/unit',
                runId: 'restore',
              ),
              sender: (_, event) async {
                if (event['eventType'] == 'interaction') primary.add(event);
              },
              stepIndex: 0,
              totalSteps: 1,
              trainerKey: 'topic-chain-flash',
              trainerTitle: 'Chain',
              child: TopicChainFlashTrainer(
                params: {..._params, '__runtimeSnapshot': _snapshot},
                onComplete: complete,
              ),
            ),
          ),
        ),
      );
  Future<void> settle(
    WidgetTester tester,
    TopicChainRunController controller,
  ) async {
    await tester.pump();
    await tester.runAsync(() => controller.flush().catchError((Object _) {}));
    await tester.pump();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    offline = false;
    primary = [];
    server = {
      'id': 'run-a',
      'revision': 0,
      'params': _params,
      'runtimeSnapshot': _snapshot,
      'state': <String, dynamic>{},
      'completed': false,
    };
  });

  testWidgets(
    'a cold accepted first-error checkpoint enters review without another primary interaction',
    (tester) async {
      server['state'] = _state(submitting: true);
      final controller = makeController();
      await tester.runAsync(controller.open);
      var completed = 0;
      await tester.pumpWidget(app(controller, () => completed++));
      await settle(tester, controller);
      expect(find.byType(PhysicalChainExample), findsOneWidget);
      expect(primary, isEmpty);
      expect(completed, 0);
      expect(controller.state['${_prefix}phase'], 'review');
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets(
    'a cold review resumes the committed semantic step on the original chain',
    (tester) async {
      server['state'] = {
        ..._state(phase: 'review'),
        'topic-chain-flash:review:0:committedStep': 2,
      };
      final controller = makeController();
      await tester.runAsync(controller.open);
      await tester.pumpWidget(app(controller, () {}));
      final review = tester.widget<PhysicalChainExample>(
        find.byType(PhysicalChainExample),
      );
      expect(review.initialCheckpointStep, 2);
      expect(review.chain.answer, 2);
      expect(review.chain.intermediates, [0, 1, 2]);
      expect(primary, isEmpty);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await tester.pump(const Duration(seconds: 1));
    },
  );

  for (final retryAnswer in ['2', '9']) {
    testWidgets(
      'a cold retry $retryAnswer completes once and preserves the initial error',
      (tester) async {
        server['state'] = _state(reviewCompleted: true);
        final controller = makeController();
        await tester.runAsync(controller.open);
        var completed = 0;
        await tester.pumpWidget(app(controller, () => completed++));
        await tester.pump();
        expect(find.byType(TextField), findsOneWidget);
        await tester.enterText(find.byType(TextField), retryAnswer);
        tester.widget<TextField>(find.byType(TextField)).onSubmitted!(
          retryAnswer,
        );
        await settle(tester, controller);
        await tester.pump(const Duration(milliseconds: 950));
        await settle(tester, controller);
        expect(completed, 1);
        expect(server['completed'], true);
        expect(primary, isEmpty);
        final attempts = (server['state'] as Map)['${_prefix}attempts'] as Map;
        expect((attempts['0'] as Map)['firstAnswer'], 99);
        expect((attempts['0'] as Map)['retryAnswer'], int.parse(retryAnswer));
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
        await tester.pump(const Duration(seconds: 1));
      },
    );
  }

  testWidgets(
    'a failed retry save cannot complete; reconnect and remount use the accepted retry without asking again',
    (tester) async {
      server['state'] = _state(reviewCompleted: true);
      var controller = makeController();
      await tester.runAsync(controller.open);
      var completed = 0;
      await tester.pumpWidget(app(controller, () => completed++));
      await tester.pump();
      offline = true;
      await tester.enterText(find.byType(TextField), '9');
      tester.widget<TextField>(find.byType(TextField)).onSubmitted!('9');
      await settle(tester, controller);
      expect(completed, 0);
      expect(controller.failed, true);
      expect(server['completed'], false);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await tester.pump(const Duration(seconds: 1));
      offline = false;
      controller = makeController();
      await tester.runAsync(controller.open);
      await tester.pumpWidget(app(controller, () => completed++));
      await settle(tester, controller);
      expect(completed, 1);
      expect(server['completed'], true);
      expect(find.byType(TextField), findsNothing);
      expect(primary, isEmpty);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await tester.pump(const Duration(seconds: 1));
    },
  );
}
