import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

const _stageKey = Key('trainer-stage');

Widget _stage({required double width, required double height, required Widget child}) {
  return MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          key: _stageKey,
          width: width,
          height: height,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('TrainerScene', () {
    testWidgets('fills bounded parent', (tester) async {
      await tester.pumpWidget(
        _stage(
          width: 360,
          height: 480,
          child: const TrainerScene(
            child: ColoredBox(color: Color(0xFF112233)),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byKey(_stageKey)), const Size(360, 480));
      expect(tester.getSize(find.byType(TrainerScene)), const Size(360, 480));
    });

    testWidgets('TrainerSceneFill expands child to stage size', (tester) async {
      const fillKey = Key('scene-fill');

      await tester.pumpWidget(
        _stage(
          width: 320,
          height: 400,
          child: TrainerSceneFill(
            child: ColoredBox(
              key: fillKey,
              color: const Color(0xFF445566),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byKey(fillKey)), const Size(320, 400));
    });
  });

  group('TrainerSceneColumn', () {
    testWidgets('keeps footer at bottom and expands body', (tester) async {
      const footerKey = Key('scene-footer');

      await tester.pumpWidget(
        _stage(
          width: 300,
          height: 360,
          child: TrainerSceneColumn(
            body: const Placeholder(color: Color(0xFF778899)),
            footer: Container(
              key: footerKey,
              height: 56,
              color: const Color(0xFF223344),
            ),
          ),
        ),
      );
      await tester.pump();

      final footerBox = tester.getRect(find.byKey(footerKey));
      expect(footerBox.bottom, 360);
      expect(footerBox.height, 56);

      final placeholderBox = tester.getRect(find.byType(Placeholder));
      expect(placeholderBox.top, 0);
      expect(placeholderBox.bottom, footerBox.top);
    });

    testWidgets('does not overflow with footer in tight stage', (tester) async {
      await tester.pumpWidget(
        _stage(
          width: 280,
          height: 320,
          child: TrainerSceneColumn(
            body: const Placeholder(),
            footer: Container(
              height: 48,
              color: const Color(0xFF334455),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
