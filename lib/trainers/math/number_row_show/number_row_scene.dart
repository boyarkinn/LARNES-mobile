import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_show_geometry.dart';
import 'package:larnes_mobile/trainers/math/number_row_show/number_row_show_model.dart';

class NumberRowScene extends StatefulWidget {
  const NumberRowScene({super.key, required this.studyDigit});

  final int studyDigit;

  @override
  State<NumberRowScene> createState() => _NumberRowSceneState();
}

class _NumberRowSceneState extends State<NumberRowScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slots = getNumberRowSlots();
    final studyDigit = normalizeStudyDigit(widget.studyDigit);

    return FittedBox(
      child: SizedBox(
        width: NumberRowLayout.width,
        height: NumberRowLayout.height,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            return CustomPaint(
              painter: _NumberRowPainter(
                slots: slots,
                studyDigit: studyDigit,
                pulse: _pulse.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NumberRowPainter extends CustomPainter {
  _NumberRowPainter({
    required this.slots,
    required this.studyDigit,
    required this.pulse,
  });

  final List<DigitSlot> slots;
  final int studyDigit;
  final double pulse;

  static const _inactiveColor = Color(0xFF1F2937);
  static const _activeColors = [
    Color(0xFFDC2626),
    Color(0xFFEF4444),
    Color(0xFFDC2626),
  ];
  static const _baselineColor = Color(0xFFD1D5DB);

  @override
  void paint(Canvas canvas, Size size) {
    final baselinePaint = Paint()
      ..color = _baselineColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(NumberRowLayout.paddingX - 4, NumberRowLayout.baselineY + 18),
      Offset(
        NumberRowLayout.width - NumberRowLayout.paddingX + 4,
        NumberRowLayout.baselineY + 18,
      ),
      baselinePaint,
    );

    for (final slot in slots) {
      if (isStudyDigit(slot.digit, studyDigit)) {
        _paintActiveDigit(canvas, slot);
      } else {
        _paintInactiveDigit(canvas, slot);
      }
    }
  }

  void _paintInactiveDigit(Canvas canvas, DigitSlot slot) {
    final painter = TextPainter(
      text: TextSpan(
        text: '${slot.digit}',
        style: const TextStyle(
          fontSize: NumberRowLayout.inactiveFontSize,
          fontWeight: FontWeight.w600,
          color: _inactiveColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(
        slot.x - painter.width / 2,
        NumberRowLayout.baselineY - painter.height / 2,
      ),
    );
  }

  void _paintActiveDigit(Canvas canvas, DigitSlot slot) {
    final scale = 1 + pulse * 0.08;
    final bounceY = NumberRowLayout.baselineY - 4 * math.sin(pulse * math.pi);
    final colorIndex = (pulse * (_activeColors.length - 1)).round()
        .clamp(0, _activeColors.length - 1);
    final color = _activeColors[colorIndex];

    canvas.save();
    canvas.translate(slot.x, bounceY);
    canvas.scale(scale);

    final painter = TextPainter(
      text: TextSpan(
        text: '${slot.digit}',
        style: TextStyle(
          fontSize: NumberRowLayout.activeFontSize,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(-painter.width / 2, -painter.height / 2),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NumberRowPainter oldDelegate) {
    return oldDelegate.studyDigit != studyDigit ||
        oldDelegate.pulse != pulse ||
        oldDelegate.slots != slots;
  }
}
