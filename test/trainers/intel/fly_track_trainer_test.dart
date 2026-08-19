import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/fly_track_grid.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/fly_track_trainer.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/fly_track_phase.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/model.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

void main() {
  group('FlyTrackTrainer', () {
    testWidgets('starts in instruction phase inside TrainerScene', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: FlyTrackTrainer(
                params: {
                  'gridSize': 4,
                  'rounds': 1,
                  'stepCount': 3,
                  'stepPauseSec': 0.5,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(TrainerScene), findsOneWidget);
      expect(find.byType(FlyTrackGrid), findsNothing);
      expect(find.text('3'), findsNothing);
      expect(find.text('СТАРТ'), findsNothing);
    });

    testWidgets('bottom row cells stay inside the square field', (tester) async {
      const fieldKey = Key('fly-track-grid-field');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: FlyTrackGrid(
                fireworksKey: 0,
                gridSize: 3,
                onCellSelect: (_) {},
                phase: FlyTrackPhase.answer,
                round: generateFlyTrackRound(
                  GenerateFlyTrackRoundInput(
                    gridSize: 3,
                    stepCount: 2,
                    random: seededRandom(1),
                  ),
                ),
                selectedCell: null,
                visibleCell: const FlyCell(row: 1, column: 1),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final fieldRect = tester.getRect(find.byKey(fieldKey));
      final bottomLeftCell = tester.getRect(find.byKey(const ValueKey('2:0')));

      expect(fieldRect.bottom, greaterThanOrEqualTo(bottomLeftCell.bottom));
      expect(fieldRect.left, lessThanOrEqualTo(bottomLeftCell.left));
      expect(fieldRect.right, greaterThanOrEqualTo(bottomLeftCell.right));
    });

    testWidgets('fills bounded stage', (tester) async {
      const stageKey = Key('fly-stage');

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              key: stageKey,
              width: 320,
              height: 480,
              child: FlyTrackTrainer(
                params: {
                  'gridSize': 3,
                  'rounds': 1,
                  'stepCount': 2,
                  'stepPauseSec': 0.5,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byKey(stageKey)), const Size(320, 480));
      expect(tester.getSize(find.byType(TrainerScene)), const Size(320, 480));
    });
  });

  group('fly-track scene QA (progon 1.3)', () {
    test('trainer implements web session phases and timings', () {
      final trainerSource =
          File('lib/trainers/intel/fly_track/fly_track_trainer.dart')
              .readAsStringSync();
      final gridSource =
          File('lib/trainers/intel/fly_track/fly_track_grid.dart')
              .readAsStringSync();

      expect(trainerSource, contains('FlyTrackPhase.instruction'));
      expect(trainerSource, contains('FlyTrackPhase.countdown'));
      expect(trainerSource, contains('FlyTrackPhase.tracking'));
      expect(trainerSource, contains('FlyTrackPhase.answer'));
      expect(trainerSource, contains('FlyTrackPhase.replay'));
      expect(trainerSource, contains('FlyTrackPhase.feedback'));
      expect(trainerSource, contains('_countdownStepMs = 750'));
      expect(trainerSource, contains('_feedbackMs = 1600'));
      expect(trainerSource, contains('includeFlyMoved: stepIndex == 0'));
      expect(trainerSource, contains('getFlyTrackReplayAudioAssets'));
      expect(trainerSource, contains('_fireworksKey'));
      expect(gridSource, contains('AnswerFireworksBurst'));
      expect(gridSource, contains('FlyGlyph'));
    });
  });
}
