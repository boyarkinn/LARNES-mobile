import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_found_burst.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_paths.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/trace_feedback.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/trace_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_color/color_palette.dart';
import 'package:larnes_mobile/trainers/reading/letter_color/letter_color_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_field_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_half_draw/half_draw_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_half_draw/half_draw_pad_size.dart';

const _minPointDistance = colorMinPointDistance;
const _wrongShakeMs = 550;
const _popCurve = Cubic(0.34, 1.2, 0.64, 1);

/// Web v2: `platform/src/trainers/reading/letter-half-draw/half-draw-pad.tsx`
class HalfDrawPad extends StatefulWidget {
  const HalfDrawPad({
    super.key,
    required this.displayLetter,
    required this.guideLetter,
    this.disabled = false,
    required this.onPassed,
  });

  final String displayLetter;
  final String guideLetter;
  final bool disabled;
  final ValueChanged<int> onPassed;

  @override
  State<HalfDrawPad> createState() => _HalfDrawPadState();
}

class _HalfDrawPadState extends State<HalfDrawPad>
    with SingleTickerProviderStateMixin {
  final _strokes = <TraceStroke>[];
  final _displayStrokes = <List<TracePoint>>[];
  final _activeStroke = <TracePoint>[];

  var _selectedColor = drawColors.first;
  var _drawing = false;
  var _passed = false;
  var _isShaking = false;
  int? _similarityPercent;

  Timer? _shakeTimer;
  late final AnimationController _letterPopController;
  late final Animation<double> _letterPopProgress;

  @override
  void initState() {
    super.initState();
    _letterPopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: traceGuidePopDurationMs),
    );
    _letterPopProgress = CurvedAnimation(
      parent: _letterPopController,
      curve: _popCurve,
    );
    _letterPopController.forward();
  }

  @override
  void didUpdateWidget(HalfDrawPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.guideLetter != widget.guideLetter ||
        oldWidget.displayLetter != widget.displayLetter) {
      _resetForLetter();
    }
  }

  void _resetForLetter() {
    _shakeTimer?.cancel();
    _drawing = false;
    _passed = false;
    _isShaking = false;
    _similarityPercent = null;
    _selectedColor = drawColors.first;
    _strokes.clear();
    _displayStrokes.clear();
    _activeStroke.clear();
    _letterPopController.forward(from: 0);
  }

  bool get _isInteractionLocked => widget.disabled || _passed;

  double get _splitLineViewbox => halfDrawSplitLineViewboxX();

  Color get _selectedColorValue => letterDisplayColorFromHex(_selectedColor);

  Color get _committedStrokeColor => getTraceStrokeColor(
        _similarityPercent,
        _selectedColorValue,
      );

  void _triggerLowScoreShake() {
    _shakeTimer?.cancel();
    setState(() => _isShaking = true);
    _shakeTimer = Timer(const Duration(milliseconds: _wrongShakeMs), () {
      if (mounted) {
        setState(() => _isShaking = false);
      }
    });
  }

  void _updateScore(List<TraceStroke> nextStrokes) {
    final result = scoreLetterHalfDraw(widget.guideLetter, nextStrokes);

    if (result.similarityPercent == null) {
      return;
    }

    setState(() => _similarityPercent = result.similarityPercent);

    if (result.similarityPercent! >= tracePassPercent && !_passed) {
      _passed = true;
      widget.onPassed(result.similarityPercent!);
      return;
    }

    if (result.similarityPercent! < tracePassPercent) {
      _triggerLowScoreShake();
    }
  }

  TracePoint _localToViewBox(Offset local, Size size) {
    return TracePoint(
      x: (local.dx / size.width) * halfDrawViewboxSize,
      y: (local.dy / size.height) * halfDrawViewboxSize,
    );
  }

  void _handlePointerDown(PointerDownEvent event, Size size) {
    if (_isInteractionLocked) {
      return;
    }

    final point = _localToViewBox(event.localPosition, size);
    if (!isPointInDrawableHalf(Offset(point.x, point.y), splitViewbox: _splitLineViewbox)) {
      return;
    }

    _drawing = true;
    setState(() {
      _activeStroke
        ..clear()
        ..add(point);
    });
  }

  void _handlePointerMove(PointerMoveEvent event, Size size) {
    if (!_drawing || _isInteractionLocked) {
      return;
    }

    final rawPoint = _localToViewBox(event.localPosition, size);
    final point = TracePoint(
      x: math.max(rawPoint.x, _splitLineViewbox),
      y: rawPoint.y,
    );
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

    final finalStroke = _activeStroke
        .where((point) => point.x >= _splitLineViewbox)
        .toList();

    if (finalStroke.length < 2) {
      setState(() => _activeStroke.clear());
      return;
    }

    final normalizedStroke = finalStroke
        .map((point) => toNormalizedPoint(Offset(point.x, point.y)))
        .toList();
    final nextStrokes = [..._strokes, normalizedStroke];

    setState(() {
      _strokes
        ..clear()
        ..addAll(nextStrokes);
      _displayStrokes.add(finalStroke);
      _activeStroke.clear();
    });

    _updateScore(nextStrokes);
  }

  void _handleClear() {
    if (_isInteractionLocked || _passed) {
      return;
    }

    _shakeTimer?.cancel();
    setState(() {
      _drawing = false;
      _similarityPercent = null;
      _isShaking = false;
      _strokes.clear();
      _displayStrokes.clear();
      _activeStroke.clear();
    });
  }

  bool get _canClear => _strokes.isNotEmpty || _activeStroke.isNotEmpty;

  @override
  void dispose() {
    _shakeTimer?.cancel();
    _letterPopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padSize = halfDrawPadSize(
          constraints.maxHeight,
          constraints.maxWidth,
        );

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ColorPalette(
              disabled: _isInteractionLocked,
              selectedColor: _selectedColor,
              onSelect: (color) => setState(() => _selectedColor = color),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Center(
                child: _HalfDrawPadShake(
                  isShaking: _isShaking,
                  child: SizedBox(
                    width: padSize,
                    height: padSize,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        if (_passed)
                          DigitFoundBurst(
                            color: halfDrawBurstColor,
                            size: padSize,
                          ),
                        Semantics(
                          label: 'Дорисуй половину буквы ${widget.displayLetter}',
                          child: AnimatedBuilder(
                            animation: _letterPopProgress,
                            builder: (context, _) {
                              final letterPopProgress =
                                  _letterPopProgress.value.clamp(0.0, 1.0);

                              return LayoutBuilder(
                                builder: (context, padConstraints) {
                                  final size = Size(
                                    padConstraints.maxWidth,
                                    padConstraints.maxHeight,
                                  );

                                  return Listener(
                                    behavior: HitTestBehavior.opaque,
                                    onPointerDown: (event) =>
                                        _handlePointerDown(event, size),
                                    onPointerMove: (event) =>
                                        _handlePointerMove(event, size),
                                    onPointerUp: (_) => _handlePointerEnd(),
                                    onPointerCancel: (_) => _handlePointerEnd(),
                                    child: CustomPaint(
                                      painter: _HalfDrawPadPainter(
                                        activeStroke: _activeStroke,
                                        displayLetter: widget.displayLetter,
                                        displayStrokes: _displayStrokes,
                                        drawing: _drawing,
                                        letterPopProgress: letterPopProgress,
                                        selectedColor: _selectedColorValue,
                                        strokeColor: _drawing
                                            ? _selectedColorValue
                                            : _committedStrokeColor,
                                      ),
                                      child: const SizedBox.expand(),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (!_passed) ...[
              const SizedBox(height: 16),
              _HalfDrawClearButton(
                disabled: _isInteractionLocked || !_canClear,
                onPressed: _handleClear,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _HalfDrawPadShake extends StatefulWidget {
  const _HalfDrawPadShake({
    required this.isShaking,
    required this.child,
  });

  final bool isShaking;
  final Widget child;

  @override
  State<_HalfDrawPadShake> createState() => _HalfDrawPadShakeState();
}

class _HalfDrawPadShakeState extends State<_HalfDrawPadShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _wrongShakeMs),
    );
    _offset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: -5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isShaking) {
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(_HalfDrawPadShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isShaking && widget.isShaking) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_offset.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _HalfDrawClearButton extends StatelessWidget {
  const _HalfDrawClearButton({
    required this.disabled,
    required this.onPressed,
  });

  final bool disabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Material(
        color: Colors.white.withValues(alpha: 0.85),
        shape: const StadiumBorder(
          side: BorderSide(color: ParentColors.shell, width: 2),
        ),
        child: InkWell(
          onTap: disabled ? null : onPressed,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Text(
              'Стереть',
              style: GoogleFonts.onest(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ParentColors.shell,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HalfDrawPadPainter extends CustomPainter {
  _HalfDrawPadPainter({
    required this.activeStroke,
    required this.displayLetter,
    required this.displayStrokes,
    required this.drawing,
    required this.letterPopProgress,
    required this.selectedColor,
    required this.strokeColor,
  });

  final List<TracePoint> activeStroke;
  final String displayLetter;
  final List<List<TracePoint>> displayStrokes;
  final bool drawing;
  final double letterPopProgress;
  final Color selectedColor;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final splitX = size.width * (halfDrawSplitLineViewboxX() / halfDrawViewboxSize);

    _paintSplitLine(canvas, size, splitX);

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, splitX, size.height));
    _paintLetter(canvas, size);
    canvas.restore();

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(splitX, 0, size.width - splitX, size.height));
    _paintStrokes(canvas, size);
    canvas.restore();
  }

  void _paintSplitLine(Canvas canvas, Size size, double splitX) {
    final paint = Paint()
      ..color = halfDrawSplitLineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * (1.5 / halfDrawViewboxSize);

    final path = Path();
    final topY = size.height * (8 / halfDrawViewboxSize);
    final bottomY = size.height * (92 / halfDrawViewboxSize);
    path.moveTo(splitX, topY);
    path.lineTo(splitX, bottomY);

    canvas.drawPath(
      buildDashedPath(path, dashArray: const [4, 4]),
      paint,
    );
  }

  void _paintLetter(Canvas canvas, Size size) {
    final letterCenter = Offset(
      size.width * (colorLetterCenterX / colorViewboxSize),
      size.height * (colorLetterCenterY / colorViewboxSize),
    );
    final fontSize = size.width * (colorLetterFontSize / colorViewboxSize);
    final textStyle = GoogleFonts.onest(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: halfDrawFixedLetterColor.withValues(alpha: letterPopProgress),
      height: 1,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: displayLetter, style: textStyle),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = Offset(
      letterCenter.dx - textPainter.width / 2,
      letterCenter.dy - textPainter.height / 2,
    );

    canvas.save();
    canvas.translate(letterCenter.dx, letterCenter.dy);
    canvas.scale(0.88 + 0.12 * letterPopProgress);
    canvas.translate(-letterCenter.dx, -letterCenter.dy);
    textPainter.paint(canvas, offset);
    canvas.restore();
  }

  void _paintStrokes(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * (colorStrokeWidth / colorViewboxSize)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in displayStrokes) {
      _paintPolyline(canvas, size, stroke, strokePaint);
    }

    if (activeStroke.isNotEmpty) {
      _paintPolyline(canvas, size, activeStroke, strokePaint);
    }
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
      first.x / halfDrawViewboxSize * size.width,
      first.y / halfDrawViewboxSize * size.height,
    );

    for (var index = 1; index < stroke.length; index++) {
      final point = stroke[index];
      path.lineTo(
        point.x / halfDrawViewboxSize * size.width,
        point.y / halfDrawViewboxSize * size.height,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HalfDrawPadPainter oldDelegate) {
    return oldDelegate.activeStroke != activeStroke ||
        oldDelegate.displayLetter != displayLetter ||
        oldDelegate.displayStrokes != displayStrokes ||
        oldDelegate.drawing != drawing ||
        oldDelegate.letterPopProgress != letterPopProgress ||
        oldDelegate.selectedColor != selectedColor ||
        oldDelegate.strokeColor != strokeColor;
  }
}
