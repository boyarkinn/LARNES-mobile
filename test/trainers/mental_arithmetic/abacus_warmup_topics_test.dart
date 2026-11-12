import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_warmup/recipes.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_warmup_topics.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';
import 'package:larnes_mobile/features/admin/models/trainer_play.dart';

void main() {
  for (final type in warmupTypes) {
    for (final topic in warmupTopicNumbers(type)) {
      test(
        '$type/$topic: correct arithmetic, complete return and existing intro',
        () {
          final plan = warmupRecipe(type, [topic]);
          final frames = compilePhysicalGesturePlan(plan);
          expect(
            frames.length,
            type == 'brothers'
                ? 77
                : type == 'friends'
                ? 15
                : type == 'simple-2digit'
                ? 12
                : 26,
          );
          final selected = frames.skip(
            type == 'brothers'
                ? 13
                : type == 'friends'
                ? 3
                : 0,
          );
          final target = type == 'brothers'
              ? 5 - topic
              : type == 'friends'
              ? 10 - topic
              : topic;
          final moves = selected
              .expand((frame) => frame.moves)
              .where(
                (move) => type != 'friends' || move.hand == AbacusHand.right,
              );
          expect(moves.any((move) => beadsToDigit(move.to) == target), true);
          expect(
            moves.every(
              (move) => [
                type == 'brothers' ? 5 : 0,
                target,
              ].contains(beadsToDigit(move.to)),
            ),
            true,
          );
          final finalDigits = frames.last.rods.map(beadsToDigit).toList();
          if (type == 'friends') {
            expect(finalDigits, [0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0]);
          } else {
            expect(
              finalDigits.every(
                (digit) => digit == (type == 'brothers' ? 5 : 0),
              ),
              true,
            );
          }
          expect(plan.openingAudioKey, warmupOpeningKey(type, [topic]));
          expect(identical(plan, warmupRecipe(type, [topic])), true);
        },
      );
    }
    test('$type: all topics keep the previous complete block', () {
      expect(
        identical(
          warmupRecipe(type),
          warmupRecipe(type, warmupTopicNumbers(type).reversed.toList()),
        ),
        true,
      );
    });
  }
  test(
    'multiple topics prepare once and all three hand variants are present',
    () {
      expect(
        compilePhysicalGesturePlan(warmupRecipe('simple-9', [2, 3, 5])).length,
        78,
      );
      expect(
        compilePhysicalGesturePlan(warmupRecipe('brothers', [1, 4])).length,
        141,
      );
      expect(
        compilePhysicalGesturePlan(warmupRecipe('friends', [1, 9])).length,
        27,
      );
    },
  );
  test('validator keeps selection and rejects empty or foreign topics', () {
    expect(
      validateTrainerParams('abacus-warmup', {
        'warmupType': 'brothers',
        'warmupTopics': [1, 4, 1],
      }).params?['warmupTopics'],
      [4, 1],
    );
    for (final topics in [
      [],
      [0],
      [5],
      [1.5],
      'bad',
    ]) {
      expect(
        validateTrainerParams('abacus-warmup', {
          'warmupType': 'brothers',
          'warmupTopics': topics,
        }).ok,
        false,
      );
    }
  });
  test(
    'native multi-select emits numeric arrays and retains an explicitly empty selection',
    () {
      final config = TrainerPlayConfig.fromJson({
        'trainerKey': 'abacus-warmup',
        'title': 'Warmup',
        'fields': [
          {
            'key': 'warmupTopics',
            'type': 'multi-select',
            'labelKey': 'warmupTopicsLabel',
            'options': [
              for (final number in [4, 3, 2, 1])
                {'value': '$number', 'label': '$number'},
            ],
          },
        ],
      });
      expect(
        buildPlayParamsPayload(config, {'warmupTopics': '4,1'})['warmupTopics'],
        [4, 1],
      );
      expect(
        buildPlayParamsPayload(config, {'warmupTopics': 'all'})['warmupTopics'],
        [4, 3, 2, 1],
      );
      expect(
        buildPlayParamsPayload(config, {'warmupTopics': ''})['warmupTopics'],
        isEmpty,
      );
    },
  );
  for (var mask = 1; mask < 32; mask++) {
    test(
      'mixed family selection $mask preserves moves and return boundaries',
      () {
        final families = [
          for (var index = 0; index < warmupTypes.length; index++)
            if ((mask & (1 << index)) != 0) warmupTypes[index],
        ];
        final ids = families
            .map((type) => '$type:${warmupTopicNumbers(type).first}')
            .toList();
        final plan = warmupPlanForParams('simple-9', ids.reversed.toList());
        final frames = compilePhysicalGesturePlan(plan);
        final expectedCount = families.fold<int>(
          0,
          (sum, type) =>
              sum +
              compilePhysicalGesturePlan(
                warmupRecipe(type, [warmupTopicNumbers(type).first]),
              ).fold<int>(0, (count, frame) => count + frame.moves.length),
        );
        expect(
          frames.fold<int>(0, (sum, frame) => sum + frame.moves.length),
          expectedCount,
        );
        for (var index = 0; index < frames.length; index++) {
          if (frames[index].moves.isEmpty) {
            expect(frames[index - 1].returnAfter, true);
            expect(
              frames[index].rods.every((rod) => beadsToDigit(rod) == 0),
              true,
            );
          }
        }
        expect(plan.openingAudioKey, warmupInstructionKey);
      },
    );
  }
  test('mixed topic IDs validate, normalize and reject unknown IDs', () {
    final result = validateTrainerParams('abacus-warmup', {
      'warmupTopics': ['friends:9', 'simple-9:2', 'brothers:4'],
    });
    expect(result.params?['warmupTopics'], [
      'simple-9:2',
      'brothers:4',
      'friends:9',
    ]);
    expect(
      validateTrainerParams('abacus-warmup', {
        'warmupTopics': ['brothers:9'],
      }).ok,
      false,
    );
    expect(
      () => compilePhysicalGesturePlan(
        warmupPlanForParams('simple-9', warmupTopicIds),
      ),
      returnsNormally,
    );
  });
  test('native picker preserves mixed string IDs and group labels', () {
    final config = TrainerPlayConfig.fromJson({
      'trainerKey': 'abacus-warmup',
      'title': 'Warmup',
      'fields': [
        {
          'key': 'warmupTopics',
          'labelKey': 'warmupTopicsLabel',
          'type': 'multi-select',
          'options': [
            for (final id in ['simple-9:2', 'brothers:4', 'friends:9'])
              {'value': id, 'label': id, 'groupLabelKey': 'warmupBrothers'},
          ],
        },
      ],
    });
    expect(config.fields.single.options.first.groupLabelKey, 'warmupBrothers');
    expect(
      buildPlayParamsPayload(config, {
        'warmupTopics': 'simple-9:2,brothers:4,friends:9',
      })['warmupTopics'],
      ['simple-9:2', 'brothers:4', 'friends:9'],
    );
  });
}
