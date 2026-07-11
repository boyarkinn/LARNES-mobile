import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_play_theme.dart';

class TrainerPlayerMenuButton extends StatefulWidget {
  const TrainerPlayerMenuButton({
    super.key,
    required this.isOpen,
    required this.onPressed,
    this.theme = TrainerPlayTheme.parent,
  });

  final bool isOpen;
  final VoidCallback onPressed;
  final TrainerPlayTheme theme;

  @override
  State<TrainerPlayerMenuButton> createState() => _TrainerPlayerMenuButtonState();
}

class _TrainerPlayerMenuButtonState extends State<TrainerPlayerMenuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final horizontalInset = MediaQuery.paddingOf(context).left;
    final left = horizontalInset > 14 ? horizontalInset : 14.0;

    return Padding(
      padding: EdgeInsets.only(top: 12, left: left),
      child: Semantics(
        button: true,
        label: 'Меню',
        expanded: widget.isOpen,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onPressed();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: Transform.translate(
            offset: Offset(0, _pressed ? 1 : 0),
            child: AnimatedContainer(
              duration: ParentMotion.tapDuration,
              curve: ParentMotion.curve,
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.isOpen
                    ? theme.accentDeep
                    : (_pressed ? theme.accentPressed : theme.accent),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.isOpen ? const Color(0xFF16367A) : theme.accentDeep,
                    offset: Offset(0, _pressed || widget.isOpen ? 2 : 3),
                  ),
                ],
              ),
              child: const Center(child: _MenuIcon()),
            ),
          ),
        ),
      ),
    );
  }
}

class TrainerPlayerMenuModal extends StatelessWidget {
  const TrainerPlayerMenuModal({
    super.key,
    required this.continueLabel,
    required this.exitLabel,
    required this.onContinue,
    required this.onExit,
    this.theme = TrainerPlayTheme.parent,
  });

  final String continueLabel;
  final String exitLabel;
  final VoidCallback onContinue;
  final VoidCallback onExit;
  final TrainerPlayTheme theme;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onTap: onContinue,
          behavior: HitTestBehavior.opaque,
          child: Container(color: Colors.black.withValues(alpha: 0.45)),
        ),
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 280,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: ParentColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(26, 29, 46, 0.18),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MenuAction(
                    label: continueLabel,
                    isPrimary: true,
                    theme: theme,
                    onTap: onContinue,
                  ),
                  const Divider(height: 1, color: ParentColors.line),
                  _MenuAction(
                    label: exitLabel,
                    isPrimary: false,
                    theme: theme,
                    onTap: onExit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuIcon extends StatelessWidget {
  const _MenuIcon();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (_) => Container(
          width: 18,
          height: 2,
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

class _MenuAction extends StatefulWidget {
  const _MenuAction({
    required this.label,
    required this.isPrimary,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final bool isPrimary;
  final VoidCallback onTap;
  final TrainerPlayTheme theme;

  @override
  State<_MenuAction> createState() => _MenuActionState();
}

class _MenuActionState extends State<_MenuAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isPrimary ? widget.theme.accent : widget.theme.danger;
    final pressedColor =
        widget.isPrimary ? widget.theme.accentPressed : widget.theme.dangerPressed;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: ParentMotion.tapDuration,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: _pressed ? pressedColor.withValues(alpha: 0.12) : Colors.transparent,
        child: Text(
          widget.label,
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
