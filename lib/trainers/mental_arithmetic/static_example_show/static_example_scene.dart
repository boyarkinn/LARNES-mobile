import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/example_bridge.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/move_hints.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/static_example_show/static_abacus_widget.dart';

/// Web v2: `static-example-show/component.tsx` — row of two abacuses + bridge.
class StaticExampleScene extends StatelessWidget {
  const StaticExampleScene({
    super.key,
    required this.expression,
    required this.leftValue,
    required this.rightValue,
    required this.totalRods,
    required this.moveOverlays,
  });

  final String expression;
  final int leftValue;
  final int rightValue;
  final int totalRods;
  final List<MoveOverlay> moveOverlays;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedStaticAbacusValue(
          value: leftValue,
          totalRods: totalRods,
          moveOverlays: moveOverlays,
        ),
        const SizedBox(width: 24),
        ExampleBridge(expression: expression),
        const SizedBox(width: 24),
        AnimatedStaticAbacusValue(
          value: rightValue,
          totalRods: totalRods,
        ),
      ],
    );
  }
}
