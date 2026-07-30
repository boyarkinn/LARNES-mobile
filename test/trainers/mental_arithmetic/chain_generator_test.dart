import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/classify.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/generate.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/model.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/friend_rules.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/simple_rules.dart';
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
        ('simple-2digit-1digit', 'add', 'withLower'),
        ('simple-2digit', 'mix', 'withLower'),
        ('brother-4-2digit-1digit', 'mix', 'topic'),
        ('brother-4-2digit', 'mix', 'topic'),
        ('brother-4-1digit', 'mix', 'topic'),
        ('friend-9-1digit', 'mix', 'topic'),
        ('transition-50', 'mix', 'topic'),
        ('transition-100', 'mix', 'topic'),
        ('friend-brother-6-1digit', 'mix', 'topic'),
        ('friend-brother-8-2digit', 'mix', 'topic'),
        ('anzan-1digit-mix', 'mix', 'topic'),
        ('anzan-2digit', 'mix', 'topic'),
        ('anzan-2digit-1digit', 'mix', 'topic'),
        ('anzan-3digit', 'mix', 'topic'),
        ('anzan-3digit-2digit-1digit', 'mix', 'topic'),
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

    test('simple-N: amounts 1..N, ≥1 focus ±N, ≤50% focus when N>1', () {
      for (final digit in [1, 2, 4, 7, 9]) {
        final topicId = 'simple-$digit';

        for (var i = 0; i < 50; i++) {
          final chain = generateChain(
            GenerateConfig(
              topicId: topicId,
              actionCount: 5,
              signMode: 'mix',
            ),
          );

          expect(
            chain.steps.every((step) => step.amount >= 1 && step.amount <= digit),
            isTrue,
            reason: topicId,
          );

          final focusCount =
              chain.steps.where((step) => step.amount == digit).length;
          expect(focusCount, greaterThanOrEqualTo(1), reason: topicId);

          if (digit > 1) {
            expect(
              focusCount,
              lessThanOrEqualTo((chain.steps.length / 2).floor()),
              reason: topicId,
            );
            expect(
              chain.steps.any((step) => step.amount < digit),
              isTrue,
              reason: topicId,
            );
          }
        }
      }
    });

    test('simple-N v2: caps, final ≤ N, limited reverses', () {
      for (final digit in [1, 2, 4, 5, 7, 9]) {
        final topicId = 'simple-$digit';
        final intermediateMax = simpleIntermediateMax(digit);

        for (var i = 0; i < 40; i++) {
          final chain = generateChain(
            GenerateConfig(
              topicId: topicId,
              actionCount: 5,
              signMode: 'mix',
            ),
          );

          expect(
            chain.intermediates.every((v) => v >= 0 && v <= intermediateMax),
            isTrue,
            reason: topicId,
          );
          final hasSub = chain.steps.any((step) => step.sign == '-');
          if (hasSub) {
            expect(chain.answer, lessThanOrEqualTo(digit), reason: topicId);
          }
          if (digit > 1) {
            expect(
              hasEnoughSimpleTopicVariation(chain.steps),
              isTrue,
              reason: topicId,
            );
          }
        }
      }
    });

    test('v2: brother target later + quota', () {
      for (var i = 0; i < 40; i++) {
        final chain = generateChain(
          const GenerateConfig(
            topicId: 'brother-4-1digit',
            actionCount: 5,
            signMode: 'mix',
          ),
        );
        final targetIndices = <int>[];
        for (var stepIndex = 0; stepIndex < chain.steps.length; stepIndex++) {
          final technique = classifyStep(
            chain.intermediates[stepIndex],
            chain.steps[stepIndex],
            1,
          );
          if (technique.kind == TechniqueKind.brother) {
            targetIndices.add(stepIndex);
          }
        }
        expect(targetIndices, isNotEmpty);
        expect(targetIndices.length, lessThanOrEqualTo(2));
        expect(targetIndices.any((index) => index >= 2), isTrue);
      }
    });

    test('v2: friend fifty-zone forbidden', () {
      expect(
        violatesFriendFiftyZone(41, const ChainStep(amount: 9, sign: '+')),
        isTrue,
      );
      expect(
        violatesFriendFiftyZone(50, const ChainStep(amount: 3, sign: '-')),
        isTrue,
      );
      expect(
        violatesFriendFiftyZone(40, const ChainStep(amount: 9, sign: '+')),
        isFalse,
      );
    });

    test('simple-N focus steps are not stuck in the first two positions', () {
      for (final digit in [2, 5, 9]) {
        final topicId = 'simple-$digit';
        var early = 0;
        var later = 0;
        var chainsWithLaterFocus = 0;
        const samples = 120;

        for (var i = 0; i < samples; i++) {
          final chain = generateChain(
            GenerateConfig(
              topicId: topicId,
              actionCount: 5,
              signMode: 'mix',
            ),
          );
          var hasLater = false;

          for (var stepIndex = 0; stepIndex < chain.steps.length; stepIndex++) {
            if (chain.steps[stepIndex].amount != digit) {
              continue;
            }
            if (stepIndex <= 1) {
              early += 1;
            } else {
              later += 1;
              hasLater = true;
            }
          }

          if (hasLater) {
            chainsWithLaterFocus += 1;
          }
        }

        final total = early + later;
        expect(total, greaterThan(0), reason: topicId);
        expect(
          later / total,
          greaterThanOrEqualTo(0.3),
          reason: '$topicId later focus share $later/$total',
        );
        expect(
          early / total,
          lessThanOrEqualTo(0.7),
          reason: '$topicId early focus share $early/$total',
        );
        expect(
          chainsWithLaterFocus,
          samples,
          reason: topicId,
        );
      }
    });
  });
}
