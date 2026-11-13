import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

/// Short reading prompts stay centered; authored text and answer lists can grow
/// beyond a phone viewport without making the last answer unreachable.
class ReadingScrollableScene extends StatelessWidget {
  const ReadingScrollableScene({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => TrainerScene(
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    ),
  );
}
