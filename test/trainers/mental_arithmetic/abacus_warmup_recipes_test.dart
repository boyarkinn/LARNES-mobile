import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_warmup/recipes.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_gesture_cues.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_playback.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/trainer_playback_controller.dart';

final _checkpoints =
    jsonDecode(
          File(
            'test/trainers/mental_arithmetic/abacus_warmup_recipe_checkpoints.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

String _digits(List<RodState> rods) => rods.map(beadsToDigit).join();

String _fingerName(AbacusFinger finger) =>
    finger == AbacusFinger.indexFinger ? 'index' : finger.name;

String _frameDigest(List<PhysicalGestureFrame> frames) {
  final lines = frames
      .map((frame) {
        final moves = frame.moves
            .map(
              (move) =>
                  '${move.rodIndex}:${beadsToDigit(move.to)}:${move.hand.name}:${move.fingers.map(_fingerName).join('+')}',
            )
            .join(',');
        return '${_digits(frame.rods)}|$moves|${frame.pauseAfterMs}';
      })
      .join('\n');
  return sha256.convert(utf8.encode(lines)).toString();
}

void main() {
  for (final type in _checkpoints.keys) {
    for (final speed in PhysicalGestureSpeed.values) {
      test(
        '$type/${speed.name}: silent practice retains all frames and finishes once',
        () {
          fakeAsync((clock) {
            final plan = warmupRecipe(type);
            final frames = <PhysicalGestureFrame>[];
            var completions = 0;
            var completedAt = Duration.zero;
            final player = PhysicalGesturePlayer(
              plan: plan,
              speed: speed,
              tempoMultiplier: 2,
              prepareMs: 300,
              onPrepare: (_, _) {},
              onReturn: (_, _) {},
              onFrame: (frame, _) => frames.add(frame),
              onComplete: () {
                completions++;
                completedAt = clock.elapsed;
              },
              nowMs: () => clock.elapsed.inMilliseconds,
            );
            player.play();
            clock.elapse(const Duration(seconds: 160));
            expect(completions, 1);
            expect(
              _frameDigest(frames),
              _frameDigest(compilePhysicalGesturePlan(plan)),
            );
            if (speed == PhysicalGestureSpeed.medium) {
              expect(
                completedAt.inMilliseconds,
                inInclusiveRange(50000, 115000),
              );
            }
          });
        },
      );
    }
  }
  for (final type in _checkpoints.keys) {
    test(
      '$type matches the reference states and full Web/Flutter sequence',
      () {
        final plan = warmupRecipe(type);
        final frames = compilePhysicalGesturePlan(plan);
        final expected = _checkpoints[type] as Map<String, dynamic>;
        expect(plan.initialRods, hasLength(13));
        expect(_digits(plan.initialRods), '0000000000000');
        expect(frames, hasLength(expected['frameCount'] as int));
        final positions = expected['checkpoints'] as Map<String, dynamic>;
        for (final entry in positions.entries) {
          expect(
            _digits(frames[int.parse(entry.key) - 1].rods),
            entry.value,
            reason: '$type frame ${entry.key}',
          );
        }
        expect(_frameDigest(frames), expected['sha256']);
        final cues = [
          warmupIntroCue(type),
          ...frames.map((frame) => frame.audioKey),
        ].whereType<String>().join('\n');
        expect(
          sha256.convert(utf8.encode(cues)).toString(),
          expected['cueSha256'],
        );
        expect(identical(warmupRecipe(type), plan), isTrue);
      },
    );
  }

  test('keeps finger, direction and simultaneous-motion details', () {
    final right = compilePhysicalGesturePlan(warmupRecipe('simple-9'));
    final left = compilePhysicalGesturePlan(warmupRecipe('simple-tens'));
    expect(right.first.moves.single.rodIndex, 12);
    expect(right.first.moves.single.hand, AbacusHand.right);
    expect(right.first.moves.single.fingers, [AbacusFinger.thumb]);
    expect(left.first.moves.single.rodIndex, 0);
    expect(left.first.moves.single.hand, AbacusHand.left);
    for (var digit = 1; digit <= 9; digit++) {
      expect(
        _digits(right[digit * 26 - 14].rods),
        List.filled(13, '$digit').join(),
      );
      expect(
        _digits(left[digit * 26 - 14].rods),
        List.filled(13, '$digit').join(),
      );
      expect(_digits(right[digit * 26 - 1].rods), List.filled(13, '0').join());
    }

    final twoDigit = compilePhysicalGesturePlan(warmupRecipe('simple-2digit'));
    expect(twoDigit.first.moves.map((move) => move.rodIndex).toList(), [0, 12]);
    expect(twoDigit.first.moves.map((move) => move.hand).toList(), [
      AbacusHand.left,
      AbacusHand.right,
    ]);
    expect(twoDigit.every((frame) => beadsToDigit(frame.rods[6]) == 0), isTrue);

    final brothers = compilePhysicalGesturePlan(warmupRecipe('brothers'));
    expect(brothers[13].moves.single.to, digitToBeads(1));
    expect(brothers[13].moves.single.fingers, [
      AbacusFinger.thumb,
      AbacusFinger.indexFinger,
    ]);
    expect(brothers[221].moves.map((move) => move.hand).toList(), [
      AbacusHand.left,
      AbacusHand.right,
    ]);

    final friends = compilePhysicalGesturePlan(warmupRecipe('friends'));
    expect(friends[3].moves.map((move) => move.rodIndex).toList(), [1, 2]);
    expect(friends[3].moves.map((move) => beadsToDigit(move.to)).toList(), [
      0,
      1,
    ]);
    expect(friends[104].moves.map((move) => beadsToDigit(move.to)).toList(), [
      0,
      9,
    ]);
  });

  test('hands return after each spoken series, not between friend pairs', () {
    final simple = compilePhysicalGesturePlan(warmupRecipe('simple-9'));
    expect(simple.where((frame) => frame.returnAfter), hasLength(18));
    expect(simple[12].returnAfter, isTrue);
    expect(simple[25].returnAfter, isTrue);
    expect(simple[11].returnAfter, isFalse);

    final friends = compilePhysicalGesturePlan(warmupRecipe('friends'));
    expect(friends[2].returnAfter, isTrue);
    expect(friends[8].returnAfter, isFalse);
    expect(friends[14].returnAfter, isTrue);
    expect(friends.where((frame) => frame.returnAfter), hasLength(10));
  });

  test('keeps the video rhythm and scales every recipe movement', () {
    for (final type in _checkpoints.keys) {
      final base = type == 'simple-9' || type == 'simple-tens' ? 400 : 500;
      final plan = warmupRecipe(type);
      expect(
        physicalGestureTiming(
          PhysicalGestureSpeed.medium,
          baseTransitionMs: plan.beadTransitionMs ?? 500,
        ).transitionMs,
        base,
      );
      expect(
        physicalGestureTiming(
          PhysicalGestureSpeed.slow,
          baseTransitionMs: plan.beadTransitionMs ?? 500,
        ).transitionMs,
        (base / 0.75).round(),
      );
      expect(
        physicalGestureTiming(
          PhysicalGestureSpeed.fast,
          baseTransitionMs: plan.beadTransitionMs ?? 500,
        ).transitionMs,
        (base / 1.5).round(),
      );
    }
  });

  test('every scenario completes once after its last animation', () {
    for (final type in _checkpoints.keys) {
      fakeAsync((clock) {
        var count = 0;
        var lastFrameAt = -1;
        var completeAt = -1;
        var completions = 0;
        final player = PhysicalGesturePlayer(
          plan: warmupRecipe(type),
          speed: PhysicalGestureSpeed.fast,
          nowMs: () => clock.elapsed.inMilliseconds,
          onFrame: (_, _) {
            count++;
            lastFrameAt = clock.elapsed.inMilliseconds;
          },
          onComplete: () {
            completions++;
            completeAt = clock.elapsed.inMilliseconds;
          },
        );
        player.play();
        clock.elapse(const Duration(seconds: 1000));
        expect(
          count,
          (_checkpoints[type] as Map<String, dynamic>)['frameCount'],
        );
        expect(completions, 1);
        expect(
          completeAt - lastFrameAt,
          physicalGestureTiming(
            PhysicalGestureSpeed.fast,
            baseTransitionMs: warmupRecipe(type).beadTransitionMs ?? 500,
          ).transitionMs,
        );
        expect(player.status, TrainerPlaybackStatus.complete);
        clock.elapse(const Duration(seconds: 1000));
        expect(completions, 1);
      });
    }
  });
}
