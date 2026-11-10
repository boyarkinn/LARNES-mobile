import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/abacus_warmup/abacus_warmup_trainer.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';

void main() {
  testWidgets('run-one scene shows only the stationary shared abacus', (
    tester,
  ) async {
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
    expect(find.byType(Text), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
  });
}
