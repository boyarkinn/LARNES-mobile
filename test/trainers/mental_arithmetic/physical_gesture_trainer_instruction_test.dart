import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/audio/speech_bank.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_abacus.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_plan.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_playback.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/physical_gesture_trainer.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';

void main() {
  for (final opening in [true, false]) {
    testWidgets(
      'standard instruction holds ${opening ? 'warmup' : 'topic'} until audio ends and ignores the original opening cue',
      (tester) async {
        const instructionKey = 'instruction:abacus-test';
        const sourceKey = 'explanation:abacus-test:intro';
        const text = 'Topic. Simple one.';
        final release = Completer<void>();
        const channel = MethodChannel('com.ryanheise.just_audio.methods');
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            if (call.method == 'init') {
              await release.future;
              throw PlatformException(code: 'test-optional-audio-fallback');
            }
            return <String, dynamic>{};
          },
        );
        setSpeechAudioFiles({
          instructionKey: const SpeechAudioFile(
            path: '/cache/existing.mp3',
            text: text,
            locale: 'en-US',
            durationMs: 1000,
          ),
        });
        addTearDown(() {
          if (!release.isCompleted) release.complete();
          setSpeechAudioFiles(const {});
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            null,
          );
        });
        final plan = PhysicalGesturePlan(
          initialRods: const [RodState(heavenUp: false, earthCount: 0)],
          openingAudioKey: opening ? sourceKey : null,
          steps: [
            if (!opening) const NarrationGestureStep(audioKey: sourceKey),
            const NarrationGestureStep(audioKey: 'explanation:content'),
          ],
        );
        final calls = <String>[];
        Widget scene(PhysicalGestureSpeed speed) => MaterialApp(
          home: Scaffold(
            body: PhysicalGestureTrainer(
              plan: plan,
              speed: speed,
              instructionKey: instructionKey,
              onCue: (key, _) async => calls.add(key),
            ),
          ),
        );
        await tester.pumpWidget(scene(PhysicalGestureSpeed.fast));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(TrainerInstructionScene), findsOneWidget);
        final body = find.byType(PhysicalGestureAbacus, skipOffstage: false);
        expect(tester.widget<PhysicalGestureAbacus>(body).autoPlay, isFalse);
        expect(
          find.textContaining('Topic', findRichText: true),
          findsOneWidget,
        );
        expect(calls, isEmpty);
        final signal = GestureCueSignal();
        await tester.widget<PhysicalGestureAbacus>(body).onCue!(
          sourceKey,
          signal,
        );
        expect(calls, isEmpty);
        await tester.pumpWidget(scene(PhysicalGestureSpeed.slow));
        expect(find.byType(TrainerInstructionScene), findsOneWidget);
        expect(tester.widget<PhysicalGestureAbacus>(body).autoPlay, isFalse);
        await tester.pumpWidget(const SizedBox.shrink());
        release.complete();
        await tester.pump(const Duration(seconds: 4));
        await tester.pump();
      },
    );
  }
}
