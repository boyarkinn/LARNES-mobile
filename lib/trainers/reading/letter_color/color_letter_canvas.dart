import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_paths.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/trace_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_color/letter_color_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_field_scene.dart';

/// Web: `platform/src/trainers/reading/letter-color/color-letter-canvas.tsx`

class ColorLetterCanvasController {
  VoidCallback? _clear;
  bool Function()? _hasInk;

  void clear() => _clear?.call();

  bool get hasInk => _hasInk?.call() ?? false;

  void bind({
    required VoidCallback clear,
    required bool Function() hasInk,
  }) {
    _clear = clear;
    _hasInk = hasInk;
  }

  void unbind() {
    _clear = null;
    _hasInk = null;
  }
}

class ColorLetterCanvas extends StatefulWidget {
  const ColorLetterCanvas({
    super.key,
    required this.displayLetter,
    required this.selectedColor,
    this.controller,
    this.disabled = false,
    this.fontSize = colorLetterFontSize,
    this.onInkChange,
    this.revealDelayMs = 0,
    this.semanticsLabel,
  });

  final String displayLetter;
  final String selectedColor;
  final ColorLetterCanvasController? controller;
  final bool disabled;
  final double fontSize;
  final ValueChanged<bool>? onInkChange;
  final int revealDelayMs;
  final String? semanticsLabel;

  @override
  State<ColorLetterCanvas> createState() => _ColorLetterCanvasState();
}

class _ColorLetterCanvasState extends State<ColorLetterCanvas>
    with SingleTickerProviderStateMixin {
  final _strokes = <ColorStroke>[];
  final _strokeColors = <String>[];
  final _activeStroke = <TracePoint>[];
  var _drawing = false;
  late final AnimationController _outlineController;
  late final Animation<double> _outlineProgress;
  Timer? _revealTimer;

  @override
  void initState() {
    super.initState();
    _outlineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: traceGuidePopDurationMs),
    );
    _outlineProgress = CurvedAnimation(
      parent: _outlineController,
      curve: Curves.easeOutBack,
    );
    _bindController();
    _scheduleOutlineReveal();
  }

  @override
  void didUpdateWidget(ColorLetterCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.displayLetter != widget.displayLetter) {
      _clearInk(notify: true);
      _scheduleOutlineReveal(resetAnimation: true);
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.unbind();
      _bindController();
    }
  }

  void _bindController() {
    widget.controller?.bind(
      clear: () => _clearInk(notify: true),
      hasInk: () => _strokes.isNotEmpty || _activeStroke.isNotEmpty,
    );
  }

  void _scheduleOutlineReveal({bool resetAnimation = false}) {
    _revealTimer?.cancel();

    if (widget.revealDelayMs <= 0) {
      if (resetAnimation) {
        _outlineController.forward(from: 0);
      } else {
        _outlineController.forward();
      }
      return;
    }

    _revealTimer = Timer(Duration(milliseconds: widget.revealDelayMs), () {
      if (mounted) {
        _outlineController.forward(from: 0);
      }
    });
  }

  void _reportInk() {
    widget.onInkChange?.call(
      _strokes.isNotEmpty || _activeStroke.isNotEmpty,
    );
  }

  void _clearInk({required bool notify}) {
    _drawing = false;
    setState(() {
      _strokes.clear();
      _strokeColors.clear();
      _activeStroke.clear();
    });
    if (notify) {
      _reportInk();
    }
  }

  TracePoint _localToViewBox(Offset local, Size size) {
    return TracePoint(
      x: (local.dx / size.width) * colorViewboxSize,
      y: (local.dy / size.height) * colorViewboxSize,
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
    _reportInk();
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
      if (math.sqrt(dx * dx + dy * dy) < colorMinPointDistance) {
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
      _reportInk();
      return;
    }

    setState(() {
      _strokes.add(List<TracePoint>.from(_activeStroke));
      _strokeColors.add(widget.selectedColor);
      _activeStroke.clear();
    });
    _reportInk();
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    widget.controller?.unbind();
    _outlineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.semanticsLabel ?? 'Разукрась букву ${widget.displayLetter}';

    return Semantics(
      label: label,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);

          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) => _handlePointerDown(event, size),
            onPointerMove: (event) => _handlePointerMove(event, size),
            onPointerUp: (_) => _handlePointerEnd(),
            onPointerCancel: (_) => _handlePointerEnd(),
            child: AnimatedBuilder(
              animation: _outlineProgress,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ColorLetterCanvasPainter(
                    activeStroke: _activeStroke,
                    displayLetter: widget.displayLetter,
                    fontSize: widget.fontSize,
                    outlineProgress: _outlineProgress.value.clamp(0.0, 1.0),
                    selectedColor: widget.selectedColor,
                    strokeColors: _strokeColors,
                    strokes: _strokes,
                  ),
                  child: child,
                );
              },
              child: const SizedBox.expand(),
            ),
          );
        },
      ),
    );
  }
}

