import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/reading_shutter/model.dart';
import 'package:larnes_mobile/trainers/shared/theme/trainer_direction_theme.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

class ReadingShutterScene extends StatelessWidget {
  const ReadingShutterScene({
    super.key,
    required this.hiddenOrder,
    required this.plan,
  });

  final int hiddenOrder;
  final ReadingShutterPlan plan;

  @override
  Widget build(BuildContext context) {
    final surface =
        TrainerDirectionThemeScope.maybeOf(context)?.theme.surface ??
        const Color(0xFFF0FBF3);
    final band = plan.cover == 'half' ? 0.5 : 0.25;

    return TrainerScene(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Stack(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    for (final unit in plan.units)
                      TextSpan(
                        text: unit.grapheme,
                        style: TextStyle(
                          color: hiddenOrder >= unit.order
                              ? const Color(0x0020352D)
                              : const Color(0xFF20352D),
                        ),
                      ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: plan.edge == 'bottom'
                      ? Alignment.bottomCenter
                      : Alignment.topCenter,
                  child: FractionallySizedBox(
                    heightFactor: band,
                    widthFactor: 1,
                    child: ColoredBox(color: surface),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
