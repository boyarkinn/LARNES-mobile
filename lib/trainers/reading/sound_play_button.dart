import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_play_theme.dart';

/// Web: `platform/src/trainers/reading/letter-find-by-sound/sound-play-button.tsx`
enum SoundPlayButtonVariant { circle, chrome, reading }

class SoundPlayButton extends StatefulWidget {
  const SoundPlayButton({
    super.key,
    required this.onPressed,
    this.active = false,
    this.disabled = false,
    this.size = 48,
    this.variant = SoundPlayButtonVariant.circle,
  });

  final VoidCallback? onPressed;
  final bool active;
  final bool disabled;
  final double size;
  final SoundPlayButtonVariant variant;

  static const shellBlue = Color(0xFF3B6FD4);

  @override
  State<SoundPlayButton> createState() => _SoundPlayButtonState();
}

class _SoundPlayButtonState extends State<SoundPlayButton>
    with SingleTickerProviderStateMixin {
  var _pressed = false;
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );
    _syncWaves();
  }

  @override
  void didUpdateWidget(SoundPlayButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _syncWaves();
    }
  }

  void _syncWaves() {
    if (widget.active) {
      _waveController.repeat();
    } else {
      _waveController.stop();
      _waveController.value = 0;
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.variant == SoundPlayButtonVariant.chrome) {
      return _buildChrome();
    }
    if (widget.variant == SoundPlayButtonVariant.reading) {
      return _buildReading();
    }

    return _buildCircle();
  }

  Widget _buildCircle() {
    final iconSize = widget.size >= 48 ? 24.0 : 20.0;

    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: CircleBorder(
        side: BorderSide(
          color: SoundPlayButton.shellBlue.withValues(
            alpha: widget.disabled ? 0.4 : 1,
          ),
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
            color: SoundPlayButton.shellBlue.withValues(
              alpha: widget.disabled ? 0.4 : 1,
            ),
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
        onTapDown: widget.disabled
            ? null
            : (_) => setState(() => _pressed = true),
        onTapUp: widget.disabled
            ? null
            : (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              },
        onTapCancel: widget.disabled
            ? null
            : () => setState(() => _pressed = false),
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
              child: const Icon(
                Icons.volume_up_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReading() {
    return SizedBox(
      width: widget.size * 1.75,
      height: widget.size * 1.75,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          Widget wave(double progress, Color color) {
            final normalized = progress % 1;
            return Opacity(
              opacity: widget.active ? (1 - normalized) * 0.34 : 0,
              child: Transform.scale(
                scale: 1 + normalized * 0.72,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                ),
              ),
            );
          }

          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.square(
                dimension: widget.size,
                child: wave(_waveController.value, const Color(0xFF249B73)),
              ),
              SizedBox.square(
                dimension: widget.size,
                child: wave(
                  _waveController.value + 0.5,
                  const Color(0xFF8BDCB2),
                ),
              ),
              child!,
            ],
          );
        },
        child: Semantics(
          button: true,
          enabled: !widget.disabled,
          label: 'Прослушать звук',
          child: GestureDetector(
            onTapDown: widget.disabled
                ? null
                : (_) => setState(() => _pressed = true),
            onTapUp: widget.disabled
                ? null
                : (_) {
                    setState(() => _pressed = false);
                    widget.onPressed?.call();
                  },
            onTapCancel: widget.disabled
                ? null
                : () => setState(() => _pressed = false),
            child: Opacity(
              opacity: widget.disabled && !widget.active ? 0.45 : 1,
              child: Transform.translate(
                offset: Offset(0, _pressed ? 4 : 0),
                child: AnimatedContainer(
                  duration: ParentMotion.tapDuration,
                  curve: ParentMotion.curve,
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: _pressed
                        ? const Color(0xFF208B68)
                        : const Color(0xFF249B73),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xB3FFFFFF)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF187B5A),
                        offset: Offset(0, _pressed ? 2 : 5),
                      ),
                      const BoxShadow(
                        color: Color(0x3D249B73),
                        blurRadius: 28,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: Colors.white,
                    size: widget.size * 0.44,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