class _ColorLetterCanvasPainter extends CustomPainter {
  _ColorLetterCanvasPainter({
    required this.displayLetter,
    required this.fontSize,
    required this.strokes,
    required this.strokeColors,
    required this.activeStroke,
    required this.selectedColor,
    required this.outlineProgress,
  });

  final String displayLetter;
  final double fontSize;
  final List<ColorStroke> strokes;
  final List<String> strokeColors;
  final List<TracePoint> activeStroke;
  final String selectedColor;
  final double outlineProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final letterStyle = _letterTextStyle(size);
    final letterCenter = Offset(
      size.width * (colorLetterCenterX / colorViewboxSize),
      size.height * (colorLetterCenterY / colorViewboxSize),
    );

    canvas.saveLayer(Offset.zero & size, Paint());
    _paintClippedStrokes(canvas, size, letterStyle, letterCenter);
    canvas.restore();

    _paintOutline(canvas, size, letterStyle, letterCenter);
  }

  void _paintClippedStrokes(
    Canvas canvas,
    Size size,
    TextStyle letterStyle,
    Offset letterCenter,
  ) {
    canvas.saveLayer(Offset.zero & size, Paint());

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * (colorStrokeWidth / colorViewboxSize)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var index = 0; index < strokes.length; index++) {
      strokePaint.color = letterDisplayColorFromHex(
        strokeColors[index],
      );
      _paintPolyline(canvas, size, strokes[index], strokePaint);
    }

    if (activeStroke.isNotEmpty) {
      strokePaint.color = letterDisplayColorFromHex(selectedColor);
      _paintPolyline(canvas, size, activeStroke, strokePaint);
    }

    canvas.saveLayer(Offset.zero & size, Paint()..blendMode = BlendMode.dstIn);
    _paintLetterMask(canvas, size, letterStyle, letterCenter);
    canvas.restore();
    canvas.restore();
  }

  void _paintOutline(
    Canvas canvas,
    Size size,
    TextStyle letterStyle,
    Offset letterCenter,
  ) {
    final progress = outlineProgress.clamp(0.0, 1.0);
    if (progress <= 0) {
      return;
    }

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * (colorOutlineStrokeWidth / colorViewboxSize)
      ..color = letterDisplayColorFromHex(colorOutlineStrokeHex)
          .withValues(alpha: progress)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final textPainter = _buildTextPainter(
      letterStyle.copyWith(foreground: outlinePaint),
    );
    final offset = _letterOffset(textPainter, letterCenter);

    canvas.save();
    canvas.translate(letterCenter.dx, letterCenter.dy);
    canvas.scale(0.88 + 0.12 * progress);
    canvas.translate(-letterCenter.dx, -letterCenter.dy);
    textPainter.paint(canvas, offset);
    canvas.restore();
  }

  void _paintLetterMask(
    Canvas canvas,
    Size size,
    TextStyle letterStyle,
    Offset letterCenter,
  ) {
    final textPainter = _buildTextPainter(
      letterStyle.copyWith(color: Colors.white),
    );
    textPainter.paint(canvas, _letterOffset(textPainter, letterCenter));
  }

  TextStyle _letterTextStyle(Size size) {
    final scaledFontSize = fontSize * size.width / colorViewboxSize;

    return TextStyle(
      fontSize: scaledFontSize,
      fontWeight: FontWeight.w700,
      height: 1,
    );
  }

  TextPainter _buildTextPainter(TextStyle style) {
    return TextPainter(
      text: TextSpan(text: displayLetter, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
  }

  Offset _letterOffset(TextPainter textPainter, Offset letterCenter) {
    return Offset(
      letterCenter.dx - textPainter.width / 2,
      letterCenter.dy - textPainter.height / 2,
    );
  }

  void _paintPolyline(
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
      first.x / colorViewboxSize * size.width,
      first.y / colorViewboxSize * size.height,
    );

    for (var index = 1; index < stroke.length; index++) {
      final point = stroke[index];
      path.lineTo(
        point.x / colorViewboxSize * size.width,
        point.y / colorViewboxSize * size.height,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ColorLetterCanvasPainter oldDelegate) {
    return oldDelegate.displayLetter != displayLetter ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.strokes != strokes ||
        oldDelegate.strokeColors != strokeColors ||
        oldDelegate.activeStroke != activeStroke ||
        oldDelegate.selectedColor != selectedColor ||
        oldDelegate.outlineProgress != outlineProgress;
  }
}
