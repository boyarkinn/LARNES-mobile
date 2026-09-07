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
      opacity: connected ? 0.7 : 1,
      child: DotGroup(
        count: count,
        dotColor: color,
        frameHeight: size,
        frameWidth: count <= 9 ? size : size * 1.25,
        revealProgressively: false,
        size: DotGroupSize.auto,
      ),
    );
  }
}
