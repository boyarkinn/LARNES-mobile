import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_case_match/case_match_size.dart';

const _popCurve = Cubic(0.34, 1.2, 0.64, 1);

/// Web: `platform/src/trainers/reading/letter-case-match/case-match-card.tsx`

class LowercaseCaseMatchCard extends StatefulWidget {
  const LowercaseCaseMatchCard({
    super.key,
    required this.displayLetter,
    required this.displayColor,
    required this.boxSize,
    required this.fontSize,
    required this.connected,
    required this.disabled,
    required this.revealDelayMs,
    required this.onPointerDown,
    required this.onPointerEnd,
  });

  final String displayLetter;
  final Color displayColor;
  final double boxSize;
  final double fontSize;
  final bool connected;
  final bool disabled;
  final int revealDelayMs;
  final ValueChanged<PointerDownEvent> onPointerDown;
  final ValueChanged<PointerEvent> onPointerEnd;

  @override
  State<LowercaseCaseMatchCard> createState() => _LowercaseCaseMatchCardState();
}

class _LowercaseCaseMatchCardState extends State<LowercaseCaseMatchCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: kFruitPopDurationMs),
    );
    _progress = CurvedAnimation(parent: _controller, curve: _popCurve);
    _delayTimer = Timer(Duration(milliseconds: widget.revealDelayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        widget.connected ? caseMatchLineLockedColor : const Color(0xFFE5E7EB);

    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final t = _progress.value.clamp(0.0, 1.0);

        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.88 + 0.12 * t,
            child: child,
          ),
        );
      },
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: widget.disabled ? null : widget.onPointerDown,
        onPointerUp: widget.disabled ? null : widget.onPointerEnd,
        onPointerCancel: widget.disabled ? null : widget.onPointerEnd,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: widget.disabled ? 0.7 : 1,
          child: Container(
            width: widget.boxSize,
            height: widget.boxSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(15, 23, 42, 0.06),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              widget.displayLetter,
              style: GoogleFonts.onest(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w700,
                color: widget.displayColor,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UppercaseCaseMatchCard extends StatefulWidget {
  const UppercaseCaseMatchCard({
    super.key,
    required this.displayLetter,
    required this.boxSize,
    required this.fontSize,
    required this.connected,
    required this.revealDelayMs,
    this.wrongFlash = false,
  });

  final String displayLetter;
  final double boxSize;
  final double fontSize;
  final bool connected;
  final int revealDelayMs;
  final bool wrongFlash;

  @override
  State<UppercaseCaseMatchCard> createState() => _UppercaseCaseMatchCardState();
}

class _UppercaseCaseMatchCardState extends State<UppercaseCaseMatchCard>
    with TickerProviderStateMixin {
  late final AnimationController _revealController;
  late final Animation<double> _revealProgress;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: kFruitPopDurationMs),
    );
    _revealProgress = CurvedAnimation(
      parent: _revealController,
      curve: _popCurve,
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: -5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
    _delayTimer = Timer(Duration(milliseconds: widget.revealDelayMs), () {
      if (mounted) {
        _revealController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(UppercaseCaseMatchCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.wrongFlash && widget.wrongFlash) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _revealController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        widget.connected ? caseMatchLineLockedColor : const Color(0xFFE5E7EB);

    return AnimatedBuilder(
      animation: Listenable.merge([_revealProgress, _shakeController]),
      builder: (context, child) {
        final t = _revealProgress.value.clamp(0.0, 1.0);

        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.88 + 0.12 * t,
            child: Transform.translate(
              offset: Offset(_shakeOffset.value, 0),
              child: child,
            ),
          ),
        );
      },
      child: Container(
        width: widget.boxSize,
        height: widget.boxSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(15, 23, 42, 0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          widget.displayLetter,
          style: GoogleFonts.onest(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w700,
            height: 1,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = caseMatchOutlineStrokeWidth
              ..color = caseMatchOutlineStrokeColor,
          ),
        ),
      ),
    );
  }
}
