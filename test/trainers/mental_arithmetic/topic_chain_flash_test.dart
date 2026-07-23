import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_flash/check_answer.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_flash/topic_chain_flash_trainer.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';

void main() {
  group('topic-chain-flash check-answer', () {
    test('parses plain integers and rejects junk', () {
      expect(parseAnswerInput('12'), 12);
      expect(parseAnswerInput('  -3 '), -3);
      expect(parseAnswerInput(''), isNull);
      expect(parseAnswerInput('12a'), isNull);
    });

    test('matches expected answer', () {
      expect(isCorrectAnswer('7', 7), isTrue);
      expect(isCorrectAnswer('8', 7), isFalse);
    });
  });

  group('topic-chain-flash params', () {
    test('validates defaults and rejects bad topicId', () {
      final ok = validateTrainerParams('topic-chain-flash', {
        'topicId': 'simple-1',
        'actionCount': 5,
        'signMode': 'mix',
        'amountScope': 'topic',
        'stepPauseSec': 1,
      });
      expect(ok.ok, isTrue);

      final bad = validateTrainerParams('topic-chain-flash', {
        'topicId': 'nope',
        'actionCount': 5,
        'signMode': 'mix',
        'stepPauseSec': 1,
      });
      expect(bad.ok, isFalse);
    });
  });

  group('topic-chain-flash trainer', () {
    testWidgets('flash then answer field in bounded stage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 700,
              child: TopicChainFlashTrainer(
                params: {
                  'topicId': 'simple-1',
                  'actionCount': 3,
                  'signMode': 'add',
                  'amountScope': 'topic',
                  'stepPauseSec': 0.05,
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(TopicChainFlashTrainer), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Проверить'), findsOneWidget);
    });
  });
}
