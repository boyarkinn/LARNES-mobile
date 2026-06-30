import 'package:flutter/material.dart';

enum TrainerShellTone {
  sky,
  rose,
  orange,
}

class TrainerShell extends StatelessWidget {
  const TrainerShell({
    super.key,
    required this.child,
    this.tone = TrainerShellTone.sky,
    this.minHeight = 200,
  });

  final Widget child;
  final TrainerShellTone tone;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsForTone(tone);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderForTone(tone)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }

  List<Color> _colorsForTone(TrainerShellTone tone) {
    return switch (tone) {
      TrainerShellTone.sky => const [Color(0xFFF0F9FF), Colors.white],
      TrainerShellTone.rose => const [Color(0xFFFFF1F2), Colors.white],
      TrainerShellTone.orange => const [Color(0xFFFFF7ED), Colors.white],
    };
  }

  Color _borderForTone(TrainerShellTone tone) {
    return switch (tone) {
      TrainerShellTone.sky => const Color(0xFFE0F2FE),
      TrainerShellTone.rose => const Color(0xFFFFE4E6),
      TrainerShellTone.orange => const Color(0xFFFFEDD5),
    };
  }
}
