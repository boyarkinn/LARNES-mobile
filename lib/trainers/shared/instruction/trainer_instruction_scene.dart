// Web: `platform/src/trainers/shared/instruction/trainer-instruction-scene.tsx`

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';
import 'package:larnes_mobile/trainers/shared/theme/trainer_direction_theme.dart';

const kTrainerInstructionColor = Color(0xFF115E59);
const kTrainerInstructionCursorColor = Color(0xFF0F766E);

class TrainerInstructionScene extends StatelessWidget {
  const TrainerInstructionScene({
    super.key,
    required this.length,
    required this.text,
  });

  final int length;
  final String text;

  @override
  Widget build(BuildContext context) {
    final visibleText = text.substring(0, length.clamp(0, text.length));
    final directionTheme = TrainerDirectionThemeScope.maybeOf(context)?.theme;
    final textColor = directionTheme?.deep ?? kTrainerInstructionColor;
    final cursorColor = directionTheme?.base ?? kTrainerInstructionCursorColor;

    return TrainerScene(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: visibleText,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: textColor,
                  ),
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: _TrainerInstructionCursor(color: cursorColor),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _TrainerInstructionCursor extends StatefulWidget {
  const _TrainerInstructionCursor({required this.color});

  final Color color;

  @override
  State<_TrainerInstructionCursor> createState() =>
      _TrainerInstructionCursorState();
}

class _TrainerInstructionCursorState extends State<_TrainerInstructionCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 3,
        height: 28,
        margin: const EdgeInsets.only(left: 4),
        color: widget.color,
      ),
    );
  }
}
