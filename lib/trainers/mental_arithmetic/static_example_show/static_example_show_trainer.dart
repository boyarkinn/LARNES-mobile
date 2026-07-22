import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/example_logic.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/move_hints.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/static_example_scene.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

/// Web v2: `platform/src/trainers/mental-arithmetic/static-example-show/component.tsx`
class StaticExampleShowTrainer extends StatelessWidget {
  const StaticExampleShowTrainer({
    super.key,
    required this.params,
  });

  final Map<String, dynamic> params;

  @override
  Widget build(BuildContext context) {
    final operation = params['operation'] as String? ?? 'add';
    final operandA = params['operandA'] as int? ?? 0;
    final operandB = params['operandB'] as int? ?? 0;
    final totalRods = params['totalRods'] as int? ?? 1;

    final values = resolveStaticExampleAbacusValues(
      operation: operation,
      operandA: operandA,
      operandB: operandB,
    );
    final expression = formatStaticExampleExpression(
      operation: operation,
      operandA: operandA,
      operandB: operandB,
    );
    final moveOverlays = resolveMoveOverlays(
      operation: operation,
      operandA: operandA,
      operandB: operandB,
      totalRods: totalRods,
    );

    return TrainerScene(
      child: ColoredBox(
        color: Colors.white,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight * 0.72;
            final maxWidth = constraints.maxWidth * 0.96;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: maxHeight,
                  maxWidth: maxWidth,
                ),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: StaticExampleScene(
                    expression: expression,
                    leftValue: values.leftValue,
                    rightValue: values.rightValue,
                    totalRods: totalRods,
                    moveOverlays: moveOverlays,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
