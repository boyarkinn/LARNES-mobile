import 'dart:async';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/reading/reading_word_catalogs.dart';

const _popCurve = Cubic(0.34, 1.2, 0.64, 1);

/// Web: `platform/src/trainers/reading/letter-place-in-word/word-card-with-gap.tsx`
class WordCardWithGap extends StatefulWidget {
  const WordCardWithGap({
    super.key,
    required this.displayWord,
    required this.enterDelayMs,
    required this.onPlay,
    required this.slug,
    required this.success,
  });

  final String displayWord;
  final int enterDelayMs;
  final VoidCallback onPlay;
  final String slug;
  final bool success;

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
      child: Semantics(
        button: true,
        label: 'Прослушать слово ${widget.displayWord.toLowerCase()}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPlay,
            borderRadius: BorderRadius.circular(24),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 260),
              scale: widget.success ? 1.04 : 1,
              curve: Curves.easeOutBack,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.sizeOf(context).height * 0.30,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.36,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                      child: imageSrc != null
                          ? Image.asset(
                              imageSrc,
                              fit: BoxFit.contain,
                              semanticLabel: widget.displayWord.toLowerCase(),
                            )
                          : Text(
                              widget.displayWord,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF20352D),
                                height: 1.1,
                              ),
                            ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 8,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFF315CD6),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x38315CD6),
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
