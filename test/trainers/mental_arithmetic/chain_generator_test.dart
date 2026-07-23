import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/classify.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/generate.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/model.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/topics.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';

void main() {
  group('chain-generator topics', () {
    test('mvp catalog covers simple / brother / friend', () {
      final mvp = listTopicsByStatus(TopicStatus.mvp);
      expect(mvp.any((t) => t.id == 'simple-1'), isTrue);
      expect(mvp.any((t) => t.id == 'brother-4-1digit'), isTrue);
      expect(mvp.any((t) => t.id == 'friend-9-1digit'), isTrue);
      expect(isTopicId('simple-1'), isTrue);
      expect(isTopicId('nope'), isFalse);
    });
  });

  group('chain-generator classify', () {
    test('marks 4+4 as brother 4 and 0+3 as direct', () {
      expect(
        classifyStep(4, const ChainStep(amount: 4, sign: '+'), 1),
        const Technique.brother(4),
      );
      expect(
        classifyStep(0, const ChainStep(amount: 3, sign: '+'), 1),
        const Technique.direct(),
      );
    });

    test('marks 2+9 as friend 9', () {
      expect(
        classifyStep(2, const ChainStep(amount: 9, sign: '+'), 2),
        const Technique.friend(9),
      );
    });

    test('marks 5+6 as friendBrother 6', () {
      expect(
        classifyStep(5, const ChainStep(amount: 6, sign: '+'), 2),
        const Technique.friendBrother(6),
      );
    });
  });

  group('chain-generator model', () {
    test('applies steps from zero without going negative', () {
      expect(applyChainStep(0, const ChainStep(amount: 4, sign: '+'), 1), 4);
      expect(applyChainStep(4, const ChainStep(amount: 2, sign: '-'), 1), 2);
      expect(tryApplyChainStep(1, const ChainStep(amount: 2, sign: '-'), 1), isNull);
    });
  });

  group('chain-generator generateChain', () {
    test('builds a valid mix chain for simple-1', () {
      final chain = generateChain(
        const GenerateConfig(
          topicId: 'simple-1',
          actionCount: 5,
          signMode: 'mix',
        ),
      );
      expect(chain.steps, hasLength(5));
      expect(chain.intermediates.first, 0);
      expect(chain.intermediates.last, chain.answer);
      expect(chain.answer, greaterThanOrEqualTo(0));
    });

    test('spot-check MVP topics stay in-topic', () {
      const cases = [
        ('simple-1', 'mix', 'topic'),
        ('simple-2digit', 'add', 'withLower'),
        ('brother-4-1digit', 'mix', 'topic'),
        ('friend-9-1digit', 'mix', 'topic'),
      ];

      for (final (topicId, signMode, amountScope) in cases) {
        for (var i = 0; i < 8; i++) {
          final chain = generateChain(
            GenerateConfig(
              topicId: topicId,
              actionCount: 5,
              signMode: signMode,
              amountScope: amountScope,
            ),
          );
          expect(chain.steps.length, 5, reason: topicId);
          expect(chain.answer, greaterThanOrEqualTo(0), reason: topicId);
        }
      }
    });
  });
}
