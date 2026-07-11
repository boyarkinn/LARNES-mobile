import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_found_burst.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_paths.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_trace_model.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/trace_feedback.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/trace_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_complete/complete_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_complete/complete_pad_size.dart';
import 'package:larnes_mobile/trainers/reading/letter_guides.dart';

const _minPointDistance = 1.2;
const _wrongShakeMs = 550;
const _popCurve = Cubic(0.34, 1.2, 0.64, 1);

/// Web v2: `platform/src/trainers/reading/letter-complete/complete-pad.tsx`
class LetterCompletePad extends StatefulWidget {
  const LetterCompletePad({
    super.key,
    required this.displayLetter,
    required this.guideLetter,
    required this.missingSegmentIndex,
    this.disabled = false,
    required this.onPassed,
  });

  final String displayLetter;
  final String guideLetter;
  final int missingSegmentIndex;
  final bool disabled;
  final ValueChanged<int> onPassed;

  @override
  State<LetterCompletePad> createState() => _LetterCompletePadState();
}

class _LetterCompletePadState extends State<LetterCompletePad>
    with SingleTickerProviderStateMixin {
  final _strokes = <TraceStroke>[];
  final _displayStrokes = <List<TracePoint>>[];
  final _activeStroke = <TracePoint>[];
  var _drawing = false;
  var _passed = false;
  var _isShaking = false;
  int? _similarityPercent;
  Timer? _shakeTimer;
  late final AnimationController _guideController;
  late final Animation<double> _guideProgress;

  @override
  void initState() {
    super.initState();
    _guideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: traceGuidePopDurationMs),
    );
    _guideProgress = CurvedAnimation(parent: _guideController, curve: _popCurve);
    _guideController.forward();
  }

  @override
  void didUpdateWidget(LetterCompletePad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.guideLetter != widget.guideLetter ||
        oldWidget.missingSegmentIndex != widget.missingSegmentIndex) {
      _resetForRound();
    }
  }

  void _resetForRound() {
    _shakeTimer?.cancel();
    _drawing = false;
    _passed = false;
    _isShaking = false;
    _similarityPercent = null;
    _strokes.clear();
    _displayStrokes.clear();
    _activeStroke.clear();
    _guideController.forward(from: 0);
  }

  bool get _isInteractionLocked => widget.disabled || _passed;

  Color get _committedStrokeColor => getTraceStrokeColor(
        _similarityPercent,
        completeInkColor,
      );

  List<List<TracePoint>> get _guideSegments =>
      getLetterGuideSegments(widget.guideLetter);

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
    final result = scoreLetterSegmentTrace(
      widget.guideLetter,
      widget.missingSegmentIndex,
      nextStrokes,
    );

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
      x: (local.dx / size.width) * letterCompleteViewboxSize,
      y: (local.dy / size.height) * letterCompleteViewboxSize,
    );
  }

  TracePoint _toNormalized(TracePoint point) {
    return TracePoint(
      x: point.x / letterCompleteViewboxSize,
      y: point.y / letterCompleteViewboxSize,
    );
  }

  void _handlePointerDown(PointerDownEvent event, Size size) {
    if (_isInteractionLocked) {
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
    if (!_drawing || _isInteractionLocked) {
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
    _guideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padSize = completePadSize(
          constraints.maxHeight,
          constraints.maxWidth,
        );

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Center(
                child: _LetterCompletePadShake(
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
                            color: completeBurstColor,
                            size: padSize,
                          ),
                        Semantics(
                          label: 'Допиши букву ${widget.displayLetter}',
                          child: AnimatedBuilder(
                            animation: _guideProgress,
                            builder: (context, child) {
                              final t = _guideProgress.value.clamp(0.0, 1.0);
                              return Opacity(
                                opacity: t,
                                child: Transform.scale(
                                  scale: 0.88 + 0.12 * t,
                                  child: child,
                                ),
                              );
                            },
                            child: LayoutBuilder(
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
                                    painter: _LetterCompletePadPainter(
                                      guideSegments: _guideSegments,
                                      missingSegmentIndex:
                                          widget.missingSegmentIndex,
                                      displayStrokes: _displayStrokes,
                                      activeStroke: _activeStroke,
                                      strokeColor: _drawing
                                          ? completeInkColor
                                          : _committedStrokeColor,
                                    ),
                                    child: const SizedBox.expand(),
                                  ),
                                );
                              },
                            ),
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
              _LetterCompleteClearButton(
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

class _LetterCompletePadShake extends StatefulWidget {
  const _LetterCompletePadShake({
    required this.isShaking,
    required this.child,
  });

  final bool isShaking;
  final Widget child;

  @override
  State<_LetterCompletePadShake> createState() =>
      _LetterCompletePadShakeState();
}

class _LetterCompletePadShakeState extends State<_LetterCompletePadShake>
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
  void didUpdateWidget(_LetterCompletePadShake oldWidget) {
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

class _LetterCompleteClearButton extends StatelessWidget {
  const _LetterCompleteClearButton({
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

class _LetterCompletePadPainter extends CustomPainter {
  _LetterCompletePadPainter({
    required this.guideSegments,
    required this.missingSegmentIndex,
    required this.displayStrokes,
    required this.activeStroke,
    required this.strokeColor,
  });

  final List<List<TracePoint>> guideSegments;
  final int missingSegmentIndex;
  final List<List<TracePoint>> displayStrokes;
  final List<TracePoint> activeStroke;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (var index = 0; index < guideSegments.length; index++) {
      final segment = guideSegments[index];
      final segmentPath = _buildSegmentPath(segment, size);

      if (segmentPath.computeMetrics().isEmpty) {
        continue;
      }

      final isMissing = index == missingSegmentIndex;
      final guidePaint = Paint()
        ..color =
            isMissing ? completeMissingDashColor : completeFixedStrokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * (isMissing ? 0.07 : 0.08)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(
        isMissing ? buildDashedPath(segmentPath) : segmentPath,
        guidePaint,
      );
    }

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

  Path _buildSegmentPath(List<TracePoint> segment, Size size) {
    final path = Path();

    if (segment.length < 2) {
      return path;
    }

    path.moveTo(segment.first.x * size.width, segment.first.y * size.height);

    for (var index = 1; index < segment.length; index++) {
      final point = segment[index];
      path.lineTo(point.x * size.width, point.y * size.height);
    }

    return path;
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
      first.x / letterCompleteViewboxSize * size.width,
      first.y / letterCompleteViewboxSize * size.height,
    );

    for (var index = 1; index < stroke.length; index++) {
      final point = stroke[index];
      path.lineTo(
        point.x / letterCompleteViewboxSize * size.width,
        point.y / letterCompleteViewboxSize * size.height,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LetterCompletePadPainter oldDelegate) {
    return oldDelegate.guideSegments != guideSegments ||
        oldDelegate.missingSegmentIndex != missingSegmentIndex ||
        oldDelegate.displayStrokes != displayStrokes ||
        oldDelegate.activeStroke != activeStroke ||
        oldDelegate.strokeColor != strokeColor;
  }
}
