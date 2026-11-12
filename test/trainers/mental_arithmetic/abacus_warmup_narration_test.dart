import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_warmup_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_warmup_topics.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_playback.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_gesture_cues.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/runtime/validate_params.dart';
import 'package:larnes_mobile/features/admin/models/trainer_play.dart';
import 'package:larnes_mobile/trainers/audio/exercise_audio_manifest.dart';

void main() {
  for (final id in warmupTopicIds) {
    test('$id: independent speech in the full mixed selection', () {
      final parts = id.split(':');
      final plan = warmupPlanForParams('simple-9', warmupTopicIds, [id]);
      expect(() => compilePhysicalGesturePlan(plan), returnsNormally);
      final expected = physicalGestureAudioKeys(
        warmupRecipe(parts[0], [int.parse(parts[1])]),
      ).toSet();
      expect(physicalGestureAudioKeys(plan).every(expected.contains), true);
    });
  }
  test(
    'learned topics stay compact while multiple new topics are narrated',
    () {
      final ids = [
        for (final number in [1, 2, 3, 4]) 'simple-9:$number',
      ];
      final plan = warmupPlanForParams('simple-9', ids, ids.sublist(2));
      final frames = compilePhysicalGesturePlan(plan);
      expect(frames.length, 104);
      expect(
        frames
            .take(52)
            .every(
              (frame) => frame.audioKey == null && frame.tempoMultiplier == 2,
            ),
        true,
      );
      expect(
        frames.skip(52).every((frame) => frame.tempoMultiplier == 1),
        true,
      );
      expect(
        physicalGestureAudioKeys(warmupPlanForParams('simple-9', ids, [])),
        [warmupInstructionKey],
      );
      expect(
        identical(
          warmupPlanForParams('simple-9', ids, ids),
          warmupPlanForParams('simple-9', ids),
        ),
        true,
      );
    },
  );
  test('reused speech remains enabled for the other topic', () {
    fakeAsync((async) {
      final plan = warmupPlanForParams(
        'simple-9',
        ['simple-9:5', 'brothers:4'],
        ['brothers:4'],
      );
      var position = 0, done = 0;
      final calls = <(String, int)>[];
      final player = PhysicalGesturePlayer(
        plan: plan,
        speed: PhysicalGestureSpeed.fast,
        nowMs: () => async.elapsed.inMilliseconds,
        onFrame: (_, index) => position = index + 1,
        onCue: (key, _) async {
          calls.add((key, position));
        },
        onComplete: () => done++,
      );
      player.play();
      async.elapse(const Duration(minutes: 4));
      expect(done, 1);
      expect(
        calls.where((call) => call.$1 == heavenCue('right', 'down')).toList(),
        [(heavenCue('right', 'down'), 26)],
      );
      expect(calls.where((call) => call.$1 == warmupInstructionKey).length, 1);
    });
  });
  test('per-step bead and hand durations match the web scheduler', () {
    fakeAsync((async) {
      final plan = PhysicalGesturePlan(
        initialRods: [digitToBeads(0)],
        steps: [
          GroupGestureStep(
            moves: [
              PhysicalBeadMove(
                rodIndex: 0,
                to: digitToBeads(1),
                hand: AbacusHand.right,
                fingers: [AbacusFinger.thumb],
              ),
            ],
            audioKey: 'shared',
            returnAfter: true,
            pauseAfterMs: 100,
          ),
          GroupGestureStep(
            moves: [
              PhysicalBeadMove(
                rodIndex: 0,
                to: digitToBeads(0),
                hand: AbacusHand.right,
                fingers: [AbacusFinger.indexFinger],
              ),
            ],
            audioKey: 'shared',
            returnAfter: true,
            pauseAfterMs: 100,
          ),
        ],
        stepPlayback: {
          0: PhysicalGestureStepPlayback(
            narrationEnabled: false,
            tempoMultiplier: 2,
          ),
        },
      );
      final frames = <int>[], returns = <int>[], calls = <String>[];
      var done = 0;
      final player = PhysicalGesturePlayer(
        plan: plan,
        speed: PhysicalGestureSpeed.medium,
        prepareMs: 300,
        returnMs: 320,
        nowMs: () => async.elapsed.inMilliseconds,
        onPrepare: (_, _) {},
        onFrame: (_, _) {
          frames.add(async.elapsed.inMilliseconds);
        },
        onReturn: (_, _) {
          returns.add(async.elapsed.inMilliseconds);
        },
        onCue: (key, _) async {
          calls.add(key);
        },
        onComplete: () => done++,
      );
      player.play();
      async.elapse(const Duration(seconds: 3));
      expect(frames, [150, 860]);
      expect(returns, [400, 1360]);
      expect(calls, ['shared']);
      expect(done, 1);
    });
  });
  test(
    'voice configuration validates and survives the native picker payload',
    () {
      final ids = ['simple-9:1', 'simple-9:3', 'brothers:4'];
      final config = TrainerPlayConfig.fromJson({
        'trainerKey': 'abacus-warmup',
        'title': 'Warmup',
        'fields': [
          {
            'key': 'warmupTopics',
            'labelKey': 'warmupTopicsLabel',
            'type': 'multi-select',
            'selectedLabels': true,
            'optionToggleKey': 'warmupNarratedTopics',
            'optionToggleLabelKey': 'warmupTopicNarrationLabel',
            'options': [
              for (final id in ids) {'value': id, 'label': id},
            ],
          },
        ],
      });
      for (final voiced in [<String>[], ids.sublist(1)]) {
        final payload = buildPlayParamsPayload(config, {
          'warmupTopics': ids.join(','),
          'warmupNarratedTopics': voiced.join(','),
          'withExplanations': 'false',
        });
        expect(payload['warmupNarratedTopics'], voiced);
        expect(
          validateTrainerParams(
            'abacus-warmup',
            payload,
          ).params?['warmupNarratedTopics'],
          voiced,
        );
      }
      expect(config.fields.single.selectedLabels, true);
      expect(
        buildPlayParamsPayload(config, {
          'warmupTopics': ids.join(','),
          'warmupNarratedTopics': 'inherit',
        }).containsKey('warmupNarratedTopics'),
        false,
      );
      expect(
        validateTrainerParams('abacus-warmup', {
          'warmupTopics': ids,
          'warmupNarratedTopics': ['friends:9'],
        }).ok,
        false,
      );
    },
  );
  test(
    'audio scope uses the selected topic voices even with the old global flag off',
    () {
      final main = warmupInstructionKey,
          one = earthCycleCue('right', 1),
          three = earthCycleCue('right', 3);
      final manifest = ExerciseAudioManifest.fromJson({
        'trainerKey': 'abacus-warmup',
        'clips': [
          for (final key in [main, one, three])
            {
              'bytes': 10,
              'durationMs': 800,
              'locale': 'ru-RU',
              'semanticKey': key,
              'url': 'https://audio.larnes.ru/$key.mp3',
            },
        ],
      })!;
      final params = <String, dynamic>{
        'warmupTopics': ['simple-9:1', 'simple-9:3'],
        'warmupNarratedTopics': ['simple-9:3'],
        'withExplanations': false,
      };
      expect(
        scopeTrainerAudioForParams(
          manifest,
          'abacus-warmup',
          params,
        )!.clips.map((clip) => clip.semanticKey).toList(),
        [main, three],
      );
      params['warmupNarratedTopics'] = <String>[];
      expect(
        scopeTrainerAudioForParams(
          manifest,
          'abacus-warmup',
          params,
        )!.clips.map((clip) => clip.semanticKey).toList(),
        [main],
      );
    },
  );
}
