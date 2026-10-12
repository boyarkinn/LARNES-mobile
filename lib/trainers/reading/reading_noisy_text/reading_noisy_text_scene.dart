import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/reading_noisy_text/model.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

class ReadingNoisyTextScene extends StatelessWidget {
  const ReadingNoisyTextScene({
    super.key,
    required this.hiddenOrder,
    required this.plan,
  });

  final int hiddenOrder;
  final ReadingNoisyTextPlan plan;

  Color _color(NoisyUnit unit) {
    final hidden = !unit.noise && hiddenOrder >= unit.order;
    if (hidden) return const Color(0x0020352D);
    return unit.noise ? const Color(0xFF7D8F86) : const Color(0xFF20352D);
  }

  @override
  Widget build(BuildContext context) {
    if (plan.noise == 'circle') {
      return TrainerScene(
        child: Center(
          child: SizedBox(
            height: 320,
            width: 320,
            child: Stack(
              children: [
                for (var index = 0; index < plan.units.length; index++)
                  _circleLetter(plan.units[index], index),
              ],
            ),
          ),
        ),
      );
    }

    final line = Wrap(
      alignment: WrapAlignment.center,
      children: [
        for (var index = 0; index < plan.units.length; index++)
          _lineLetter(plan.units[index], index),
      ],
    );

    return TrainerScene(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: plan.noise == 'strokes'
              ? Stack(
                  children: [
                    line,
                    const Positioned.fill(child: IgnorePointer(child: _StrokeOverlay())),
                  ],
                )
              : line,
        ),
      ),
    );
  }

  Widget _lineLetter(NoisyUnit unit, int index) {
    Widget child = Text(
      unit.grapheme,
      textDirection: TextDirection.ltr,
      style: TextStyle(color: _color(unit), fontSize: 32, fontWeight: FontWeight.w600),
    );
    if (plan.noise == 'zigzag') {
      child = Transform.translate(
        offset: Offset(0, index.isEven ? -8 : 8),
        child: child,
      );
    } else if (plan.noise == 'wave') {
      child = Transform.translate(
        offset: Offset(0, math.sin(index * 0.8) * 10),
        child: child,
      );
    } else if (plan.noise == 'flip' && unit.turned) {
      child = Transform.rotate(angle: math.pi, child: child);
    }
    return child;
  }

  Widget _circleLetter(NoisyUnit unit, int index) {
    final count = plan.units.isEmpty ? 1 : plan.units.length;
    final angle = (index / count) * math.pi * 2 - math.pi / 2;
    return Align(
      alignment: Alignment(
        math.cos(angle) * 0.82,
        math.sin(angle) * 0.82,
      ),
      child: Text(
        unit.grapheme,
        style: TextStyle(color: _color(unit), fontSize: 22, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StrokeOverlay extends StatelessWidget {
  const _StrokeOverlay();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _StrokePainter());
  }
}

class _StrokePainter extends CustomPainter {
  const _StrokePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x6620352D)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, size.height * 0.22), Offset(size.width, size.height * 0.34), paint);
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.42), paint);
    canvas.drawLine(Offset(0, size.height * 0.78), Offset(size.width, size.height * 0.7), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
