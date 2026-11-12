import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/admin/models/trainer_play.dart';
import 'package:larnes_mobile/features/admin/screens/trainer_play_labels.dart';
import 'package:larnes_mobile/features/parent/models/parent_homework.dart';
import 'package:larnes_mobile/features/parent/trainers/parent_trainer_params_utils.dart';
import 'package:larnes_mobile/l10n/app_localizations_en.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_chain_example_widget.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_flash/topic_chain_attempt_record.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_flash/topic_chain_flash_trainer.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_telemetry.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';

const _fixedChain = {
  'topicId': 'simple-1',
  'steps': [
    {'amount': 1, 'sign': '+'},
    {'amount': 1, 'sign': '+'},
  ],
  'intermediates': [0, 1, 2],
  'answer': 2,
};

Map<String, dynamic> _params({bool enabled = true, int count = 1}) => {
  'topicId': 'simple-1',
  'actionCount': 2,
  'exampleCount': count,
  'stepPauseSec': 0.1,
  'reviewErrors': enabled,
  'errorReviewStepSec': 4.5,
  '__runtimeSnapshot': {
    'version': 1,
    'mode': 'materialized',
    'trainerKey': 'topic-chain-flash',
    'payload': {'chains': List.generate(count, (_) => _fixedChain)},
  },
};

Future<void> _reachAnswer(WidgetTester tester, {bool first = false}) async {
  if (first) {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1800));
  }
  await tester.pump(const Duration(milliseconds: 3000));
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.byType(TextField), findsOneWidget);
}

Future<void> _submit(WidgetTester tester, String answer) async {
  await tester.enterText(find.byType(TextField), answer);
  tester.widget<TextField>(find.byType(TextField)).onSubmitted!(answer);
  await tester.pump();
}

