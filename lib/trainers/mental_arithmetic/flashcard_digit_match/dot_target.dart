import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/shared/dot_group.dart';

/// Web v2: `platform/src/trainers/mental-arithmetic/flashcard-digit-match/dot-target.tsx`
class DotTarget extends StatelessWidget {
  const DotTarget({
    super.key,
    required this.color,
    required this.count,
    required this.size,
    this.connected = false,
  });

  final Color color;
  final int count;
  final double size;
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
        child: DotGroup(
          count: count,
          dotColor: color,
          frameHeight: size,
          frameWidth: count <= 9 ? size : size * 1.25,
          framed: false,
          revealProgressively: false,
          size: DotGroupSize.auto,
        ),
      ),
    );
  }
}
