import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_flash/check_answer.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_flash/topic_chain_flash_trainer.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';

void main() {
  group('topic-chain-flash check-answer', () {
    test('accepts exact and trims', () {
      expect(isCorrectAnswer('12', 12), isTrue);
      expect(isCorrectAnswer(' 12 ', 12), isTrue);
      expect(isCorrectAnswer('13', 12), isFalse);
    });
  });

  group('topic-chain-flash params', () {
    test('validates defaults and rejects bad topicId', () {
      final ok = validateTrainerParams('topic-chain-flash', {
        'topicId': 'simple-1',
        'actionCount': 5,
        'stepPauseSec': 1,
      });
      expect(ok.ok, isTrue);
      expect(ok.params?['exampleCount'], 1);
      expect(ok.params?['solveMode'], 'abacus');

      final withExamples = validateTrainerParams('topic-chain-flash', {
        'topicId': 'simple-1',
        'actionCount': 5,
        'exampleCount': 3,
        'solveMode': 'mental',
        'stepPauseSec': 1,
      });
      expect(withExamples.ok, isTrue);
      expect(withExamples.params?['exampleCount'], 3);
      expect(withExamples.params?['solveMode'], 'mental');

      final bad = validateTrainerParams('topic-chain-flash', {
        'topicId': 'nope',
        'actionCount': 5,
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
                  'stepPauseSec': 0.05,
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      // instruction silent (~1800) + countdown 3→2→1→Старт (4×750ms) + flash steps
      await tester.pump(const Duration(milliseconds: 1800));
      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Повторить'), findsNothing);

      await tester.enterText(find.byType(TextField), '99999');
      await tester.tap(find.text('Проверить'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Повторить'), findsOneWidget);
    });
  });
}