void main() {
  test('review params are optional, finite and independently bounded', () {
    final old = {'topicId': 'simple-1', 'actionCount': 5, 'stepPauseSec': 0.1};
    final defaults = validateTrainerParams('topic-chain-flash', old);
    expect(defaults.params?['reviewErrors'], false);
    expect(defaults.params?['errorReviewStepSec'], 3.0);
    for (final value in [0.1, 3, 30]) {
      final valid = validateTrainerParams('topic-chain-flash', {
        ...old,
        'reviewErrors': true,
        'errorReviewStepSec': value,
      });
      expect(valid.ok, true);
      expect(valid.params?['stepPauseSec'], 0.1);
      expect(valid.params?['errorReviewStepSec'], value);
    }
    for (final value in [0.09, 30.1, double.nan, double.infinity, 'no']) {
      expect(
        validateTrainerParams('topic-chain-flash', {
          ...old,
          'errorReviewStepSec': value,
        }).ok,
        false,
      );
    }
    expect(
      validateTrainerParams('topic-chain-flash', {
        ...old,
        'reviewErrors': 'true',
      }).ok,
      false,
    );
  });

  test(
    'native form serialization and stored homework values retain both params',
    () {
      final config = TrainerPlayConfig.fromJson({
        'trainerKey': 'topic-chain-flash',
        'title': 'Chain',
        'defaultParams': {
          'chainTopicId': 'simple-1',
          'actionCount': 5,
          'exampleCount': 1,
          'stepPauseSec': 1,
          'reviewErrors': false,
          'errorReviewStepSec': 3,
        },
        'fields': [
          {
            'key': 'reviewErrors',
            'type': 'checkbox',
            'labelKey': 'reviewErrorsLabel',
          },
          {
            'key': 'errorReviewStepSec',
            'type': 'number',
            'labelKey': 'errorReviewStepSecLabel',
            'min': 0.1,
            'max': 30,
            'showWhen': {'field': 'reviewErrors', 'equals': 'true'},
          },
        ],
      });
      final values = mergeStoredParamsIntoFormValues(config, {
        'topicId': 'brother-1',
        'reviewErrors': true,
        'errorReviewStepSec': 4.5,
      });
      expect(values['chainTopicId'], 'brother-1');
      expect(values['reviewErrors'], 'true');
      expect(config.fields.last.isVisible(values), true);
      final parsed = buildPlayParamsPayload(config, values);
      expect(parsed['reviewErrors'], true);
      expect(parsed['errorReviewStepSec'], 4.5);
      values['reviewErrors'] = 'false';
      expect(config.fields.last.isVisible(values), false);
      expect(buildPlayParamsPayload(config, values)['reviewErrors'], false);
    },
  );

  for (final locale in ['ru', 'en', 'ar']) {
    test('native review field labels are localized for $locale', () {
      final l10n = AppLocalizationsEn(locale);
      expect(
        trainerPlayFieldLabel(l10n, 'reviewErrorsLabel'),
        isNot('reviewErrorsLabel'),
      );
      expect(
        trainerPlayFieldLabel(l10n, 'errorReviewStepSecLabel'),
        isNot('errorReviewStepSecLabel'),
      );
    });
  }

  test(
    'attempt serializes the original first answer independently of help',
    () {
      final chain = Chain(
        topicId: 'simple-1',
        answer: 2,
        steps: const [
          ChainStep(amount: 1, sign: '+'),
          ChainStep(amount: 1, sign: '+'),
        ],
        intermediates: [0, 1, 2],
      );
      final record = TopicChainAttemptRecord(chain: chain, firstAnswer: 9);
      record.reviewCompleted = true;
      record.retryAnswer = 2;
      expect(record.toJson(), {
        'chain': _fixedChain,
        'firstAnswer': 9,
        'reviewCompleted': true,
        'retryAnswer': 2,
      });
    },
  );

  for (final retryCorrect in [true, false]) {
    testWidgets(
      'first error reviews once; retry correct=$retryCorrect closes last example',
      (tester) async {
        var completed = 0;
        final events = <Map<String, dynamic>>[];
        var params = _params();
        Widget app() => MaterialApp(
          home: Scaffold(
            body: TrainerTelemetryScope(
              descriptor: LessonTrainerTelemetryDescriptor(
                reportToken: 'unit',
                reportUrl: '/unit',
                runId: 'review-$retryCorrect',
              ),
              sender: (_, event) async => events.add(event),
              stepIndex: 0,
              totalSteps: 1,
              trainerKey: 'topic-chain-flash',
              trainerTitle: 'Chain',
              child: TopicChainFlashTrainer(
                params: params,
                onComplete: () => completed++,
              ),
            ),
          ),
        );
        await tester.pumpWidget(app());
        await _reachAnswer(tester, first: true);
        await _submit(tester, '9');
        expect(find.byType(PhysicalChainExample), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
        final review = tester.widget<PhysicalChainExample>(
          find.byType(PhysicalChainExample),
        );
        expect(review.chain.answer, 2);
        expect(review.chain.intermediates, [0, 1, 2]);
        expect(review.stepSec, 4.5);
        expect(review.stateKey, 'topic-chain-review-0');
        // Rehydrating equivalent immutable runtime data must not reset attempts.
        params = Map<String, dynamic>.from(
          jsonDecode(jsonEncode(params)) as Map,
        );
        await tester.pumpWidget(app());
        expect(
          identical(
            tester
                .widget<PhysicalChainExample>(find.byType(PhysicalChainExample))
                .chain,
            review.chain,
          ),
          true,
        );
        expect(completed, 0);
        // The shared scene's own audio/timing gate is covered by its run-1 tests.
        review.onComplete!();
        review.onComplete!();
        await tester.pump();
        expect(find.byType(PhysicalChainExample), findsNothing);
        await _reachAnswer(tester);
        await _submit(tester, '-');
        expect(completed, 0);
        expect(find.byType(TextField), findsOneWidget);
        await _submit(tester, retryCorrect ? '2' : '9');
        await tester.pump(const Duration(milliseconds: 900));
        expect(completed, 1);
        expect(find.byType(PhysicalChainExample), findsNothing);
        final primary = events
            .where((event) => event['eventType'] == 'interaction')
            .toList();
        expect(primary.length, 1);
        expect(primary.single['correct'], false);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 4));
      },
    );
  }

  testWidgets('lifecycle suspends a review and rejects its stale callback', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TopicChainFlashTrainer(
            params: _params(),
            onComplete: () => completed++,
          ),
        ),
      ),
    );
    await _reachAnswer(tester, first: true);
    await _submit(tester, '9');
    final stale = tester
        .widget<PhysicalChainExample>(find.byType(PhysicalChainExample))
        .onComplete!;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(
      tester
          .widget<PhysicalChainExample>(find.byType(PhysicalChainExample))
          .autoPlay,
      false,
    );
    stale();
    await tester.pump(const Duration(seconds: 10));
    expect(completed, 0);
    expect(find.byType(PhysicalChainExample), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    stale();
    await tester.pump();
    expect(find.byType(PhysicalChainExample), findsOneWidget);
    tester
        .widget<PhysicalChainExample>(find.byType(PhysicalChainExample))
        .onComplete!();
    await tester.pump();
    await _reachAnswer(tester);
    await _submit(tester, '9');
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets(
    'a retry error advances to the next example with a fresh review',
    (tester) async {
      var completed = 0;
      final events = <Map<String, dynamic>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrainerTelemetryScope(
              descriptor: const LessonTrainerTelemetryDescriptor(
                reportToken: 'unit',
                reportUrl: '/unit',
                runId: 'two-review-examples',
              ),
              sender: (_, event) async => events.add(event),
              stepIndex: 0,
              totalSteps: 1,
              trainerKey: 'topic-chain-flash',
              trainerTitle: 'Chain',
              child: TopicChainFlashTrainer(
                params: _params(count: 2),
                onComplete: () => completed++,
              ),
            ),
          ),
        ),
      );
      await _reachAnswer(tester, first: true);
      for (var index = 0; index < 2; index++) {
        await _submit(tester, '9');
        final review = tester.widget<PhysicalChainExample>(
          find.byType(PhysicalChainExample),
        );
        expect(review.stateKey, 'topic-chain-review-$index');
        review.onComplete!();
        await tester.pump();
        await _reachAnswer(tester);
        await _submit(tester, '9');
        if (index == 0) {
          expect(completed, 0);
          await _reachAnswer(tester);
        }
      }
      expect(completed, 1);
      final primary = events
          .where((e) => e['eventType'] == 'interaction')
          .toList();
      expect(primary.map((e) => e['progressCurrent']), [1, 2]);
      expect(primary.map((e) => e['correct']), [false, false]);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 4));
    },
  );

  testWidgets(
    'control mode never opens review; a first correct answer stays primary',
    (tester) async {
      var completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TopicChainFlashTrainer(
              params: _params(enabled: false),
              onComplete: () => completed++,
            ),
          ),
        ),
      );
      await _reachAnswer(tester, first: true);
      await _submit(tester, '9');
      expect(completed, 1);
      expect(find.byType(PhysicalChainExample), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 150));
      completed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TopicChainFlashTrainer(
              params: _params(),
              onComplete: () => completed++,
            ),
          ),
        ),
      );
      await _reachAnswer(tester, first: true);
      await _submit(tester, '2');
      expect(find.byType(PhysicalChainExample), findsNothing);
      await tester.pump(const Duration(milliseconds: 900));
      expect(completed, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 4));
    },
  );
}
