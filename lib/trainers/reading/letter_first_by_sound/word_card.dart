import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';

const _popCurve = Cubic(0.34, 1.2, 0.64, 1);

/// Web: `platform/src/trainers/reading/letter-first-by-sound/word-card.tsx`
class WordCard extends StatefulWidget {
  const WordCard({
    super.key,
    required this.imageSrc,
    required this.onPlay,
    this.disabled = false,
  });

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
            constraints: const BoxConstraints(maxWidth: 280),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Center(
                child: widget.imageSrc == null
                    ? const SizedBox.shrink()
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final size = MediaQuery.sizeOf(context);
                          final maxHeight = (size.height * 0.21)
                              .clamp(72.0, size.width * 0.28);

                          return ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: maxHeight),
                            child: Image.asset(
                              widget.imageSrc!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
