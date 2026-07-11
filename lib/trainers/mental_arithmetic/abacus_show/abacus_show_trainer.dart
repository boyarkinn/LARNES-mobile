import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/shared/abacus/abacus_widget.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

/// Web v2: `platform/src/trainers/mental-arithmetic/abacus-show/component.tsx`
class AbacusShowTrainer extends StatelessWidget {
  const AbacusShowTrainer({
    super.key,
    required this.params,
  });

  final Map<String, dynamic> params;

  @override
  Widget build(BuildContext context) {
    final totalRods = params['totalRods'] as int? ?? 1;
    final value = params['value'] as int? ?? 0;

    return TrainerScene(
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
                child: AnimatedAbacusValue(
                  value: value,
                  totalRods: totalRods,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
