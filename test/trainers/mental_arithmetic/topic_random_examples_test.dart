import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/audio/number_bank.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_topic_explanation/example_profile.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_topic_explanation/recipes.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_topic_explanation/run_recipe.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/classify.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/simple_rules.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/topic_rule.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/topic_example_generation.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';

final lessons = <String>[
  for (var digit = 1; digit <= 9; digit++) 'simple-$digit',
  'simple-tens',
  'simple-11-19',
  for (var digit = 4; digit <= 9; digit++) 'simple-${digit * 11}',
  'simple-hundreds',
  'simple-000',
  for (var digit = 4; digit >= 1; digit--) 'brother-$digit',
  for (var digit = 9; digit >= 1; digit--) 'friend-$digit',
  for (var digit = 6; digit <= 9; digit++) 'friend-brother-$digit',
];

void main() {
  test(
    'all 36 lessons keep the teaching prefix and show five valid generated actions',
    () {
      expect(lessons, hasLength(36));
      for (final lesson in lessons) {
        final profile = topicExplanationExampleProfile(lesson);
        final digit = profile.repeatedDigit;
        final rule = digit == null
            ? getTopicRule(profile.topicId)
            : createRepeatedDigitSimpleTopicRule(digit);
        for (var seed = 1; seed <= 12; seed++) {
          final chain = generateTopicExample(
            profile,
            random: TrainerSnapshotRandom(seed * 991).nextDouble,
          );
          expect(chain.steps, hasLength(5), reason: lesson);
          expect(
            rule.isValidChain?.call(chain.steps, chain.intermediates) ?? true,
            isTrue,
            reason: lesson,
          );
          for (var index = 0; index < chain.steps.length; index++) {
            final step = chain.steps[index];
            expect(
              rule.allows(
                chain.intermediates[index],
                step,
                classifyStep(chain.intermediates[index], step, rule.totalRods),
              ),
              isTrue,
              reason: lesson,
            );
          }
          if (digit != null) {
            expect(
              chain.steps.any((step) => step.amount == digit * 11),
              isTrue,
              reason: lesson,
            );
            expect(
              chain.steps.every(
                (step) =>
                    step.amount ~/ 10 <= digit && step.amount % 10 <= digit,
              ),
              isTrue,
              reason: lesson,
            );
          }
          final plan = topicExplanationRunRecipe(lesson, chain);
          final source = topicExplanationRecipe(lesson);
          final boundary = source.steps.indexWhere(
            (step) =>
                step.audioKey ==
                'explanation:abacus-topic:simple-1:example-intro',
          );
          final prefix = boundary < 0
              ? source.steps
              : source.steps.take(boundary).toList();
          expect(plan.steps.take(prefix.length), prefix, reason: lesson);
          final operations = plan.steps
              .where(
                (step) =>
                    step.audioKey?.startsWith(
                      r'$physical-example:operation:',
                    ) ??
                    false,
              )
              .toList();
          expect(operations, hasLength(5), reason: lesson);
          for (var index = 0; index < operations.length; index++) {
            expect(
              physicalGestureCueKeys(plan, operations[index].audioKey!),
              stepAudioKeys(
                amount: chain.steps[index].amount,
                sign: chain.steps[index].sign,
              ),
            );
            expect(operations[index].returnAfter, index == 4, reason: lesson);
          }
          expect(physicalGestureCueKeys(plan, r'$physical-example:answer'), [
            'explanation:abacus-topic:answer',
            ...amountAudioKeys(chain.answer),
          ]);
          expect(
            abacusToNumber(compilePhysicalGesturePlan(plan).last.rods),
            chain.answer,
            reason: lesson,
          );
          expect(
            physicalGestureAudioKeys(
              plan,
            ).any((key) => key.startsWith(r'$physical-example:')),
            isFalse,
          );
          if (seed == 1) {
            for (final locale in ['en-US', 'ar-XA']) {
              final localized = topicExplanationRunRecipe(
                lesson,
                chain,
                locale,
              );
              for (var index = 0; index < chain.steps.length; index++) {
                expect(
                  physicalGestureCueKeys(
                    localized,
                    '\$physical-example:operation:$index',
                  ),
                  stepAudioKeys(
                    amount: chain.steps[index].amount,
                    sign: chain.steps[index].sign,
                    locale: locale,
                  ),
                );
              }
              expect(
                physicalGestureAudioKeys(
                  localized,
                ).any((key) => key.startsWith('explanation:arithmetic:')),
                isFalse,
              );
            }
          }
        }
      }
    },
  );

  test(
    'an alternative example is selected when the first draw repeats the previous one',
    () {
      final profile = topicExplanationExampleProfile('simple-1');
      final first = generateTopicExample(
        profile,
        random: TrainerSnapshotRandom(991).nextDouble,
      );
      final signature = chainExampleSignature(first.steps);
      final next = generateTopicExample(
        profile,
        random: TrainerSnapshotRandom(991).nextDouble,
        previousSignature: signature,
      );
      expect(chainExampleSignature(next.steps), isNot(signature));
    },
  );
}
