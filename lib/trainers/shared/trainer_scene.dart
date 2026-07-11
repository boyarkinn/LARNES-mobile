import 'package:flutter/material.dart';

/// Full-bleed root for trainer scene content (web `h-full w-full min-h-0`).
///
/// Etalon: `platform/docs/completed/trainer-scene-design-v2.md` §1.
/// Parent [TrainerPlayer] already stretches the stage; scene roots should fill it.
class TrainerScene extends StatelessWidget {
  const TrainerScene({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: child,
        );
      },
    );
  }
}

/// Column layout for scenes with a bottom bar (web `flex flex-col` + `flex-1 min-h-0`).
class TrainerSceneColumn extends StatelessWidget {
  const TrainerSceneColumn({
    super.key,
    required this.body,
    this.footer,
    this.bodyAlignment = Alignment.center,
  });

  final Widget body;
  final Widget? footer;
  final Alignment bodyAlignment;

  @override
  Widget build(BuildContext context) {
    return TrainerScene(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Align(
              alignment: bodyAlignment,
              child: body,
            ),
          ),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}

/// Body region that must occupy the full stage (tap fields, trace pad, grids).
class TrainerSceneFill extends StatelessWidget {
  const TrainerSceneFill({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TrainerScene(
      child: SizedBox.expand(child: child),
    );
  }
}
