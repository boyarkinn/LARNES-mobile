import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_guides.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_trace_model.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/trace_score_display.dart';

const _viewBoxSize = 100.0;
const _minPointDistance = 1.2;

class TracePad extends StatefulWidget {
  const TracePad({
    super.key,
    required this.digit,
    this.disabled = false,
    required this.onScored,
  });

  final int digit;
  final bool disabled;
  final ValueChanged<int> onScored;

  @override
  State<TracePad> createState() => _TracePadState();
}

class _TracePadState extends State<TracePad> {
  final _strokes = <TraceStroke>[];
  final _displayStrokes = <List<TracePoint>>[];
  final _activeStroke = <TracePoint>[];
  var _drawing = false;
  var _scored = false;
  int? _similarityPercent;

  void _updateScore(List<TraceStroke> nextStrokes) {
    final result = scoreTrace(widget.digit, nextStrokes);

    if (result.similarityPercent == null) {
      return;
    }

    setState(() => _similarityPercent = result.similarityPercent);

    if (!_scored) {
      _scored = true;
      widget.onScored(result.similarityPercent!);
    }
  }

  TracePoint _localToViewBox(Offset local, Size size) {
    return TracePoint(
      x: (local.dx / size.width) * _viewBoxSize,
      y: (local.dy / size.height) * _viewBoxSize,
    );
  }

  TracePoint _toNormalized(TracePoint point) {
    return TracePoint(
      x: point.x / _viewBoxSize,
      y: point.y / _viewBoxSize,
    );
  }

  void _handlePointerDown(PointerDownEvent event, Size size) {
    if (widget.disabled) {
      return;
    }

    _drawing = true;
    final point = _localToViewBox(event.localPosition, size);
    setState(() {
      _activeStroke
        ..clear()
        ..add(point);
    });
  }

  void _handlePointerMove(PointerMoveEvent event, Size size) {
    if (!_drawing || widget.disabled) {
      return;
    }

    final point = _localToViewBox(event.localPosition, size);
    final last = _activeStroke.isEmpty ? null : _activeStroke.last;

    if (last != null) {
      final dx = last.x - point.x;
      final dy = last.y - point.y;
      if (math.sqrt(dx * dx + dy * dy) < _minPointDistance) {
        return;
      }
    }

    setState(() => _activeStroke.add(point));
  }

  void _handlePointerEnd() {
    if (!_drawing) {
      return;
    }

    _drawing = false;

    if (_activeStroke.length < 2) {
      setState(() => _activeStroke.clear());
      return;
    }

    final normalizedStroke = _activeStroke.map(_toNormalized).toList();
    final nextStrokes = [..._strokes, normalizedStroke];
    final displayStroke = List<TracePoint>.from(_activeStroke);

    setState(() {
      _strokes
        ..clear()
        ..addAll(nextStrokes);
      _displayStrokes.add(displayStroke);
      _activeStroke.clear();
    });

    _updateScore(nextStrokes);
  }

  void _handleClear() {
    if (widget.disabled) {
      return;
    }

    setState(() {
      _drawing = false;
      _scored = false;
      _similarityPercent = null;
      _strokes.clear();
      _displayStrokes.clear();
      _activeStroke.clear();
    });
  }

  Color get _strokeColor {
    if (_similarityPercent != null && _similarityPercent! >= 70) {
      return const Color(0xFF22C55E);
    }
    return const Color(0xFF4F46E5);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          label: 'Обведи цифру ${widget.digit}',
          child: AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);

                return Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) => _handlePointerDown(event, size),
                  onPointerMove: (event) => _handlePointerMove(event, size),
                  onPointerUp: (_) => _handlePointerEnd(),
                  onPointerCancel: (_) => _handlePointerEnd(),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE0E7FF), width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: CustomPaint(
                        painter: _TracePadPainter(
                          digit: widget.digit,
                          displayStrokes: _displayStrokes,
                          activeStroke: _activeStroke,
                          strokeColor: _strokeColor,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 96,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_similarityPercent != null)
                TraceScoreDisplay(percent: _similarityPercent!),
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.disabled ||
                        (_strokes.isEmpty && _activeStroke.isEmpty)
                    ? null
                    : _handleClear,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4B5563),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'Стереть и попробовать снова',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TracePadPainter extends CustomPainter {
  _TracePadPainter({
    required this.digit,
    required this.displayStrokes,
    required this.activeStroke,
    required this.strokeColor,
  });

  final int digit;
  final List<List<TracePoint>> displayStrokes;
  final List<TracePoint> activeStroke;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF8FAFC),
    );

    _paintGuideDigit(canvas, size);

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in displayStrokes) {
      _paintStroke(canvas, size, stroke, strokePaint);
    }

    if (activeStroke.isNotEmpty) {
      _paintStroke(canvas, size, activeStroke, strokePaint);
    }
  }

  void _paintGuideDigit(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$digit',
        style: TextStyle(
          fontSize: size.width * 0.72,
          fontWeight: FontWeight.w700,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.width * 0.05
            ..color = const Color(0xFFCBD5E1),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    final offset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2 + size.height * 0.04,
    );

    textPainter.paint(canvas, offset);
  }

  void _paintStroke(
    Canvas canvas,
    Size size,
    List<TracePoint> stroke,
    Paint paint,
  ) {
    if (stroke.isEmpty) {
      return;
    }

    final path = Path();
    final first = stroke.first;
    path.moveTo(
      first.x / _viewBoxSize * size.width,
      first.y / _viewBoxSize * size.height,
    );

    for (var index = 1; index < stroke.length; index++) {
      final point = stroke[index];
      path.lineTo(
        point.x / _viewBoxSize * size.width,
        point.y / _viewBoxSize * size.height,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TracePadPainter oldDelegate) {
    return oldDelegate.digit != digit ||
        oldDelegate.displayStrokes != displayStrokes ||
        oldDelegate.activeStroke != activeStroke ||
        oldDelegate.strokeColor != strokeColor;
  }
}
