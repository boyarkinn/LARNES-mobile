import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

class ReadingLinePaceScene extends StatelessWidget {
  const ReadingLinePaceScene({
    super.key,
    required this.index,
    required this.lineKeep,
    required this.lines,
  });

  final int index;
  final String lineKeep;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final visible = lineKeep == 'drop'
        ? (index >= 0 && index < lines.length ? [lines[index]] : <String>[])
        : lines;

    return TrainerScene(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var visibleIndex = 0; visibleIndex < visible.length; visibleIndex++)
                _Line(
                  current: (lineKeep == 'drop' ? index : visibleIndex) == index,
                  text: visible[visibleIndex],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.current, required this.text});

  final bool current;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: current ? const Color(0xFF0C4A6E) : const Color(0x00000000),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            text,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: current ? const Color(0xFFFFFFFF) : const Color(0xFF20352D),
              fontSize: 32,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}
