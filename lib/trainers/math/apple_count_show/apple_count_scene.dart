import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_reveal.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_show_choreography.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_show_geometry.dart';
import 'package:larnes_mobile/trainers/math/apple_count_show/apple_count_sizes.dart';

/// Web v2: `platform/src/trainers/math/apple-count-show/apple-count-scene.tsx`
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
    with TickerProviderStateMixin {
  Ticker? _dropTicker;
  Ticker? _settleTicker;
  var _elapsedMs = 0.0;
  var _isSettlePulseActive = false;
  var _settlePhaseMs = 0.0;

  @override
  void initState() {
    super.initState();
    _restartAnimation();
  }

  @override
  void didUpdateWidget(AppleCountScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sceneKey != widget.sceneKey ||
        oldWidget.appleCount != widget.appleCount) {
      _restartAnimation();
    }
  }

  void _restartAnimation() {
    _dropTicker?.dispose();
    _settleTicker?.dispose();
    _elapsedMs = 0;
    _isSettlePulseActive = false;
    _settlePhaseMs = 0;

    final dropCompleteMs = getAppleDropCompleteMs(widget.appleCount);
    final startedAt = DateTime.now().millisecondsSinceEpoch;

    _dropTicker = createTicker((elapsed) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final nextElapsed = (now - startedAt).toDouble();

      if (nextElapsed >= dropCompleteMs) {
        if (!_isSettlePulseActive) {
          setState(() {
            _elapsedMs = dropCompleteMs.toDouble();
            _isSettlePulseActive = true;
          });
          _startSettlePulse();
        }
        return;
      }

      setState(() => _elapsedMs = nextElapsed);
    })..start();

    if (dropCompleteMs == 0) {
      _isSettlePulseActive = true;
      _startSettlePulse();
    }
  }

  void _startSettlePulse() {
    _dropTicker?.stop();
    _settleTicker?.dispose();

    final startedAt = DateTime.now().millisecondsSinceEpoch;
    _settleTicker = createTicker((_) {
      final now = DateTime.now().millisecondsSinceEpoch;
      setState(() {
        _settlePhaseMs = (now - startedAt) % appleSettlePulseMs.toDouble();
      });
    })..start();
  }

  double get _basketRevealProgress {
    return (_elapsedMs / appleBasketRevealMs).clamp(0.0, 1.0);
  }

  double get _settlePulseWave {
    if (!_isSettlePulseActive) {
      return 0;
    }

    final t = _settlePhaseMs / appleSettlePulseMs;
    return t < 0.5 ? t * 2 : (1 - t) * 2;
  }

  @override
  void dispose() {
    _dropTicker?.dispose();
    _settleTicker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = buildAppleDropSequence(widget.appleCount);
    final pulseOriginY =
        AppleSceneLayout.basketTopY + AppleSceneLayout.basketBodyDepth * 0.42;

    return SizedBox(
      width: AppleSceneLayout.width,
      height: AppleSceneLayout.height,
      child: CustomPaint(
        painter: _AppleCountScenePainter(
          steps: steps,
          elapsedMs: _elapsedMs,
          basketRevealProgress: Curves.easeOutBack.transform(_basketRevealProgress),
          settleScale: 1 + 0.035 * _settlePulseWave,
          settleDy: -3 * _settlePulseWave,
          pulseOriginX: AppleSceneLayout.basketCenterX,
          pulseOriginY: pulseOriginY,
        ),
      ),
    );
  }
}

class _AppleCountScenePainter extends CustomPainter {
  _AppleCountScenePainter({
    required this.steps,
    required this.elapsedMs,
    required this.basketRevealProgress,
    required this.settleScale,
    required this.settleDy,
    required this.pulseOriginX,
    required this.pulseOriginY,
  });

  final List<AppleMotionStep> steps;
  final double elapsedMs;
  final double basketRevealProgress;
  final double settleScale;
  final double settleDy;
  final double pulseOriginX;
  final double pulseOriginY;

