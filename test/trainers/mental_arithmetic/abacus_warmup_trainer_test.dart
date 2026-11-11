import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_warmup/abacus_warmup_trainer.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_model.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';

void main() {
  testWidgets(
    'run-three scene shows only the shared abacus at selected speed',
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
      expect(rods.map(beadsToDigit).join(), '0100000000010');
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
}
