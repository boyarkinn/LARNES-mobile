import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/trainers/reading/stroop_colors/stroop_colors_sizes.dart';

const _popCurve = Cubic(0.34, 1.2, 0.64, 1);
const _wordSwitchMs = 320;

/// Web: `platform/src/trainers/reading/stroop-colors/stroop-colors-scene.tsx`
class StroopColorsScene extends StatelessWidget {
  const StroopColorsScene({
    super.key,
    required this.inkHex,
    required this.word,
    required this.wordKey,
  });

  final String inkHex;
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

        return Center(
          child: SizedBox(
            width: boxSize,
            height: boxSize,
            child: Center(
              child: TweenAnimationBuilder<double>(
                key: ValueKey(wordKey),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: _wordSwitchMs),
                curve: _popCurve,
                builder: (context, value, child) {
                  final progress = value.clamp(0.0, 1.0);

                  return Opacity(
                    opacity: progress,
                    child: Transform.scale(
                      scale: 0.9 + 0.1 * progress,
                      child: child,
                    ),
                  );
                },
                child: Text(
                  word,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.onest(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    color: ink,
                    height: 1,
                    shadows: const [
                      Shadow(
                        offset: Offset(0, 2),
                        color: Color(0x291C1917),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
