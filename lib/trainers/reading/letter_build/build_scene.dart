import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_found_burst.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_paths.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/trace_reveal.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_build/build_pad_size.dart';
import 'package:larnes_mobile/trainers/reading/letter_build/build_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_build/letter_build_model.dart';
import 'package:larnes_mobile/trainers/reading/zaitsev/path_geometry.dart';
import 'package:larnes_mobile/trainers/reading/zaitsev/zaitsev_sticks.dart';
import 'package:larnes_mobile/trainers/reading/zaitsev/zaitsev_types.dart';

const _stickHitThreshold = 0.08;

/// Web: `platform/src/trainers/reading/letter-build/build-scene.tsx`
class BuildScene extends StatefulWidget {
  const BuildScene({
    super.key,
    required this.displayLetter,
    required this.guideLetter,
    required this.onGuideComplete,
    this.disabled = false,
  });

  final String displayLetter;
  final String guideLetter;
  final VoidCallback onGuideComplete;
  final bool disabled;

  @override
  State<BuildScene> createState() => _BuildSceneState();
}

class _BuildSceneState extends State<BuildScene> {
  late List<StickPieceDef> _pieces;
  late ZaitsevLetterDrawing? _drawing;
  late BuildLayout? _layout;
  late List<PiecePlacement> _placements;

  _DragState? _dragState;
  var _hasPassed = false;
  var _isInteractionReady = false;

  Timer? _interactionTimer;

  @override
  void initState() {
    super.initState();
    _loadLetterData();
    _scheduleInteractionReady();
  }

