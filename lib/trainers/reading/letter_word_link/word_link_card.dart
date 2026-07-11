import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/reading/sound_play_button.dart';
import 'package:larnes_mobile/trainers/reading/letter_word_link/word_link_size.dart';

const _popCurve = Cubic(0.34, 1.2, 0.64, 1);

/// Web: `platform/src/trainers/reading/letter-word-link/word-link-card.tsx`

class LetterWordLinkAnchorCard extends StatefulWidget {
  const LetterWordLinkAnchorCard({
    super.key,
    required this.displayLetter,
    required this.letterColor,
    required this.boxSize,
    required this.fontSize,
    required this.disabled,
    required this.onPointerDown,
    required this.onPointerEnd,
    this.revealDelayMs = 0,
  });

  final String displayLetter;
  final Color letterColor;
  final double boxSize;
  final double fontSize;
  final bool disabled;
  final int revealDelayMs;
  final ValueChanged<PointerDownEvent> onPointerDown;
  final ValueChanged<PointerEvent> onPointerEnd;

  @override
  State<LetterWordLinkAnchorCard> createState() =>
      _LetterWordLinkAnchorCardState();
}

class _LetterWordLinkAnchorCardState extends State<LetterWordLinkAnchorCard>
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
              border: Border.all(color: const Color(0xCCE5E7EB), width: 2),
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
                color: widget.letterColor,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WordLinkCard extends StatefulWidget {
  const WordLinkCard({
    super.key,
    required this.displayLabel,
    required this.imageSrc,
    required this.connected,
    required this.onPlaySound,
    required this.revealDelayMs,
    this.wrongFlash = false,
  });

  final String displayLabel;
  final String? imageSrc;
  final bool connected;
  final VoidCallback onPlaySound;
  final int revealDelayMs;
  final bool wrongFlash;

  @override
  State<WordLinkCard> createState() => _WordLinkCardState();
}

class _WordLinkCardState extends State<WordLinkCard> with TickerProviderStateMixin {
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
  void didUpdateWidget(WordLinkCard oldWidget) {
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
    final borderColor = widget.wrongFlash
        ? const Color(0xFFF87171)
        : widget.connected
        ? wordLinkLineLockedColor.withValues(alpha: 0.6)
        : const Color(0xCCE5E7EB);
    final backgroundColor = widget.wrongFlash
        ? const Color(0xCCFEF2F2)
        : Colors.white.withValues(alpha: 0.7);
    final labelColor = widget.wrongFlash
        ? const Color(0xFFDC2626)
        : const Color(0xFF1F2937);

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportWidth = MediaQuery.sizeOf(context).width;
          final maxCardWidth = (viewportWidth * 0.42).clamp(0, 220).toDouble();

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxCardWidth),
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: getWordLinkCardMinHeight(
                      MediaQuery.sizeOf(context).height,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: backgroundColor,
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
                  alignment: Alignment.center,
                  child: widget.imageSrc != null
                      ? Image.asset(
                          widget.imageSrc!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              _WordLinkLabel(
                                displayLabel: widget.displayLabel,
                                color: labelColor,
                              ),
                        )
                      : _WordLinkLabel(
                          displayLabel: widget.displayLabel,
                          color: labelColor,
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: 'Прослушать ${widget.displayLabel}',
                button: true,
                child: SoundPlayButton(
                  onPressed: widget.onPlaySound,
                  size: viewportWidth < 640 ? 40 : 44,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WordLinkLabel extends StatelessWidget {
  const _WordLinkLabel({
    required this.displayLabel,
    required this.color,
  });

  final String displayLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 640;

    return Text(
      displayLabel,
      textAlign: TextAlign.center,
      style: GoogleFonts.onest(
        fontSize: compact ? 16 : 18,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.2,
      ),
    );
  }
}
