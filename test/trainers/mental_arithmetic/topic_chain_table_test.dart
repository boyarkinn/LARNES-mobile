import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/admin/models/trainer_play.dart';
import 'package:larnes_mobile/trainers/catalog/registry.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/generate.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_table/parse_step.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_table/topic_chain_table_trainer.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';

void main() {
  group('parseEditableStep', () {
    test('parses signed and bare amounts', () {
      expect(parseEditableStep('+12'), const ChainStep(amount: 12, sign: '+'));
      expect(parseEditableStep('-3'), const ChainStep(amount: 3, sign: '-'));
      expect(parseEditableStep('7'), const ChainStep(amount: 7, sign: '+'));
      expect(
        parseEditableStep(' + 40 '),
        const ChainStep(amount: 40, sign: '+'),
      );
    });

    test('rejects empty and invalid', () {
      expect(parseEditableStep(''), isNull);
      expect(parseEditableStep('+'), isNull);
      expect(parseEditableStep('0'), isNull);
      expect(parseEditableStep('1000'), isNull);
      expect(parseEditableStep('abc'), isNull);
    });
  });

  group('topic-chain-table params', () {
    test('defaults and rejects bad topic / counts', () {
      final ok = validateTrainerParams('topic-chain-table', {
        'topicId': 'simple-1',
        'actionCount': 4,
      });
      expect(ok.ok, isTrue);
      expect(ok.params?['exampleCount'], 5);

      final badTopic = validateTrainerParams('topic-chain-table', {
        'topicId': 'nope',
        'actionCount': 4,
      });
      expect(badTopic.ok, isFalse);

      final badCount = validateTrainerParams('topic-chain-table', {
        'topicId': 'simple-1',
        'actionCount': 4,
        'exampleCount': 13,
      });
      expect(badCount.ok, isFalse);
    });

    test('definition is non-interactive', () {
      final definition = getTrainerDefinition('topic-chain-table');
      expect(definition, isNotNull);
      expect(definition!.title, 'Таблица цепочек');
      expect(definition.isInteractive, isFalse);
    });

    test('maps chainTopicId form payload', () {
      final config = TrainerPlayConfig.fromJson({
        'status': 'success',
        'trainerKey': 'topic-chain-table',
        'title': 'Table',
        'direction': 'mental',
        'isInteractive': false,
        'defaultParams': {
          'chainTopicId': 'simple-1',
          'actionCount': 4,
          'exampleCount': 5,
        },
        'fields': [],
      });

      final payload = buildPlayParamsPayload(config, {
        'chainTopicId': 'friend-9-2digit',
        'actionCount': '6',
        'exampleCount': '5',
      });

      expect(payload['topicId'], 'friend-9-2digit');
      expect(payload['actionCount'], 6);
      expect(payload['exampleCount'], 5);
      expect(payload.containsKey('stepPauseSec'), isFalse);
      expect(payload.containsKey('chainTopicId'), isFalse);
    });
  });

  group('topic-chain-table generate', () {
    test('builds N independent chains', () {
      const topicId = 'simple-1';
      const actionCount = 4;
      const exampleCount = 5;
      final chains = List.generate(
        exampleCount,
        (_) => generateChain(
          GenerateConfig(
            topicId: topicId,
            actionCount: actionCount,
            signMode: 'mix',
          ),
        ),
      );

      expect(chains, hasLength(exampleCount));
      for (final chain in chains) {
        expect(chain.steps, hasLength(actionCount));
      }
    });
  });

  group('topic-chain-table widget', () {
    testWidgets('renders regenerate buttons and step cells', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: TopicChainTableTrainer(
                params: {
                  'topicId': 'simple-1',
                  'actionCount': 4,
                  'exampleCount': 3,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsNWidgets(3));
      expect(find.textContaining('+'), findsWidgets);
    });
  });
}
