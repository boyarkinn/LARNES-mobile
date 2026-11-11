import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_warmup/abacus_warmup_trainer.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/shared/abacus_hand_layer.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';

void main() {
  testWidgets(
    'warmup reserves both hand positions before the first bead moves',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AbacusWarmupTrainer(
              params: {'warmupType': 'friends', 'speed': 'fast'},
            ),
          ),
        ),
      );

      expect(find.byType(AbacusWidget), findsOneWidget);
      expect(find.byType(AbacusHandLayer), findsOneWidget);
      for (final side in ['left', 'right']) {
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Image &&
                widget.image is AssetImage &&
                (widget.image as AssetImage).assetName ==
                    'assets/animations/hand-idle-$side.png',
          ),
          findsOneWidget,
        );
      }
      expect(
        tester
            .widget<AbacusWidget>(find.byType(AbacusWidget))
            .beadAnimationDuration,
        const Duration(milliseconds: 333),
      );
      expect(find.byType(Text), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      await tester.pump();
      final rods = tester.widget<AbacusWidget>(find.byType(AbacusWidget)).rods;
      expect(rods.map(beadsToDigit).join(), '0000000000000');
    },
  );

  testWidgets('simple sweep uses its video rhythm at medium speed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AbacusWarmupTrainer(
            params: {'warmupType': 'simple-9', 'speed': 'medium'},
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<AbacusWidget>(find.byType(AbacusWidget))
          .beadAnimationDuration,
      const Duration(milliseconds: 400),
    );
  });

  testWidgets('landscape hands leave the abacus area at the screen edge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AbacusWarmupTrainer(params: {'warmupType': 'simple-9'}),
        ),
      ),
    );

    final viewport = tester.getRect(find.byType(AbacusWarmupTrainer));
    final abacus = tester.getRect(find.byType(AbacusWidget));
    final leftFist = tester.getRect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/animations/hand-idle-left.png',
      ),
    );
    expect(abacus.width, greaterThan(viewport.width * 0.9));
    expect(leftFist.bottom, greaterThanOrEqualTo(viewport.bottom));
  });

  testWidgets('portrait fists reach the bottom while the abacus stays visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AbacusWarmupTrainer(params: {'warmupType': 'simple-9'}),
        ),
      ),
    );

    final viewport = tester.getRect(find.byType(AbacusWarmupTrainer));
    final abacus = tester.getRect(find.byType(AbacusWidget));
    final leftFist = tester.getRect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/animations/hand-idle-left.png',
      ),
    );
    expect(abacus.top, greaterThanOrEqualTo(viewport.top));
    expect(abacus.bottom, lessThan(viewport.bottom));
    expect(leftFist.bottom, closeTo(viewport.bottom, 1));
  });
}