  static final _flightEase = Cubic(0.22, 1.1, 0.36, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final revealOpacity = basketRevealProgress.clamp(0.0, 1.0);
    final revealScale = 0.94 + 0.06 * basketRevealProgress;
    final revealDy = 10 * (1 - basketRevealProgress);

    canvas.save();
    canvas.translate(pulseOriginX, pulseOriginY);
    canvas.scale(settleScale, settleScale);
    canvas.translate(-pulseOriginX, -pulseOriginY + revealDy + settleDy);

    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Color.fromRGBO(255, 255, 255, revealOpacity),
    );

    canvas.translate(pulseOriginX, pulseOriginY);
    canvas.scale(revealScale, revealScale);
    canvas.translate(-pulseOriginX, -pulseOriginY);

    _paintBasket(canvas);

    for (final step in steps) {
      _paintApple(canvas, step);
    }

    canvas.restore();
    canvas.restore();
  }

  void _paintBasket(Canvas canvas) {
    final left = AppleSceneLayout.basketCenterX - AppleSceneLayout.basketHalfWidth;
    final right = AppleSceneLayout.basketCenterX + AppleSceneLayout.basketHalfWidth;
    final bottom = AppleSceneLayout.basketTopY + AppleSceneLayout.basketBodyDepth;
    const rimInset = 14.0;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(AppleSceneLayout.basketCenterX, bottom + 10),
        width: AppleSceneLayout.basketHalfWidth * 1.64,
        height: 20,
      ),
      Paint()..color = const Color(0x12000000),
    );

    final basketPath = Path()
      ..moveTo(left + rimInset, AppleSceneLayout.basketTopY)
      ..lineTo(right - rimInset, AppleSceneLayout.basketTopY)
      ..lineTo(right, bottom)
      ..quadraticBezierTo(
        AppleSceneLayout.basketCenterX,
        bottom + 20,
        left,
        bottom,
      )
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
        ..strokeWidth = 2.5,
    );

    final handlePath = Path()
      ..moveTo(left + 22, AppleSceneLayout.basketTopY)
      ..quadraticBezierTo(
        AppleSceneLayout.basketCenterX,
        AppleSceneLayout.basketTopY - AppleSceneLayout.basketRimLift,
        right - 22,
        AppleSceneLayout.basketTopY,
      );

    canvas.drawPath(
      handlePath,
      Paint()
        ..color = const Color(0xFF8D6E43)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round,
    );

    for (final y in [
      AppleSceneLayout.basketTopY + 18,
      AppleSceneLayout.basketTopY + 42,
      AppleSceneLayout.basketTopY + 66,
      AppleSceneLayout.basketTopY + 90,
    ]) {
      canvas.drawLine(
        Offset(left + 28, y),
        Offset(right - 28, y),
        Paint()
          ..color = const Color(0xFFC49A6C)
          ..strokeWidth = 2.5,
      );
    }
  }

  void _paintApple(Canvas canvas, AppleMotionStep step) {
    final localMs = elapsedMs - appleBasketRevealMs - step.delayMs;
    if (localMs < 0) {
      return;
    }

    final flightT = (localMs / appleFlightDurationMs).clamp(0.0, 1.0);
    final eased = _flightEase.transform(flightT);
    final x = _lerp(step.from.x, step.to.x, eased);
    final y = _lerp(step.from.y, step.to.y, eased);

    final opacityT = (localMs / 200).clamp(0.0, 1.0);
    final scaleT = flightT < 0.72
        ? 0.5 + 0.5 * (flightT / 0.72)
        : 0.8 +
            0.2 *
                Curves.easeOutBack
                    .transform(((flightT - 0.72) / 0.28).clamp(0.0, 1.0))
                    .clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(x, y);
    canvas.scale(scaleT);
    _drawApple(canvas, opacity: opacityT);
    canvas.restore();
  }

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
    return oldDelegate.elapsedMs != elapsedMs ||
        oldDelegate.basketRevealProgress != basketRevealProgress ||
        oldDelegate.settleScale != settleScale ||
        oldDelegate.settleDy != settleDy ||
        oldDelegate.steps != steps;
  }
}
