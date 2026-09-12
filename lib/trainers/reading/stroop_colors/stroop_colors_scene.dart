import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/trainers/reading/stroop_colors/stroop_colors_sizes.dart';

const _signalCurve = Cubic(0.23, 1, 0.32, 1);
const _wordSwitchMs = 190;

/// Web: `platform/src/trainers/reading/stroop-colors/stroop-colors-scene.tsx`
class StroopColorsScene extends StatelessWidget {
  const StroopColorsScene({
    super.key,
    required this.inkHex,
    required this.itemIndex,
    required this.word,
    required this.wordKey,
  });

  final String inkHex;
  final int itemIndex;
  final String word;
  final String wordKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = stroopWordBoxSize(
          constraints.maxHeight,
          constraints.maxWidth,
        );
        final fontSize = stroopWordFontSize(
          constraints.maxHeight,
          constraints.maxWidth,
        );
        final ink = stroopInkColor(inkHex);
        final direction = itemIndex.isEven ? 1.0 : -1.0;
        final displayFontSize = word.length >= 9 ? fontSize * 0.78 : fontSize;
        final wordStyle = GoogleFonts.onest(
          fontSize: displayFontSize,
          fontWeight: FontWeight.w800,
          color: ink,
          height: 1,
          shadows: const [Shadow(blurRadius: 3, color: Color(0x1A1C4E3B))],
        );
        final wordPainter = TextPainter(
          text: TextSpan(text: word, style: wordStyle),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: boxSize * 0.74);
        final wordWidth = wordPainter.width;

        return Center(
          child: SizedBox(
            width: boxSize,
            height: boxSize,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: EdgeInsets.all(boxSize * 0.12),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [Color(0xCCFFFFFF), Color(0x00FFFFFF)],
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  key: ValueKey('focus-$wordKey'),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 340),
                  curve: _signalCurve,
                  builder: (context, value, _) {
                    final pulse = value < 0.5 ? value * 2 : (1 - value) * 2;
                    return Opacity(
                      opacity: 0.34 + pulse * 0.34,
                      child: _FocusRails(progress: value, wordWidth: wordWidth),
                    );
                  },
                ),
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: _wordSwitchMs),
                    reverseDuration: const Duration(milliseconds: 150),
                    switchInCurve: _signalCurve,
                    switchOutCurve: Curves.easeOut,
                    layoutBuilder: (currentChild, previousChildren) => Stack(
                      alignment: Alignment.center,
                      children: [...previousChildren, ?currentChild],
                    ),
                    transitionBuilder: (child, animation) {
                      final exiting =
                          animation.status == AnimationStatus.reverse;
                      final travel = exiting ? -direction : direction;
                      return AnimatedBuilder(
                        animation: animation,
                        builder: (context, _) {
                          final progress = animation.value.clamp(0.0, 1.0);
                          return Opacity(
                            opacity: progress,
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(
                                sigmaX: (1 - progress) * 4,
                                sigmaY: (1 - progress) * 4,
                              ),
                              child: Transform.translate(
                                offset: Offset(
                                  (1 - progress) * travel * 22,
                                  (1 - progress) * 7,
                                ),
                                child: child,
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: ConstrainedBox(
                      key: ValueKey(wordKey),
                      constraints: BoxConstraints(maxWidth: boxSize * 0.74),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          word,
                          textAlign: TextAlign.center,
                          style: wordStyle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FocusRails extends StatelessWidget {
  const _FocusRails({required this.progress, required this.wordWidth});

  final double progress;
  final double wordWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availablePerSide = (constraints.maxWidth - wordWidth) / 2 - 16;
        final railWidth = availablePerSide.clamp(18.0, 72.0);
        final center = constraints.maxWidth / 2;

        return Stack(
          children: [
            Positioned(
              left: center - wordWidth / 2 - 16 - railWidth,
              top: constraints.maxHeight / 2 - 1.5,
              child: Transform.translate(
                offset: Offset(-14 * (1 - progress), 0),
                child: _FocusRail(left: true, width: railWidth),
              ),
            ),
            Positioned(
              left: center + wordWidth / 2 + 16,
              top: constraints.maxHeight / 2 - 1.5,
              child: Transform.translate(
                offset: Offset(14 * (1 - progress), 0),
                child: _FocusRail(left: false, width: railWidth),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FocusRail extends StatelessWidget {
  const _FocusRail({required this.left, required this.width});

  final bool left;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(999)),
          gradient: LinearGradient(
            colors: left
                ? const [Color(0x00249B73), Color(0x99249B73)]
                : const [Color(0x99249B73), Color(0x00249B73)],
          ),
        ),
      ),
    );
  }
}
