import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_play_theme.dart';

/// Web: `platform/src/trainers/reading/letter-find-by-sound/sound-play-button.tsx`
enum SoundPlayButtonVariant { circle, chrome }

class SoundPlayButton extends StatefulWidget {
  const SoundPlayButton({
    super.key,
    required this.onPressed,
    this.disabled = false,
    this.size = 48,
    this.variant = SoundPlayButtonVariant.circle,
  });

  final VoidCallback? onPressed;
  final bool disabled;
  final double size;
  final SoundPlayButtonVariant variant;

  static const shellBlue = Color(0xFF3B6FD4);

  @override
  State<SoundPlayButton> createState() => _SoundPlayButtonState();
}

class _SoundPlayButtonState extends State<SoundPlayButton> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.variant == SoundPlayButtonVariant.chrome) {
      return _buildChrome();
    }

    return _buildCircle();
  }

  Widget _buildCircle() {
    final iconSize = widget.size >= 48 ? 24.0 : 20.0;

    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: CircleBorder(
        side: BorderSide(
          color: SoundPlayButton.shellBlue.withValues(alpha: widget.disabled ? 0.4 : 1),
          width: 2,
        ),
      ),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: widget.disabled ? null : widget.onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Icon(
            Icons.play_arrow_rounded,
            color: SoundPlayButton.shellBlue.withValues(alpha: widget.disabled ? 0.4 : 1),
            size: iconSize,
          ),
        ),
      ),
    );
  }

  Widget _buildChrome() {
    const theme = TrainerPlayTheme.parent;

    return Semantics(
      button: true,
      enabled: !widget.disabled,
      label: 'Прослушать звук',
      child: GestureDetector(
        onTapDown: widget.disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: widget.disabled
            ? null
            : (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              },
        onTapCancel: widget.disabled ? null : () => setState(() => _pressed = false),
        child: Opacity(
          opacity: widget.disabled ? 0.4 : 1,
          child: Transform.translate(
            offset: Offset(0, _pressed ? 1 : 0),
            child: AnimatedContainer(
              duration: ParentMotion.tapDuration,
              curve: ParentMotion.curve,
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _pressed ? theme.accentPressed : theme.accent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.accentDeep,
                    offset: Offset(0, _pressed ? 2 : 3),
                  ),
                ],
              ),
              child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
