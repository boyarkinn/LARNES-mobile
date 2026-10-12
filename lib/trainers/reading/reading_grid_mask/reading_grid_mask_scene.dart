import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/shared/passage.dart';
import 'package:larnes_mobile/trainers/shared/trainer_scene.dart';

class ReadingGridMaskScene extends StatelessWidget {
  const ReadingGridMaskScene({
    super.key,
    required this.gridStepPx,
    required this.hiddenOrder,
    required this.units,
  });

  final int gridStepPx;
  final int hiddenOrder;
  final List<VanishUnit> units;

  @override
  Widget build(BuildContext context) {
    return TrainerScene(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: Stack(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    for (final unit in units)
                      TextSpan(
                        text: unit.grapheme,
                        style: TextStyle(
                          color: hiddenOrder >= unit.order
                              ? const Color(0x0020352D)
                              : const Color(0xFF20352D),
                        ),
                      ),
                  ],
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600, height: 1.25),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _GridFramePainter(gridStepPx)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridFramePainter extends CustomPainter {
  const _GridFramePainter(this.step);

  final int step;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x73115E59)
      ..strokeWidth = 1;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridFramePainter oldDelegate) => oldDelegate.step != step;
}
