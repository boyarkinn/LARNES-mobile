import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_catalogs.dart';

const _popCurve = Cubic(0.34, 1.2, 0.64, 1);

/// Web: `platform/src/trainers/reading/letter-place-in-word/word-card-with-gap.tsx`
class WordCardWithGap extends StatefulWidget {
  const WordCardWithGap({
    super.key,
    required this.displayWord,
    required this.enterDelayMs,
    required this.slug,
  });

  final String displayWord;
  final int enterDelayMs;
  final String slug;

  @override
  State<WordCardWithGap> createState() => _WordCardWithGapState();
}

class _WordCardWithGapState extends State<WordCardWithGap>
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
    _scheduleReveal();
  }

  @override
  void didUpdateWidget(WordCardWithGap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug ||
        oldWidget.enterDelayMs != widget.enterDelayMs) {
      _controller.reset();
      _scheduleReveal();
    }
  }

  void _scheduleReveal() {
    _delayTimer?.cancel();
    _delayTimer = Timer(Duration(milliseconds: widget.enterDelayMs), () {
      if (mounted) {
        _controller.forward(from: 0);
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
    final imageSrc = getFillGapWordImageSrc(widget.slug);

    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final t = _progress.value.clamp(0.0, 1.0);

        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.88 + 0.12 * t,
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - t)),
              child: child,
            ),
          ),
        );
      },
      child: Material(
        color: Colors.white.withValues(alpha: 0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xCCE5E7EB)),
        ),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height * 0.22,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Center(
              child: imageSrc != null
                  ? Image.asset(
                      imageSrc,
                      fit: BoxFit.contain,
                    )
                  : Text(
                      widget.displayWord,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.onest(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                        height: 1.1,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
