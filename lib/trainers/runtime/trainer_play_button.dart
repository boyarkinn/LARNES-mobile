import 'package:flutter/material.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_play_theme.dart';

/// Shared raised control used by the player menu and in-scene actions.
class TrainerPlayButton extends StatefulWidget {
  const TrainerPlayButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.theme = TrainerPlayTheme.parent,
    this.selected = false,
    this.danger = false,
    this.width,
    this.padding = EdgeInsets.zero,
    this.semanticsLabel,
    this.expanded,
  });

  final Widget child;
  final VoidCallback onPressed;
  final TrainerPlayTheme theme;
  final bool selected;
  final bool danger;
  final double? width;
  final EdgeInsetsGeometry padding;
  final String? semanticsLabel;
  final bool? expanded;

  @override
  State<TrainerPlayButton> createState() => _TrainerPlayButtonState();
}

class _TrainerPlayButtonState extends State<TrainerPlayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final background = widget.danger ? theme.danger : theme.accent;
    final pressedColor = widget.danger
        ? theme.dangerPressed
        : theme.accentPressed;
    final edge = widget.danger ? theme.dangerPressed : theme.accentDeep;
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      expanded: widget.expanded,
      onTap: widget.onPressed,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed();
              return null;
            },
          ),
        },
        child: GestureDetector(
          excludeFromSemantics: true,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onPressed,
          child: Transform.translate(
            offset: Offset(0, _pressed ? 1 : 0),
            child: AnimatedContainer(
              duration: ParentMotion.tapDuration,
              curve: ParentMotion.curve,
              constraints: const BoxConstraints(minWidth: 48),
              width: widget.width,
              height: 48,
              padding: widget.padding,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.selected
                    ? edge
                    : (_pressed ? pressedColor : background),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.selected && !widget.danger
                        ? const Color(0xFF16367A)
                        : edge,
                    offset: Offset(0, _pressed || widget.selected ? 2 : 3),
                  ),
                ],
              ),
              child: DefaultTextStyle.merge(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
