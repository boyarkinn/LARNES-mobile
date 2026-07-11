import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_build/build_pad_size.dart';
import 'package:larnes_mobile/trainers/reading/letter_build/letter_build_model.dart';

/// Web: `platform/src/trainers/reading/letter-build/build-phase-dots.tsx`
class BuildPhaseDots extends StatelessWidget {
  const BuildPhaseDots({
    super.key,
    required this.phase,
    this.hasPassed = false,
  });

  final BuildPhase phase;
  final bool hasPassed;

  @override
  Widget build(BuildContext context) {
    const phases = BuildPhase.values;

    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final step in phases) ...[
            _BuildPhaseDot(
              isDone: step == BuildPhase.guide
                  ? phase == BuildPhase.free || hasPassed
                  : hasPassed,
              isCurrent: () {
                final isDone = step == BuildPhase.guide
                    ? phase == BuildPhase.free || hasPassed
                    : hasPassed;
                return !isDone && phase == step;
              }(),
            ),
            if (step != phases.last) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _BuildPhaseDot extends StatelessWidget {
  const _BuildPhaseDot({
    required this.isDone,
    required this.isCurrent,
  });

  final bool isDone;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final size = isCurrent ? 12.0 : 10.0;
    final color = isDone
        ? buildPhaseDoneColor
        : isCurrent
            ? buildPhaseActiveColor
            : buildPhasePendingColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
