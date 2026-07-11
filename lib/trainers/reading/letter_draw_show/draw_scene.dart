import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/reading/letter_draw_show/draw_show_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_draw_show/draw_show_sizes.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_field_scene.dart';
import 'package:larnes_mobile/trainers/reading/zaitsev/path_geometry.dart';
import 'package:larnes_mobile/trainers/reading/zaitsev/zaitsev_types.dart';

/// Web: `platform/src/trainers/reading/letter-draw-show/draw-scene.tsx`
class DrawScene extends StatefulWidget {
  const DrawScene({
    super.key,
    required this.drawing,
    required this.onRoundComplete,
    this.settlePulseActive = false,
  });

  final ZaitsevLetterDrawing drawing;
  final VoidCallback onRoundComplete;
  final bool settlePulseActive;

  @override
  State<DrawScene> createState() => _DrawSceneState();
}

class _DrawSceneState extends State<DrawScene> with TickerProviderStateMixin {
  var _completedCount = 0;
  var _activeIndex = 0;

  AnimationController? _strokeController;
  Animation<double>? _strokeProgress;
  late final AnimationController _pulseController;

  Timer? _pauseTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this);
    _resetStrokeState();
    _syncPulse();
    _startActiveStroke();
  }

  @override
  void didUpdateWidget(DrawScene oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.drawing != widget.drawing) {
      _pauseTimer?.cancel();
      _disposeStrokeController();
      _resetStrokeState();
      _startActiveStroke();
    }

    if (oldWidget.settlePulseActive != widget.settlePulseActive) {
      _syncPulse();
    }
  }

  void _resetStrokeState() {
    _completedCount = 0;
    _activeIndex = 0;
  }

  void _syncPulse() {
    _pulseController.stop();

    if (widget.settlePulseActive) {
      _pulseController
        ..duration = const Duration(milliseconds: drawSettlePulseMs)
        ..repeat(reverse: true);
      return;
    }

    _pulseController.value = 0;
  }

  void _disposeStrokeController() {
    _strokeController?.dispose();
    _strokeController = null;
    _strokeProgress = null;
  }

  void _startActiveStroke() {
    if (_activeIndex >= widget.drawing.strokes.length) {
      return;
    }

    _disposeStrokeController();

    final stroke = widget.drawing.strokes[_activeIndex];
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: stroke.durationMs),
    );
    final progress = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _handleStrokeComplete();
      }
    });

    _strokeController = controller;
    _strokeProgress = progress;
    controller.forward();
    setState(() {});
  }

  void _handleStrokeComplete() {
    setState(() => _completedCount += 1);
    _pauseTimer?.cancel();

    if (_activeIndex + 1 < widget.drawing.strokes.length) {
      _pauseTimer = Timer(
        const Duration(milliseconds: drawShowStrokePauseMs),
        () {
          if (!mounted) {
            return;
          }

          setState(() => _activeIndex += 1);
          _startActiveStroke();
        },
      );
      return;
    }

    _pauseTimer = Timer(
      const Duration(milliseconds: drawShowRoundPauseMs),
      () {
        if (mounted) {
          widget.onRoundComplete();
        }
      },
    );
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _disposeStrokeController();
    _pulseController.dispose();
    super.dispose();
  }

  double _pulseScale() {
    if (!widget.settlePulseActive) {
      return 1;
    }

    return 1 + 0.04 * math.sin(_pulseController.value * math.pi);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = drawShowBoxSize(
          constraints.maxHeight,
          constraints.maxWidth,
        );

        return AnimatedBuilder(
          animation: Listenable.merge([
            _pulseController,
            if (_strokeController != null) _strokeController!,
          ]),
          builder: (context, _) {
            final activeProgress = _strokeProgress?.value ?? 0;

            return Transform.scale(
              scale: _pulseScale(),
              alignment: Alignment.center,
              child: SizedBox(
                width: boxSize,
                height: boxSize,
                child: CustomPaint(
                  painter: _DrawLetterPainter(
                    drawing: widget.drawing,
                    completedCount: _completedCount,
                    activeIndex: _activeIndex,
                    activeProgress: activeProgress,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DrawLetterPainter extends CustomPainter {
  const _DrawLetterPainter({
    required this.drawing,
    required this.completedCount,
    required this.activeIndex,
    required this.activeProgress,
  });

  final ZaitsevLetterDrawing drawing;
  final int completedCount;
  final int activeIndex;
  final double activeProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final viewBoxSize = parseZaitsevViewBoxSize(drawing.viewBox);
    final scale = size.width / viewBoxSize;

    canvas.save();
    canvas.scale(scale);

    for (var index = 0; index < drawing.strokes.length; index++) {
      final isDone = index < completedCount;
      final isActive = index == activeIndex && completedCount == activeIndex;

      if (!isDone && !isActive) {
        continue;
      }

      final progress = isDone ? 1.0 : activeProgress;
      _paintStroke(
        canvas,
        drawing.strokes[index].path,
        drawing.strokeWidth,
        letterDisplayColorFromHex(getStrokeColor(index)),
        progress,
      );
    }

    canvas.restore();
  }

  void _paintStroke(
    Canvas canvas,
    String path,
    double strokeWidth,
    Color color,
    double progress,
  ) {
    if (progress <= 0) {
      return;
    }

    final sourcePath = buildZaitsevSvgPath(path);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (progress >= 1) {
      canvas.drawPath(sourcePath, paint);
      return;
    }

    for (final metric in sourcePath.computeMetrics()) {
      canvas.drawPath(
        metric.extractPath(0, metric.length * progress),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DrawLetterPainter oldDelegate) {
    return oldDelegate.drawing != drawing ||
        oldDelegate.completedCount != completedCount ||
        oldDelegate.activeIndex != activeIndex ||
        oldDelegate.activeProgress != activeProgress;
  }
}
