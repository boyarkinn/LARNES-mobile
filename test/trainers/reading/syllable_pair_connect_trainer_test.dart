import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/syllable_pair_connect/syllable_pair_connect_model.dart';
import 'package:larnes_mobile/trainers/runtime/runtime_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/reading/syllable_pair_connect/syllable_pair_connect_trainer.dart';
import 'package:larnes_mobile/trainers/shared/match_connection/connection_lines_painter.dart';
import 'package:larnes_mobile/trainers/shared/instruction/trainer_instruction_scene.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/audio/clip_player.dart';

void main() {
  testWidgets('wrong tap pair retries, both methods finish only after the last pair', (tester) async {
    var completed = 0;
    final keys = buildSyllablePairRound(practiceLetters: 'А,О', pairCount: 2, letterCase: 'upper', rng: TrainerSnapshotRandom(42).nextDouble).letters.map((token) => token.pairKey).toSet().toList();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox(
      width: 390, height: 640,
      child: SyllablePairConnectTrainer(params: const {'practiceLetters': 'А,О', 'pairCount': 2, '__runtimeSnapshot': {'version': 1, 'trainerKey': 'syllable-pair-connect', 'mode': 'materialized', 'payload': {'seed': 42}}}, onComplete: () => completed++),
    ))));
    await tester.pump();
    expect(find.byType(TrainerInstructionScene), findsOneWidget);
    expect(find.byKey(ValueKey('pair-${keys[0]}-0')), findsNothing);
    expect(completed, 0);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(find.byType(TrainerInstructionScene), findsOneWidget);
    final instruction = tester.widget<TrainerInstructionScene>(find.byType(TrainerInstructionScene));
    expect(instruction.length, instruction.text.length);
    expect(find.byKey(ValueKey('pair-${keys[0]}-0')), findsNothing);
    await tester.pump(const Duration(milliseconds: 999));
    expect(find.byType(TrainerInstructionScene), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byType(TrainerInstructionScene), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));
    Finder glyph(String id) => find.byKey(ValueKey('pair-$id'));
    MatchConnectionLinesPainter painter() => tester.widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter).whereType<MatchConnectionLinesPainter>().single;

    await tester.tap(glyph('${keys[0]}-0'));
    await tester.pump();
    await tester.tap(glyph('${keys[1]}-0'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(painter().lockedLines, isEmpty);
    expect(painter().circleCutouts, isEmpty);
    expect(find.byKey(ValueKey('pair-circle-${keys[0]}-0')), findsNothing);
    expect(find.byKey(ValueKey('pair-circle-${keys[1]}-0')), findsNothing);
    final red = tester.widgetList<Text>(find.byType(Text)).where((text) => text.style?.color == const Color(0xFFDC2626));
    expect(red.length, 2);
    expect(completed, 0);
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(glyph('${keys[0]}-0'));
    await tester.pump();
    await tester.tap(glyph('${keys[0]}-1'));
    await tester.pump(const Duration(seconds: 1));
    expect(painter().lockedLines.length, 1);
    expect(painter().circleCutouts.length, 2);
    expect(painter().lockedLines.single.stroke, const Color(0xFF22C55E));
    expect(painter().lockedLines.single.path, isNotNull);
    final circle = tester.widget<DecoratedBox>(find.byKey(ValueKey('pair-circle-${keys[0]}-0')));
    expect(((circle.decoration as BoxDecoration).border! as Border).top.color, painter().lockedLines.single.stroke);
    expect(find.byKey(ValueKey('pair-circle-${keys[0]}-1')), findsOneWidget);
    expect(find.byKey(ValueKey('pair-circle-${keys[1]}-0')), findsNothing);
    expect(completed, 0);
    expect(glyph('${keys[0]}-0'), findsOneWidget);

    await tester.dragFrom(tester.getCenter(glyph('${keys[1]}-0')), tester.getCenter(glyph('${keys[1]}-1')) - tester.getCenter(glyph('${keys[1]}-0')));
    await tester.pump(const Duration(seconds: 1));
    expect(painter().lockedLines.length, 2);
    expect(completed, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox());
    await resetSharedClipPlayerForTests();
  });
}
