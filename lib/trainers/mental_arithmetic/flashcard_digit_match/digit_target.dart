import 'package:flutter/material.dart';

/// Web v2: `platform/src/trainers/mental-arithmetic/flashcard-digit-match/digit-target.tsx`
class DigitTarget extends StatelessWidget {
  const DigitTarget({
    super.key,
    required this.color,
    required this.digit,
    required this.size,
    required this.fontSize,
    this.connected = false,
  });

  final Color color;
  final int digit;
  final double size;
  final double fontSize;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: connected ? 0.85 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x80FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: connected
                ? const Color(0xFF34D399)
                : const Color(0x337759D6),
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A7759D6),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$digit',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
