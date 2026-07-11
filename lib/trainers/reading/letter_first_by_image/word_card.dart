import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';

const _popCurve = Cubic(0.34, 1.2, 0.64, 1);

/// Web: `platform/src/trainers/reading/letter-first-by-image/word-card.tsx`
class WordCard extends StatefulWidget {
  const WordCard({
    super.key,
    required this.displayWord,
    required this.imageSrc,
    required this.onPlay,
    this.disabled = false,
  });

  final String displayWord;
  final String? imageSrc;
  final VoidCallback onPlay;
  final bool disabled;

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: kFruitPopDurationMs),
    );
    _progress = CurvedAnimation(parent: _controller, curve: _popCurve);
    _controller.forward();
  }

  @override
  void dispose() {
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
      child: Material(
        color: Colors.white.withValues(alpha: widget.disabled ? 0.5 : 0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xCCE5E7EB)),
        ),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          onTap: widget.disabled ? null : widget.onPlay,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 672),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: widget.imageSrc != null
                    ? Image.asset(
                        widget.imageSrc!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            _WordLabel(displayWord: widget.displayWord),
                      )
                    : _WordLabel(displayWord: widget.displayWord),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WordLabel extends StatelessWidget {
  const _WordLabel({required this.displayWord});

  final String displayWord;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = MediaQuery.sizeOf(context).height;
        final viewportWidth = MediaQuery.sizeOf(context).width;
        final fontSize = _wordFontSize(viewportHeight, viewportWidth);

        return Text(
          displayWord,
          textAlign: TextAlign.center,
          style: GoogleFonts.onest(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
            height: 1.1,
          ),
        );
      },
    );
  }
}

double _wordFontSize(double viewportHeight, double viewportWidth) {
  final compact = viewportWidth < 640;
  final base = compact ? 36.0 : 48.0;
  final fromHeight = viewportHeight * 0.08;
  return fromHeight.clamp(base, 56).roundToDouble();
}
