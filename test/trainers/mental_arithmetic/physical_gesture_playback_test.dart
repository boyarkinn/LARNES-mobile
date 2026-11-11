import 'dart:convert';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_abacus.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_playback.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';

final _reference =
    jsonDecode(
          File(
            'test/trainers/mental_arithmetic/physical_gesture_fixture.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

AbacusFinger _finger(String name) => name == 'index'
    ? AbacusFinger.indexFinger
    : AbacusFinger.values.byName(name);

PhysicalGesturePlan _referencePlan() {
  final steps = <PhysicalGestureStep>[];
  for (final source in _reference['steps'] as List<dynamic>) {
    final step = source as Map<String, dynamic>;
    final pauseAfterMs = step['pauseAfterMs'] as int;
    if (step['kind'] == 'group') {
      steps.add(
        GroupGestureStep(
          moves: (step['moves'] as List<dynamic>).map((source) {
            final move = source as Map<String, dynamic>;
            return PhysicalBeadMove(
              rodIndex: move['rodIndex'] as int,
              to: digitToBeads(move['toDigit'] as int),
              hand: AbacusHand.values.byName(move['hand'] as String),
              fingers: (move['fingers'] as List<dynamic>)
                  .map((name) => _finger(name as String))
                  .toList(),
            );
          }).toList(),
          pauseAfterMs: pauseAfterMs,
          audioKey: step['audioKey'] as String?,
        ),
      );
    } else {
      steps.add(
        RodPassGestureStep(
          rodIndices: List<int>.from(step['rodIndices'] as List<dynamic>),
          to: digitToBeads(step['toDigit'] as int),
          hand: AbacusHand.values.byName(step['hand'] as String),
          fingers: (step['fingers'] as List<dynamic>)
              .map((name) => _finger(name as String))
              .toList(),
          pauseAfterMs: pauseAfterMs,
        ),
      );
    }
  }
  return PhysicalGesturePlan(
    initialRods: (_reference['initialDigits'] as String)
        .split('')
        .map((digit) => digitToBeads(int.parse(digit)))
        .toList(),
    steps: steps,
  );
}

void main() {
  test('same 13-rod reference frames, simultaneous hands and rod pass', () {
    final frames = compilePhysicalGesturePlan(_referencePlan());
    expect(
      frames.map((frame) => frame.rods.map(beadsToDigit).join()).toList(),
      List<String>.from(_reference['expectedDigits'] as List<dynamic>),
    );
    expect(frames.first.moves.map((move) => move.hand).toList(), [
      AbacusHand.left,
      AbacusHand.right,
    ]);
    expect(frames.first.moves.map((move) => move.rodIndex).toList(), [0, 12]);
    expect(frames.first.audioKey, 'explanation:abacus-warmup:fixture');
    expect(frames[1].audioKey, isNull);
    expect(frames.last.moves, hasLength(2));
  });

  test('rejects invalid rods, repeated moves and no-op gestures', () {
    final initial = emptyRods(2);
    final move = PhysicalBeadMove(
      rodIndex: 0,
      to: digitToBeads(1),
      hand: AbacusHand.left,
      fingers: const [AbacusFinger.thumb],
    );
    expect(
      () => compilePhysicalGesturePlan(
        const PhysicalGesturePlan(initialRods: [], steps: []),
      ),
      throwsRangeError,
    );
    expect(
      () => compilePhysicalGesturePlan(
        PhysicalGesturePlan(
          initialRods: initial,
          steps: [
            GroupGestureStep(moves: [move, move]),
          ],
        ),
      ),
      throwsStateError,
    );
    expect(
      () => compilePhysicalGesturePlan(
        PhysicalGesturePlan(
          initialRods: initial,
          steps: [
            GroupGestureStep(
              moves: [
                PhysicalBeadMove(
                  rodIndex: 0,
                  to: digitToBeads(0),
                  hand: AbacusHand.left,
                  fingers: const [AbacusFinger.thumb],
                ),
              ],
            ),
          ],
        ),
      ),
      throwsStateError,
    );
  });

  test('speed changes both transition and pause; medium keeps 500 ms', () {
    expect(physicalGestureTiming(PhysicalGestureSpeed.slow).transitionMs, 667);
    expect(
      physicalGestureTiming(PhysicalGestureSpeed.medium).transitionMs,
      500,
    );
    expect(physicalGestureTiming(PhysicalGestureSpeed.fast).transitionMs, 333);
    expect(physicalGestureTiming(PhysicalGestureSpeed.fast).pauseMs(200), 133);
    expect(physicalGestureTiming(PhysicalGestureSpeed.slow).pauseMs(200), 267);
    expect(
      physicalGestureTiming(
        PhysicalGestureSpeed.medium,
        reducedMotion: true,
      ).transitionMs,
      0,
    );
    expect(
      physicalGestureTiming(
        PhysicalGestureSpeed.medium,
        reducedMotion: true,
      ).frameMs,
      500,
    );
  });

  test('waits for each animation, pauses, cancels and completes once', () {
    fakeAsync((clock) {
      final seen = <(int, int)>[];
      var completed = 0;
      final player = PhysicalGesturePlayer(
        plan: _referencePlan(),
        speed: PhysicalGestureSpeed.medium,
        nowMs: () => clock.elapsed.inMilliseconds,
        onFrame: (_, index) => seen.add((index, clock.elapsed.inMilliseconds)),
        onComplete: () => completed++,
      );
      player.play();
      expect(seen, [(0, 0)]);
      clock.elapse(const Duration(milliseconds: 300));
      player.pause();
      clock.elapse(const Duration(milliseconds: 1000));
      expect(seen, hasLength(1));
      player.play();
      clock.elapse(const Duration(milliseconds: 399));
      expect(seen, hasLength(1));
      clock.elapse(const Duration(milliseconds: 1));
      expect(seen[1], (1, 1700));
      clock.elapse(const Duration(milliseconds: 6600));
      expect(seen, hasLength(13));
      expect(completed, 0);
      clock.elapse(const Duration(milliseconds: 500));
      expect(completed, 1);
      clock.elapse(const Duration(seconds: 10));
      expect(completed, 1);

      final other = PhysicalGesturePlayer(
        plan: _referencePlan(),
        speed: PhysicalGestureSpeed.fast,
        nowMs: () => clock.elapsed.inMilliseconds,
        onFrame: (_, _) => completed += 10,
        onComplete: () => completed += 100,
      );
      other.play();
      expect(completed, 11);
      other.cancel();
      clock.elapse(const Duration(seconds: 10));
      expect(completed, 11);
    });
  });

  test('reduced motion removes transitions while keeping frame spacing', () {
    fakeAsync((clock) {
      final times = <int>[];
      final player = PhysicalGesturePlayer(
        plan: _referencePlan(),
        speed: PhysicalGestureSpeed.medium,
        reducedMotion: true,
        nowMs: () => clock.elapsed.inMilliseconds,
        onFrame: (_, _) => times.add(clock.elapsed.inMilliseconds),
      );
      player.play();
      expect(times, [0]);
      clock.elapse(const Duration(milliseconds: 699));
      expect(times, [0]);
      clock.elapse(const Duration(milliseconds: 1));
      expect(times[1], 700);
      clock.elapse(const Duration(milliseconds: 600));
      expect(times[2], 1300);
    });
  });

  testWidgets('shared scene applies speed and cancels on close', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PhysicalGestureAbacus(
          plan: _referencePlan(),
          speed: PhysicalGestureSpeed.fast,
          onComplete: () => completed++,
        ),
      ),
    );
    await tester.pump();
    final abacus = tester.widget<AbacusWidget>(find.byType(AbacusWidget));
    expect(abacus.beadAnimationDuration, const Duration(milliseconds: 333));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(seconds: 20));
    expect(completed, 0);
  });

  testWidgets('shared scene honors system reduced motion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: PhysicalGestureAbacus(
            plan: _referencePlan(),
            speed: PhysicalGestureSpeed.slow,
            autoPlay: false,
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<AbacusWidget>(find.byType(AbacusWidget))
          .beadAnimationDuration,
      Duration.zero,
    );
  });
}
