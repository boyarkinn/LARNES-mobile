import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_abacus.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_example.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_playback.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';
import 'package:larnes_mobile/trainers/shared/trainer_playback_controller.dart';

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

final _explanationReference =
    jsonDecode(
          File(
            'test/trainers/mental_arithmetic/'
            'physical_gesture_explanation_fixture.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

PhysicalGesturePlan _topicParityPlan() {
  final steps = <PhysicalGestureStep>[];
  for (final raw in _explanationReference['steps'] as List<dynamic>) {
    final step = raw as Map<String, dynamic>;
    final audioKey = step['audioKey'] as String?;
    final pauseAfterMs = step['pauseAfterMs'] as int?;
    switch (step['kind']) {
      case 'narration':
        steps.add(
          NarrationGestureStep(
            audioKey: audioKey!,
            pauseAfterMs: pauseAfterMs ?? 0,
          ),
        );
      case 'pass':
        steps.add(
          RodPassGestureStep(
            rodIndices: List<int>.from(step['rodIndices'] as List<dynamic>),
            to: digitToBeads(step['toDigit'] as int),
            hand: AbacusHand.values.byName(step['hand'] as String),
            fingers: (step['fingers'] as List<dynamic>)
                .map((name) => _finger(name as String))
                .toList(),
            audioKey: audioKey,
            audioMode: step['audioMode'] == 'parallel'
                ? PhysicalGestureAudioMode.parallel
                : PhysicalGestureAudioMode.before,
            pauseAfterMs: pauseAfterMs ?? 200,
          ),
        );
      case 'group':
        steps.add(
          GroupGestureStep(
            moves: (step['moves'] as List<dynamic>).map((rawMove) {
              final move = rawMove as Map<String, dynamic>;
              return PhysicalBeadMove(
                rodIndex: move['rodIndex'] as int,
                to: digitToBeads(move['toDigit'] as int),
                hand: AbacusHand.values.byName(move['hand'] as String),
                fingers: (move['fingers'] as List<dynamic>)
                    .map((name) => _finger(name as String))
                    .toList(),
              );
            }).toList(),
            audioKey: audioKey,
            audioMode: step['audioMode'] == 'parallel'
                ? PhysicalGestureAudioMode.parallel
                : PhysicalGestureAudioMode.before,
            pauseAfterMs: pauseAfterMs ?? 200,
          ),
        );
      default:
        throw StateError('Неизвестный шаг в тестовом сценарии.');
    }
  }
  return PhysicalGesturePlan(
    initialRods: (_explanationReference['initialDigits'] as String)
        .split('')
        .map((digit) => digitToBeads(int.parse(digit)))
        .toList(),
    beadTransitionMs: 100,
    steps: steps,
  );
}

void main() {
  test('narration-only plan completes without abacus frames', () {
    fakeAsync((clock) {
      final speech = Completer<void>();
      final seen = <String>[];
      final player = PhysicalGesturePlayer(
        plan: PhysicalGesturePlan(
          initialRods: emptyRods(1),
          steps: const [
            NarrationGestureStep(audioKey: 'lesson', pauseAfterMs: 180),
          ],
        ),
        speed: PhysicalGestureSpeed.fast,
        onFrame: (_, _) => seen.add('frame'),
        onCue: (key, _) {
          seen.add(key);
          return speech.future;
        },
        onComplete: () => seen.add('complete'),
        nowMs: () => clock.elapsed.inMilliseconds,
      );
      expect(player.hasEvents, isTrue);
      expect(player.frames, isEmpty);
      player.play();
      expect(seen, ['lesson']);
      clock.elapse(const Duration(seconds: 1));
      expect(seen, ['lesson']);
      speech.complete();
      clock.flushMicrotasks();
      clock.elapse(const Duration(milliseconds: 179));
      expect(seen, ['lesson']);
      clock.elapse(const Duration(milliseconds: 1));
      expect(seen, ['lesson', 'complete']);
      expect(player.checkpointStepIndex, 1);
    });
  });

  test('narration defaults to no gap before the next gesture', () {
    fakeAsync((clock) {
      final speech = Completer<void>();
      final seen = <String>[];
      final player = PhysicalGesturePlayer(
        plan: PhysicalGesturePlan(
          initialRods: emptyRods(1),
          steps: [
            const NarrationGestureStep(audioKey: 'start'),
            GroupGestureStep(
              moves: [
                PhysicalBeadMove(
                  rodIndex: 0,
                  to: digitToBeads(1),
                  hand: AbacusHand.right,
                  fingers: const [AbacusFinger.thumb],
                ),
              ],
            ),
          ],
        ),
        speed: PhysicalGestureSpeed.medium,
        onFrame: (_, _) => seen.add('frame'),
        onCue: (_, _) {
          seen.add('speech');
          return speech.future;
        },
        nowMs: () => clock.elapsed.inMilliseconds,
      );
      player.play();
      expect(seen, ['speech']);
      speech.complete();
      clock.flushMicrotasks();
      expect(seen, ['speech', 'frame']);
      expect(clock.elapsed, Duration.zero);
    });
  });

  test('parallel pass waits for long speech before the next before cue', () {
    fakeAsync((clock) {
      final seen = <String>[];
      final pending = <String, Completer<void>>{};
      final player = PhysicalGesturePlayer(
        plan: _topicParityPlan(),
        speed: PhysicalGestureSpeed.medium,
        onFrame: (frame, _) => seen.add('frame:${abacusToNumber(frame.rods)}'),
        onCue: (key, _) {
          seen.add('cue:$key');
          final completion = Completer<void>();
          pending[key] = completion;
          return completion.future;
        },
        onComplete: () => seen.add('complete'),
        nowMs: () => clock.elapsed.inMilliseconds,
      );
      player.play();
      expect(seen, ['cue:intro']);
      expect(player.position, 0);
      pending['intro']!.complete();
      clock.flushMicrotasks();
      expect(seen, ['cue:intro', 'cue:parallel', 'frame:10']);
      expect(player.checkpointStepIndex, 1);
      clock.elapse(const Duration(milliseconds: 100));
      expect(seen.last, 'frame:11');
      clock.elapse(const Duration(milliseconds: 100));
      expect(seen.last, 'frame:11');
      expect(player.position, 2);
      expect(player.checkpointFramePosition, 0);
      pending['parallel']!.complete();
      clock.flushMicrotasks();
      expect(seen.last, 'cue:before');
      expect(player.checkpointStepIndex, 2);
      pending['before']!.complete();
      clock.flushMicrotasks();
      expect(seen.last, 'frame:12');
      clock.elapse(const Duration(milliseconds: 100));
      expect(seen.last, 'complete');
      expect(player.checkpointStepIndex, 3);
    });
  });

  test('parallel pass also waits when speech ends before its movement', () {
    fakeAsync((clock) {
      final seen = <String>[];
      final pending = <String, Completer<void>>{};
      final player = PhysicalGesturePlayer(
        plan: _topicParityPlan(),
        speed: PhysicalGestureSpeed.medium,
        onFrame: (_, index) => seen.add('frame:$index'),
        onCue: (key, _) {
          seen.add('cue:$key');
          return (pending[key] = Completer<void>()).future;
        },
        nowMs: () => clock.elapsed.inMilliseconds,
      );
      player.play();
      pending['intro']!.complete();
      clock.flushMicrotasks();
      pending['parallel']!.complete();
      clock.flushMicrotasks();
      expect(seen.last, 'frame:0');
      clock.elapse(const Duration(milliseconds: 199));
      expect(seen.last, 'frame:1');
      expect(seen, isNot(contains('cue:before')));
      clock.elapse(const Duration(milliseconds: 1));
      expect(seen.last, 'cue:before');
    });
  });

  test(
    'with hands, parallel speech starts after approach and with first bead',
    () {
      fakeAsync((clock) {
        final seen = <String>[];
        final intro = Completer<void>();
        final player = PhysicalGesturePlayer(
          plan: _topicParityPlan(),
          speed: PhysicalGestureSpeed.medium,
          prepareMs: 80,
          onPrepare: (_, index) => seen.add('prepare:$index'),
          onFrame: (_, index) => seen.add('frame:$index'),
          onCue: (key, _) {
            seen.add('cue:$key');
            return key == 'intro' ? intro.future : Completer<void>().future;
          },
          nowMs: () => clock.elapsed.inMilliseconds,
        );
        player.play();
        intro.complete();
        clock.flushMicrotasks();
        expect(seen, ['cue:intro', 'prepare:0']);
        clock.elapse(const Duration(milliseconds: 79));
        expect(seen, ['cue:intro', 'prepare:0']);
        clock.elapse(const Duration(milliseconds: 1));
        expect(seen, ['cue:intro', 'prepare:0', 'cue:parallel', 'frame:0']);
      });
    },
  );

  test('pause rewinds an unfinished parallel series and ignores old audio', () {
    fakeAsync((clock) {
      final seen = <String>[];
      final pending = <Completer<void>>[];
      final cancelled = <int>[];
      final resetValues = <int>[];
      final player = PhysicalGesturePlayer(
        plan: _topicParityPlan(),
        speed: PhysicalGestureSpeed.medium,
        onFrame: (frame, _) => seen.add('frame:${abacusToNumber(frame.rods)}'),
        onReset: (rods, _) => resetValues.add(abacusToNumber(rods)),
        onCue: (key, signal) {
          seen.add('cue:$key');
          final index = pending.length;
          signal.onCancel(() => cancelled.add(index));
          pending.add(Completer<void>());
          return pending.last.future;
        },
        nowMs: () => clock.elapsed.inMilliseconds,
      );
      player.play();
      pending[0].complete();
      clock.flushMicrotasks();
      expect(seen.last, 'frame:10');
      clock.elapse(const Duration(milliseconds: 50));
      player.pause();
      expect(cancelled, [1]);
      expect(resetValues, [0]);
      expect(player.position, 0);
      expect(player.checkpointStepIndex, 1);
      player.play();
      expect(seen.last, 'frame:10');
      expect(seen.where((item) => item == 'cue:parallel'), hasLength(2));
      pending[1].complete();
      clock.flushMicrotasks();
      clock.elapse(const Duration(milliseconds: 200));
      expect(seen, isNot(contains('cue:before')));
      pending[2].complete();
      clock.flushMicrotasks();
      expect(seen.last, 'cue:before');
      expect(seen.where((item) => item == 'frame:10'), hasLength(2));
    });
  });

  test('numeric checkpoints use shared abacus values, not speech text', () {
    final plan = _topicParityPlan();
    expect(
      compilePhysicalGesturePlan(
        plan,
      ).map((frame) => abacusToNumber(frame.rods)).toList(),
      List<int>.from(_explanationReference['expectedValues'] as List<dynamic>),
    );
    expect(physicalGestureAudioKeys(plan), ['intro', 'parallel', 'before']);
    expect(
      () => validatePhysicalGestureExample(plan, const [
        PhysicalGestureCheckpoint(afterFrame: 0, value: 0),
        PhysicalGestureCheckpoint(afterFrame: 1, value: 10),
        PhysicalGestureCheckpoint(afterFrame: 2, value: 11),
        PhysicalGestureCheckpoint(afterFrame: 3, value: 12),
      ]),
      returnsNormally,
    );
    expect(
      () => validatePhysicalGestureExample(plan, const [
        PhysicalGestureCheckpoint(afterFrame: 2, value: 12),
      ]),
      throwsStateError,
    );
    expect(
      () => validatePhysicalGestureExample(plan, const [
        PhysicalGestureCheckpoint(afterFrame: 4, value: 12),
      ]),
      throwsRangeError,
    );
    expect(
      () => compilePhysicalGesturePlan(
        PhysicalGesturePlan(
          initialRods: emptyRods(1),
          steps: [
            GroupGestureStep(
              moves: [
                PhysicalBeadMove(
                  rodIndex: 0,
                  to: digitToBeads(1),
                  hand: AbacusHand.right,
                  fingers: const [AbacusFinger.thumb],
                ),
              ],
              audioMode: PhysicalGestureAudioMode.parallel,
            ),
          ],
        ),
      ),
      throwsStateError,
    );
  });

  test(
    'speech completes before movement and closing cancels the active cue',
    () {
      fakeAsync((clock) {
        final seen = <String>[];
        final pending = <String, Completer<void>>{};
        final cancelled = <String>[];
        final plan = PhysicalGesturePlan(
          initialRods: emptyRods(2),
          openingAudioKey: 'intro',
          steps: [
            GroupGestureStep(
              moves: [
                PhysicalBeadMove(
                  rodIndex: 0,
                  to: digitToBeads(1),
                  hand: AbacusHand.right,
                  fingers: const [AbacusFinger.thumb],
                ),
              ],
              audioKey: 'first',
            ),
            GroupGestureStep(
              moves: [
                PhysicalBeadMove(
                  rodIndex: 1,
                  to: digitToBeads(1),
                  hand: AbacusHand.left,
                  fingers: const [AbacusFinger.thumb],
                ),
              ],
              audioKey: 'second',
            ),
          ],
        );
        final player = PhysicalGesturePlayer(
          plan: plan,
          speed: PhysicalGestureSpeed.medium,
          nowMs: () => clock.elapsed.inMilliseconds,
          onFrame: (_, index) => seen.add('frame:$index'),
          onCue: (key, signal) {
            seen.add('cue:$key');
            signal.onCancel(() => cancelled.add(key));
            final done = Completer<void>();
            pending[key] = done;
            return done.future;
          },
        );
        player.play();
        clock.flushMicrotasks();
        expect(seen, ['cue:intro']);
        pending['intro']!.complete();
        clock.flushMicrotasks();
        expect(seen, ['cue:intro', 'cue:first']);
        pending['first']!.complete();
        clock.flushMicrotasks();
        expect(seen, ['cue:intro', 'cue:first', 'frame:0']);
        clock.elapse(const Duration(milliseconds: 700));
        clock.flushMicrotasks();
        expect(seen.last, 'cue:second');
        player.cancel();
        expect(cancelled, ['second']);
        pending['second']!.complete();
        clock.flushMicrotasks();
        clock.elapse(const Duration(seconds: 2));
        expect(player.position, 1);
        expect(player.status, TrainerPlaybackStatus.cancelled);
      });
    },
  );

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

  test('hand preparation precedes the bead frame without moving beads', () {
    fakeAsync((clock) {
      final seen = <String>[];
      final plan = PhysicalGesturePlan(
        initialRods: emptyRods(1),
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
          ),
        ],
      );
      final player = PhysicalGesturePlayer(
        plan: plan,
        speed: PhysicalGestureSpeed.medium,
        onPrepare: (_, _) => seen.add('prepare'),
        onFrame: (_, _) => seen.add('move'),
        nowMs: () => clock.elapsed.inMilliseconds,
      );
      player.play();
      expect(seen, ['prepare']);
      expect(player.position, 0);
      clock.elapse(const Duration(milliseconds: 119));
      expect(seen, ['prepare']);
      clock.elapse(const Duration(milliseconds: 1));
      expect(seen, ['prepare', 'move']);
      expect(player.position, 1);
    });
  });

  test('return waits for the bead and finishes before the next series', () {
    fakeAsync((clock) {
      final seen = <String>[];
      final plan = PhysicalGesturePlan(
        initialRods: emptyRods(2),
        steps: [
          GroupGestureStep(
            moves: [
              PhysicalBeadMove(
                rodIndex: 0,
                to: digitToBeads(1),
                hand: AbacusHand.right,
                fingers: const [AbacusFinger.thumb],
              ),
            ],
            pauseAfterMs: 900,
            returnAfter: true,
          ),
          GroupGestureStep(
            moves: [
              PhysicalBeadMove(
                rodIndex: 1,
                to: digitToBeads(1),
                hand: AbacusHand.left,
                fingers: const [AbacusFinger.thumb],
              ),
            ],
            pauseAfterMs: 0,
            returnAfter: true,
          ),
        ],
      );
      final player = PhysicalGesturePlayer(
        plan: plan,
        speed: PhysicalGestureSpeed.medium,
        onPrepare: (_, index) => seen.add('prepare:$index'),
        onFrame: (_, index) => seen.add('move:$index'),
        onReturn: (_, index) => seen.add('return:$index'),
        onComplete: () => seen.add('complete'),
        nowMs: () => clock.elapsed.inMilliseconds,
      );
      player.play();
      expect(seen, ['prepare:0']);
      clock.elapse(const Duration(milliseconds: 120));
      expect(seen, ['prepare:0', 'move:0']);
      clock.elapse(const Duration(milliseconds: 500));
      expect(seen.last, 'return:0');
      clock.elapse(const Duration(milliseconds: 899));
      expect(seen.last, 'return:0');
      clock.elapse(const Duration(milliseconds: 1));
      expect(seen.last, 'prepare:1');
      clock.elapse(const Duration(milliseconds: 120));
      expect(seen.last, 'move:1');
      clock.elapse(const Duration(milliseconds: 500));
      expect(seen.last, 'return:1');
      clock.elapse(const Duration(milliseconds: 320));
      expect(seen.last, 'complete');
    });
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

  testWidgets('shared scene completes a narration-only plan', (tester) async {
    final speech = Completer<void>();
    final seen = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: PhysicalGestureAbacus(
          plan: PhysicalGesturePlan(
            initialRods: emptyRods(1),
            steps: const [
              NarrationGestureStep(audioKey: 'only', pauseAfterMs: 90),
            ],
          ),
          speed: PhysicalGestureSpeed.fast,
          onCue: (key, _) {
            seen.add(key);
            return speech.future;
          },
          onComplete: () => seen.add('complete'),
        ),
      ),
    );
    await tester.pump();
    expect(seen, ['only']);
    speech.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 89));
    expect(seen, ['only']);
    await tester.pump(const Duration(milliseconds: 1));
    expect(seen, ['only', 'complete']);
  });

  testWidgets('speed change restarts the unconfirmed parallel block', (
    tester,
  ) async {
    final plan = PhysicalGesturePlan(
      initialRods: emptyRods(1),
      beadTransitionMs: 300,
      steps: [
        GroupGestureStep(
          moves: [
            PhysicalBeadMove(
              rodIndex: 0,
              to: digitToBeads(1),
              hand: AbacusHand.right,
              fingers: const [AbacusFinger.thumb],
            ),
          ],
          audioMode: PhysicalGestureAudioMode.parallel,
          audioKey: 'parallel',
          pauseAfterMs: 0,
        ),
      ],
    );
    final speech = <Completer<void>>[];
    var cancelled = 0;
    var completed = 0;
    Future<void> onCue(String _, GestureCueSignal signal) {
      final done = Completer<void>();
      speech.add(done);
      signal.onCancel(() => cancelled++);
      return done.future;
    }

    Widget scene(PhysicalGestureSpeed speed) => MaterialApp(
      home: PhysicalGestureAbacus(
        plan: plan,
        speed: speed,
        onCue: onCue,
        onComplete: () => completed++,
      ),
    );
    await tester.pumpWidget(scene(PhysicalGestureSpeed.slow));
    await tester.pump();
    expect(speech, hasLength(1));
    expect(
      beadsToDigit(
        tester.widget<AbacusWidget>(find.byType(AbacusWidget)).rods.single,
      ),
      1,
    );
    await tester.pumpWidget(scene(PhysicalGestureSpeed.fast));
    await tester.pump();
    expect(cancelled, 1);
    expect(speech, hasLength(2));
    speech.first.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(completed, 0);
    speech.last.complete();
    await tester.pump();
    expect(completed, 1);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(cancelled, 1);
  });
}
