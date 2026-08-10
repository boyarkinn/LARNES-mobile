import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:larnes_mobile/app/theme/parent_text_theme.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/l10n/l10n_extensions.dart';

/// Header for parent screens: centered title; back chevron when stack allows pop.
class ParentHeader extends StatelessWidget {
  const ParentHeader({
    super.key,
    required this.title,
    this.showBack,
    this.onBackPressed,
  });

  final String title;

  /// When null, back is shown if [onBackPressed] is set or [GoRouter] can pop the current branch stack.
  final bool? showBack;

  /// Custom back action instead of stack pop (e.g. account hub → `/parent`).
  final VoidCallback? onBackPressed;

  static const _sideSlotWidth = 48.0;

  bool _showsBack(BuildContext context) {
    if (showBack != null) {
      return showBack!;
    }
    if (onBackPressed != null) {
      return true;
    }
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      return router.canPop();
    }
    return Navigator.of(context).canPop();
  }

  void _handleBack(BuildContext context) {
    if (onBackPressed != null) {
      onBackPressed!();
      return;
    }

    if (GoRouter.maybeOf(context) != null) {
      context.pop();
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = buildParentTextTheme();
    final topPadding = MediaQuery.paddingOf(context).top;
    final canPop = _showsBack(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ParentColors.surface.withValues(alpha: 0.88),
            border: const Border(bottom: BorderSide(color: ParentColors.line)),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 12),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  SizedBox(
                    width: _sideSlotWidth,
                    child: canPop
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: _HeaderBackButton(
                              semanticsLabel: context.l10n.parentBack,
                              onPressed: () => _handleBack(context),
                            ),
                          )
                        : null,
                  ),
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        color: ParentColors.shell,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: _sideSlotWidth),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBackButton extends StatefulWidget {
  const _HeaderBackButton({
    required this.semanticsLabel,
    required this.onPressed,
  });

  final String semanticsLabel;
  final VoidCallback onPressed;

  @override
  State<_HeaderBackButton> createState() => _HeaderBackButtonState();
}

class _HeaderBackButtonState extends State<_HeaderBackButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: ParentMotion.tapDuration,
          curve: ParentMotion.curve,
          child: const Icon(
            Icons.chevron_left_rounded,
            size: 28,
            color: ParentColors.shell,
          ),
        ),
      ),
    );
  }
}
