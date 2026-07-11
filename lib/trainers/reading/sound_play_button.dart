import 'package:flutter/material.dart';

/// Web: `platform/src/trainers/reading/letter-find-by-sound/sound-play-button.tsx`
class SoundPlayButton extends StatelessWidget {
  const SoundPlayButton({
    super.key,
    required this.onPressed,
    this.disabled = false,
    this.size = 48,
  });

  final VoidCallback? onPressed;
  final bool disabled;
  final double size;

  static const shellBlue = Color(0xFF3B6FD4);

  @override
  Widget build(BuildContext context) {
    final iconSize = size >= 48 ? 24.0 : 20.0;

    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: CircleBorder(
        side: BorderSide(
          color: shellBlue.withValues(alpha: disabled ? 0.4 : 1),
          width: 2,
        ),
      ),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: disabled ? null : onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.play_arrow_rounded,
            color: shellBlue.withValues(alpha: disabled ? 0.4 : 1),
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
