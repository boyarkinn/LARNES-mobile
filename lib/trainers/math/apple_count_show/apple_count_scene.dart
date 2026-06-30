import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_show_choreography.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_show_geometry.dart';

class AppleCountScene extends StatefulWidget {
  const AppleCountScene({
    super.key,
    required this.appleCount,
    required this.sceneKey,
  });

  final int appleCount;
  final String sceneKey;

  @override
  State<AppleCountScene> createState() => _AppleCountSceneState();
}

class _AppleCountSceneState extends State<AppleCountScene>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  @override
  void didUpdateWidget(AppleCountScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sceneKey != widget.sceneKey ||
        oldWidget.appleCount != widget.appleCount) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _controller?.dispose();
    final durationMs = appleDropTotalDurationMs(widget.appleCount);
    if (durationMs == 0) {
      _controller = null;
      return;
    }

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    )..forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = buildAppleDropSequence(widget.appleCount);

    Widget painted(double progressMs) {
      return CustomPaint(
        painter: _AppleCountScenePainter(
          steps: steps,
          elapsedMs: progressMs,
        ),
        size: const Size(
          AppleSceneLayout.width,
          AppleSceneLayout.height,
        ),
      );
    }

    if (_controller == null) {
      return FittedBox(child: painted(appleDropTotalDurationMs(widget.appleCount).toDouble()));
    }

    return FittedBox(
      child: AnimatedBuilder(
        animation: _controller!,
        builder: (context, child) {
          final elapsedMs = _controller!.value *
              appleDropTotalDurationMs(widget.appleCount);
          return painted(elapsedMs);
        },
      ),
    );
  }
}

class _AppleCountScenePainter extends CustomPainter {
  _AppleCountScenePainter({
    required this.steps,
    required this.elapsedMs,
  });

  final List<AppleMotionStep> steps;
  final double elapsedMs;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, size.height),
        const [Color(0xFFFFF8E7), Color(0xFFFFE8F0)],
      );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ),
      background,
    );

    _paintBasket(canvas);

    for (final step in steps) {
      _paintApple(canvas, step);
    }
  }

  void _paintBasket(Canvas canvas) {
    final left = AppleSceneLayout.basketCenterX - 78;
    final right = AppleSceneLayout.basketCenterX + 78;
    final bottom = AppleSceneLayout.basketTopY + 88;

    final basketPath = Path()
      ..moveTo(left + 12, AppleSceneLayout.basketTopY)
      ..lineTo(right - 12, AppleSceneLayout.basketTopY)
      ..lineTo(right, bottom)
      ..quadraticBezierTo(AppleSceneLayout.basketCenterX, bottom + 18, left, bottom)
      ..close();

    canvas.drawPath(
      basketPath,
      Paint()
        ..color = const Color(0xFFD7A86E)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      basketPath,
      Paint()
        ..color = const Color(0xFFB8864E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final handlePath = Path()
      ..moveTo(left + 18, AppleSceneLayout.basketTopY)
      ..quadraticBezierTo(
        AppleSceneLayout.basketCenterX,
        AppleSceneLayout.basketTopY - 28,
        right - 18,
        AppleSceneLayout.basketTopY,
      );

    canvas.drawPath(
      handlePath,
      Paint()
        ..color = const Color(0xFF8D6E43)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    for (final y in [
      AppleSceneLayout.basketTopY + 14,
      AppleSceneLayout.basketTopY + 34,
      AppleSceneLayout.basketTopY + 54,
    ]) {
      canvas.drawLine(
        Offset(left + 24, y),
        Offset(right - 24, y),
        Paint()
          ..color = const Color(0xFFC49A6C)
          ..strokeWidth = 2,
      );
    }
  }

  void _paintApple(Canvas canvas, AppleMotionStep step) {
    final localMs = elapsedMs - step.delayMs;
    if (localMs < 0) {
      return;
    }

    final flightT = (localMs / appleFlightDurationMs).clamp(0.0, 1.0);
    final eased = _flightEase.transform(flightT);
    final x = _lerp(step.from.x, step.to.x, eased);
    final y = _lerp(step.from.y, step.to.y, eased);

    final opacityT = (localMs / 200).clamp(0.0, 1.0);
    final scaleT = flightT < 0.7
        ? 0.45 + 0.35 * (flightT / 0.7)
        : 0.8 +
            0.2 *
                Curves.easeOutBack
                    .transform(((flightT - 0.7) / 0.3).clamp(0.0, 1.0))
                    .clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(x, y);
    canvas.scale(scaleT);
    _drawApple(canvas, opacity: opacityT);
    canvas.restore();
  }

  static final _flightEase = Cubic(0.22, 1.1, 0.36, 1.0);

  double _lerp(double from, double to, double t) => from + (to - from) * t;

  void _drawApple(Canvas canvas, {required double opacity}) {
    const r = AppleSceneLayout.appleRadius;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, r * 0.35),
        width: r * 1.7,
        height: r * 0.44,
      ),
      Paint()..color = const Color(0x18000000).withValues(alpha: opacity),
    );

    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = const Color(0xFFFF5A5A).withValues(alpha: opacity)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = const Color(0xFFE53935).withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawCircle(
      Offset(-r * 0.28, -r * 0.22),
      r * 0.22,
      Paint()..color = const Color(0x55FFFFFF).withValues(alpha: opacity),
    );

    final stem = Path()
      ..moveTo(0, -r * 0.95)
      ..cubicTo(r * 0.15, -r * 1.2, r * 0.35, -r * 1.05, r * 0.2, -r * 0.75);

    canvas.drawPath(
      stem,
      Paint()
        ..color = const Color(0xFF6D4C41).withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(r * 0.28, -r * 0.82),
        width: r * 0.68,
        height: r * 0.36,
      ),
      Paint()..color = const Color(0xFF81C784).withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(covariant _AppleCountScenePainter oldDelegate) {
    return oldDelegate.elapsedMs != elapsedMs || oldDelegate.steps != steps;
  }
}
