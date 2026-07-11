import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_play_theme.dart';

class TrainerStepChrome {
  const TrainerStepChrome({
    this.errorMessage,
    required this.finishLabel,
    required this.isInteractive,
    required this.isLast,
    this.isPending = false,
    required this.nextLabel,
    this.onAdvance,
    this.theme = TrainerPlayTheme.parent,
  });

  final String? errorMessage;
  final String finishLabel;
  final bool isInteractive;
  final bool isLast;
  final bool isPending;
  final String nextLabel;
  final VoidCallback? onAdvance;
  final TrainerPlayTheme theme;

  bool get shouldShow => errorMessage != null || !isInteractive;
}

class TrainerStepChromeBar extends StatelessWidget {
  const TrainerStepChromeBar({super.key, required this.chrome});

  final TrainerStepChrome chrome;

  @override
  Widget build(BuildContext context) {
    if (!chrome.shouldShow) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chrome.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                chrome.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFDC2626),
                ),
              ),
            ),
          if (!chrome.isInteractive)
            _AdvanceButton(
              label: chrome.isLast ? chrome.finishLabel : chrome.nextLabel,
              isPending: chrome.isPending,
              onPressed: chrome.onAdvance,
              theme: chrome.theme,
            ),
        ],
      ),
    );
  }
}

class _AdvanceButton extends StatefulWidget {
  const _AdvanceButton({
    required this.label,
    required this.isPending,
    required this.onPressed,
    required this.theme,
  });

  final String label;
  final bool isPending;
  final VoidCallback? onPressed;
  final TrainerPlayTheme theme;

  @override
  State<_AdvanceButton> createState() => _AdvanceButtonState();
}

class _AdvanceButtonState extends State<_AdvanceButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final enabled = widget.onPressed != null && !widget.isPending;
    final background = _pressed && enabled ? theme.accentPressed : theme.accent;
    final shadowDy = _pressed && enabled ? 2.0 : 3.0;

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedContainer(
        duration: ParentMotion.tapDuration,
        curve: ParentMotion.curve,
        constraints: const BoxConstraints(minWidth: 136, maxWidth: 288, minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? background : background.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: theme.accentDeep,
                    offset: Offset(0, shadowDy),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: widget.isPending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  widget.label,
                  style: GoogleFonts.fredoka(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
