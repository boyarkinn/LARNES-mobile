import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/features/admin/models/trainer_play.dart';
import 'package:larnes_mobile/features/parent/trainers/parent_trainer_params_utils.dart';
import 'package:larnes_mobile/features/parent/trainers/parent_trainer_play_session.dart';

void main() {
  group('ParentTrainerPlaySessionStore', () {
    test('storage key mirrors web sessionStorage', () {
      expect(
        ParentTrainerPlaySessionStore.storageKey('topic-chain-flash'),
        'parent-trainer-play:topic-chain-flash',
      );
    });

    test('validates parent return paths', () {
      expect(
        ParentTrainerPlaySessionStore.isValidReturnPath(
          '/parent/child-1/trainers/mental/topic-chain-flash',
        ),
        isTrue,
      );
      expect(ParentTrainerPlaySessionStore.isValidReturnPath('https://evil.test'), isFalse);
    });
  });

  group('mergeStoredParamsIntoFormValues', () {
    test('maps topic-chain-flash params back to form fields', () {
      final config = TrainerPlayConfig.fromJson({
        'trainerKey': 'topic-chain-flash',
        'title': 'Topic chain flash',
        'direction': 'mental',
        'isInteractive': false,
        'defaultParams': {
          'actionCount': 5,
          'chainTopicId': 'simple-1',
        },
        'fields': [
          {'key': 'actionCount', 'labelKey': 'actionCountLabel', 'type': 'number'},
          {'key': 'chainTopicId', 'labelKey': 'chainTopicIdLabel', 'type': 'select', 'options': []},
        ],
      });

      final values = mergeStoredParamsIntoFormValues(config, {
        'actionCount': 7,
        'topicId': 'simple-2',
        'solveMode': 'mental',
      });

      expect(values['actionCount'], '7');
      expect(values['chainTopicId'], 'simple-2');
    });
  });
}
