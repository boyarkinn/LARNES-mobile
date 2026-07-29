import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/admin/models/trainer_play.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/generate.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/chain_generator/types.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';

class _RegressionCase {
  const _RegressionCase({
    required this.topicId,
    required this.actionCount,
    required this.signMode,
    required this.stepPauseSec,
  });

  final String topicId;
  final int actionCount;
  final String signMode;
  final double stepPauseSec;
}

const _regressionCases = [
  _RegressionCase(
    topicId: 'simple-1',
    actionCount: 5,
    signMode: 'mix',
    stepPauseSec: 1,
  ),
  _RegressionCase(
    topicId: 'simple-2digit',
    actionCount: 5,
    signMode: 'add',
    stepPauseSec: 0.5,
  ),
  _RegressionCase(
    topicId: 'brother-4-1digit',
    actionCount: 5,
    signMode: 'mix',
    stepPauseSec: 1,
  ),
  _RegressionCase(
    topicId: 'friend-9-1digit',
    actionCount: 5,
    signMode: 'mix',
    stepPauseSec: 1,
  ),
];

void main() {
  group('topic-chain-flash QA regression', () {
    for (final params in _regressionCases) {
      test('validates + generates for ${params.topicId}', () {
        final validated = validateTrainerParams('topic-chain-flash', {
          'topicId': params.topicId,
          'actionCount': params.actionCount,
          'signMode': params.signMode,
          'stepPauseSec': params.stepPauseSec,
        });

        expect(validated.ok, isTrue, reason: validated.error);

        final chain = generateChain(
          GenerateConfig(
            topicId: params.topicId,
            actionCount: params.actionCount,
            signMode: params.signMode,
          ),
        );

        expect(chain.steps, hasLength(params.actionCount));
        expect(chain.intermediates.first, 0);
        expect(chain.intermediates.last, chain.answer);
        expect(chain.answer, greaterThanOrEqualTo(0));
      });
    }
  });

  group('topic-chain-flash homework smoke', () {
    test('maps chainTopicId form payload and validates', () {
      final config = TrainerPlayConfig.fromJson({
        'status': 'success',
        'trainerKey': 'topic-chain-flash',
        'title': 'Chain flash',
        'direction': 'mental',
        'isInteractive': true,
        'defaultParams': const {},
        'fields': const [],
      });

      final payload = buildPlayParamsPayload(config, {
        'chainTopicId': 'friend-9-1digit',
        'actionCount': '5',
        'signMode': 'mix',
        'stepPauseSec': '1',
      });

      final validated = validateTrainerParams('topic-chain-flash', payload);
      expect(validated.ok, isTrue, reason: validated.error);
    });

    test('rejects unknown topic', () {
      final result = validateTrainerParams('topic-chain-flash', {
        'topicId': 'nope',
        'actionCount': 5,
        'signMode': 'mix',
        'stepPauseSec': 1,
      });
      expect(result.ok, isFalse);
    });
  });
}