  @override
  void didUpdateWidget(BuildScene oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.guideLetter != widget.guideLetter) {
      _resetScene();
    }
  }

  void _loadLetterData() {
    _pieces = getPiecesForLetter(widget.guideLetter);
    _drawing = getBuildDrawing(widget.guideLetter);
    _layout = getBuildLayout(widget.guideLetter);
    _placements = createInitialPlacements(_pieces);
  }

  void _resetScene() {
    _interactionTimer?.cancel();
    _loadLetterData();
    _dragState = null;
    _hasPassed = false;
    _isInteractionReady = false;
    _scheduleInteractionReady();
  }

  void _scheduleInteractionReady() {
    _interactionTimer?.cancel();
    _interactionTimer = Timer(
      Duration(milliseconds: getBuildInteractionReadyMs(_pieces.length)),
      () {
        if (mounted) {
          setState(() => _isInteractionReady = true);
        }
      },
    );
  }

  bool get _isLocked => widget.disabled || _hasPassed || !_isInteractionReady;

  void _tryCompleteGuide(List<PiecePlacement> nextPlacements) {
    if (_hasPassed || !isGuidePhaseComplete(_pieces, nextPlacements)) {
      return;
    }

    setState(() => _hasPassed = true);
    widget.onGuideComplete();
  }

  String? _hitTestPiece(Offset local, Size size) {
    final layout = _layout;
    if (layout == null) return null;
    final scale = size.width / layout.width;
    final pointer = TracePoint(
      x: (layout.minX + local.dx / scale) / zaitsevCoordSize,
      y: (layout.minY + local.dy / scale) / zaitsevCoordSize,
    );
    final hitThreshold = math.max(_stickHitThreshold, 16 / (scale * zaitsevCoordSize));

    for (var index = _pieces.length - 1; index >= 0; index--) {
      final piece = _pieces[index];
      final placement = _placements[index];
      if (placement.snapped) continue;
      final piecePointer = TracePoint(
        x: pointer.x - placement.offset.x,
        y: pointer.y - placement.offset.y,
      );
      final samples = sampleSvgPath(piece.path);

      for (final sample in samples) {
        final dx = piecePointer.x - sample.x;
        final dy = piecePointer.y - sample.y;

        if (math.sqrt(dx * dx + dy * dy) <= hitThreshold) {
          return piece.id;
        }
      }
    }

    return null;
  }

  void _handlePointerDown(PointerDownEvent event, Size size) {
    if (_isLocked) {
      return;
    }

    final pieceId = _hitTestPiece(event.localPosition, size);

    if (pieceId == null) {
      return;
    }

    final placement = _placements.firstWhere((item) => item.id == pieceId);

    if (placement.snapped) {
      return;
    }

    setState(() {
      _dragState = _DragState(
        pieceId: pieceId,
        startOffset: placement.offset,
        startX: event.position.dx,
        startY: event.position.dy,
      );
    });
  }

  void _handlePointerMove(PointerMoveEvent event, Size size) {
    final dragState = _dragState;

    if (dragState == null || _isLocked) {
      return;
    }

    final deltaPixelsX = event.position.dx - dragState.startX;
    final deltaPixelsY = event.position.dy - dragState.startY;
    final layout = _layout;
    if (layout == null) return;
    final scale = size.width / layout.width;
    final piece = _pieces.firstWhere((item) => item.id == dragState.pieceId);
    final deltaX = deltaPixelsX / (scale * zaitsevCoordSize);
    final deltaY = deltaPixelsY / (scale * zaitsevCoordSize);

    setState(() {
      _placements = [
        for (final placement in _placements)
          placement.id == dragState.pieceId
              ? constrainBuildPlacement(piece, translatePlacement(
                  placement.copyWith(offset: dragState.startOffset),
                  deltaX,
                  deltaY,
                ), layout)
              : placement,
      ];
    });
  }

  void _handlePointerEnd() {
    final dragState = _dragState;

    if (dragState == null) {
      return;
    }

    setState(() {
      _placements = snapBuildPiece(_pieces, _placements, dragState.pieceId);
      _dragState = null;
    });

    _tryCompleteGuide(_placements);
  }

  Color _strokeColorForPiece(String pieceId, PiecePlacement placement) {
    if (placement.snapped) {
      return buildStickSnappedColor;
    }

    if (_dragState?.pieceId == pieceId) {
      return buildStickDragColor;
    }

    return buildStickColor;
  }

  @override
  void dispose() {
    _interactionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drawing = _drawing;
    final layout = _layout;

    if (drawing == null || layout == null || _pieces.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Сборка из палочек для буквы «${widget.displayLetter}» пока недоступна.',
              style: GoogleFonts.onest(
                fontSize: 14,
                color: const Color(0xFF78350F),
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = math.min(
          math.max(1.0, constraints.maxWidth - 32) / layout.width,
          math.max(1.0, constraints.maxHeight - 32) / layout.height,
        );
        final padWidth = layout.width * scale;
        final padHeight = layout.height * scale;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Center(
                child: SizedBox(
                  width: padWidth,
                  height: padHeight,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      if (_hasPassed)
                        DigitFoundBurst(
                          color: buildStickSnappedColor,
                          size: math.min(padWidth, padHeight),
                        ),
                      LayoutBuilder(
                        builder: (context, padConstraints) {
                          final size = Size(
                            padConstraints.maxWidth,
                            padConstraints.maxHeight,
                          );

                          return Semantics(
                            label: 'Собери букву ${widget.displayLetter}',
                            child: Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerDown: (event) =>
                                  _handlePointerDown(event, size),
                              onPointerMove: (event) =>
                                  _handlePointerMove(event, size),
                              onPointerUp: (_) => _handlePointerEnd(),
                              onPointerCancel: (_) => _handlePointerEnd(),
                              child: Stack(
                                children: [
                                  for (final stroke in drawing.strokes)
                                    _BuildGhostStroke(
                                      path: stroke.path,
                                      strokeWidth: drawing.strokeWidth,
                                      size: size,
                                      layout: layout,
                                    ),
                                  for (var index = 0;
                                      index < _pieces.length;
                                      index++)
                                    _BuildStickPath(
                                      key: ValueKey(_pieces[index].id),
                                      path: _pieces[index].path,
                                      strokeWidth: drawing.strokeWidth,
                                      layout: layout,
                                      padSize: size,
                                      offset: _placements[index].offset,
                                      stroke: _strokeColorForPiece(
                                        _pieces[index].id,
                                        _placements[index],
                                      ),
                                      revealDelayMs: getStickRevealDelayMs(
                                        index,
                                        _pieces.length,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DragState {
  const _DragState({
    required this.pieceId,
    required this.startOffset,
    required this.startX,
    required this.startY,
  });

  final String pieceId;
  final TracePoint startOffset;
  final double startX;
  final double startY;
}

class _BuildStickPath extends StatefulWidget {
  const _BuildStickPath({
    super.key,
    required this.path,
    required this.strokeWidth,
    required this.layout,
    required this.padSize,
    required this.offset,
    required this.stroke,
    required this.revealDelayMs,
  });

  final String path;
  final double strokeWidth;
  final BuildLayout layout;
  final Size padSize;
  final TracePoint offset;
  final Color stroke;
  final int revealDelayMs;

  @override
  State<_BuildStickPath> createState() => _BuildStickPathState();
}

class _BuildStickPathState extends State<_BuildStickPath>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: kFruitPopDurationMs),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.34, 1.2, 0.64, 1),
    );
    _delayTimer = Timer(Duration(milliseconds: widget.revealDelayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final t = _progress.value.clamp(0.0, 1.0);

        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.88 + 0.12 * t,
            child: CustomPaint(
              size: widget.padSize,
              painter: _BuildStickPathPainter(
                path: widget.path,
                strokeWidth: widget.strokeWidth,
                layout: widget.layout,
                offset: widget.offset,
                stroke: widget.stroke,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BuildStickPathPainter extends CustomPainter {
  _BuildStickPathPainter({
    required this.path,
    required this.strokeWidth,
    required this.layout,
    required this.offset,
    required this.stroke,
  });

  final String path;
  final double strokeWidth;
  final BuildLayout layout;
  final TracePoint offset;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / layout.width;
    final sourcePath = buildZaitsevSvgPath(path);
    final paint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.scale(scale);
    canvas.translate(-layout.minX, -layout.minY);
    canvas.translate(offset.x * zaitsevCoordSize, offset.y * zaitsevCoordSize);
    canvas.drawPath(sourcePath, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BuildStickPathPainter oldDelegate) {
    return oldDelegate.path != path ||
        oldDelegate.offset != offset ||
        oldDelegate.stroke != stroke || oldDelegate.layout != layout;
  }
}

class _BuildGhostStroke extends StatefulWidget {
  const _BuildGhostStroke({
    required this.path,
    required this.strokeWidth,
    required this.size,
    required this.layout,
  });

  final String path;
  final double strokeWidth;
  final Size size;
  final BuildLayout layout;

  @override
  State<_BuildGhostStroke> createState() => _BuildGhostStrokeState();
}

class _BuildGhostStrokeState extends State<_BuildGhostStroke>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: traceGuidePopDurationMs),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.34, 1.2, 0.64, 1),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final t = _progress.value.clamp(0.0, 1.0);

        return Opacity(
          opacity: t,
          child: Transform.scale(
            scale: 0.88 + 0.12 * t,
            child: CustomPaint(
              size: widget.size,
              painter: _BuildGhostStrokePainter(
                path: widget.path,
                strokeWidth: widget.strokeWidth,
                layout: widget.layout,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BuildGhostStrokePainter extends CustomPainter {
  _BuildGhostStrokePainter({
    required this.path,
    required this.strokeWidth,
    required this.layout,
  });

  final String path;
  final double strokeWidth;
  final BuildLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / layout.width;
    final sourcePath = buildZaitsevSvgPath(path);
    final paint = Paint()
      ..color = buildGhostStrokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.scale(scale);
    canvas.translate(-layout.minX, -layout.minY);
    canvas.drawPath(
      buildDashedPath(sourcePath, dashArray: const [10, 8]),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BuildGhostStrokePainter oldDelegate) {
    return oldDelegate.path != path || oldDelegate.layout != layout;
  }
}
