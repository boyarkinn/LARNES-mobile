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
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_build/build_pad_size.dart';
import 'package:larnes_mobile/trainers/reading/letter_build/build_phase_dots.dart';
import 'package:larnes_mobile/trainers/reading/letter_build/build_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_build/letter_build_model.dart';
import 'package:larnes_mobile/trainers/reading/zaitsev/path_geometry.dart';
import 'package:larnes_mobile/trainers/reading/zaitsev/zaitsev_sticks.dart';
import 'package:larnes_mobile/trainers/reading/zaitsev/zaitsev_types.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

const _wrongShakeMs = 550;
const _stickHitThreshold = 0.08;

/// Web: `platform/src/trainers/reading/letter-build/build-scene.tsx`
class BuildScene extends StatefulWidget {
  const BuildScene({
    super.key,
    required this.displayLetter,
    required this.guideLetter,
    required this.phase,
    required this.onGuideComplete,
    required this.onFreePassed,
    this.disabled = false,
  });

  final String displayLetter;
  final String guideLetter;
  final BuildPhase phase;
  final VoidCallback onGuideComplete;
  final ValueChanged<int> onFreePassed;
  final bool disabled;

  @override
  State<BuildScene> createState() => _BuildSceneState();
}

class _BuildSceneState extends State<BuildScene> {
  late List<StickPieceDef> _pieces;
  late ZaitsevLetterDrawing? _drawing;
  late List<PiecePlacement> _placements;

  _DragState? _dragState;
  var _hasPassed = false;
  var _isShaking = false;
  var _isInteractionReady = false;
  var _guideCompleteScheduled = false;
  var _passedReported = false;

  Timer? _interactionTimer;
  Timer? _guideCompleteTimer;
  Timer? _shakeTimer;

  @override
  void initState() {
    super.initState();
    _loadLetterData();
    _scheduleInteractionReady();
  }

  @override
  void didUpdateWidget(BuildScene oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.guideLetter != widget.guideLetter ||
        oldWidget.phase != widget.phase) {
      _resetScene();
    }
  }

  void _loadLetterData() {
    _pieces = getPiecesForLetter(widget.guideLetter);
    _drawing = getBuildDrawing(widget.guideLetter);
    _placements = createInitialPlacements(_pieces);
  }

  void _resetScene() {
    _interactionTimer?.cancel();
    _guideCompleteTimer?.cancel();
    _shakeTimer?.cancel();
    _loadLetterData();
    _dragState = null;
    _hasPassed = false;
    _isShaking = false;
    _isInteractionReady = false;
    _guideCompleteScheduled = false;
    _passedReported = false;
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

  bool get _isLocked =>
      widget.disabled || _hasPassed || !_isInteractionReady;

  bool get _hasMovedSticks {
    final initial = createInitialPlacements(_pieces);

    for (var index = 0; index < _placements.length; index++) {
      final placement = _placements[index];
      final start = initial[index];
      final dx = placement.offset.x - start.offset.x;
      final dy = placement.offset.y - start.offset.y;

      if (math.sqrt(dx * dx + dy * dy) > 0.01) {
        return true;
      }
    }

    return false;
  }

  void _triggerLowScoreShake() {
    _shakeTimer?.cancel();
    setState(() => _isShaking = true);
    _shakeTimer = Timer(const Duration(milliseconds: _wrongShakeMs), () {
      if (mounted) {
        setState(() => _isShaking = false);
      }
    });
  }

  void _tryCompleteGuide(List<PiecePlacement> nextPlacements) {
    if (widget.phase != BuildPhase.guide ||
        _guideCompleteScheduled ||
        !isGuidePhaseComplete(_pieces, nextPlacements)) {
      return;
    }

    _guideCompleteScheduled = true;
    _guideCompleteTimer = Timer(
      const Duration(milliseconds: TrainerTimings.guideCompleteDelayMs),
      () {
        if (mounted) {
          widget.onGuideComplete();
        }
      },
    );
  }

  String? _hitTestPiece(Offset local, Size size) {
    final pointer = TracePoint(
      x: local.dx / size.width,
      y: local.dy / size.height,
    );

    for (var index = _pieces.length - 1; index >= 0; index--) {
      final piece = _pieces[index];
      final placement = _placements[index];
      final piecePointer = TracePoint(
        x: pointer.x - placement.offset.x,
        y: pointer.y - placement.offset.y,
      );
      final samples = sampleSvgPath(piece.path);

      for (final sample in samples) {
        final dx = piecePointer.x - sample.x;
        final dy = piecePointer.y - sample.y;

        if (math.sqrt(dx * dx + dy * dy) <= _stickHitThreshold) {
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

    if (widget.phase == BuildPhase.guide && placement.snapped) {
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
    final deltaX = deltaPixelsX / size.width;
    final deltaY = deltaPixelsY / size.height;

    setState(() {
      _placements = [
        for (final placement in _placements)
          placement.id == dragState.pieceId
              ? translatePlacement(
                  placement.copyWith(offset: dragState.startOffset),
                  deltaX,
                  deltaY,
                )
              : placement,
      ];
    });
  }

  void _handlePointerEnd() {
    final dragState = _dragState;

    if (dragState == null) {
      return;
    }

    StickPieceDef? piece;

    for (final item in _pieces) {
      if (item.id == dragState.pieceId) {
        piece = item;
        break;
      }
    }

    if (piece == null) {
      setState(() => _dragState = null);
      return;
    }

    setState(() {
      _placements = [
        for (final placement in _placements)
          placement.id == dragState.pieceId
              ? () {
                  if (widget.phase == BuildPhase.guide &&
                      canSnapPiece(piece!, placement)) {
                    return snapPiece(piece, placement);
                  }

                  return placement;
                }()
              : placement,
      ];
      _dragState = null;
    });

    if (widget.phase == BuildPhase.guide) {
      _tryCompleteGuide(_placements);
    }
  }

  void _handleCheck() {
    if (widget.phase != BuildPhase.free ||
        _isLocked ||
        _passedReported) {
      return;
    }

    final result = scoreBuildPlacements(widget.guideLetter, _placements);

    if (result.similarityPercent == null) {
      return;
    }

    if (result.similarityPercent! >= tracePassPercent) {
      _passedReported = true;
      setState(() => _hasPassed = true);
      widget.onFreePassed(result.similarityPercent!);
      return;
    }

    _triggerLowScoreShake();
  }

  void _handleClear() {
    if (widget.phase != BuildPhase.free || _isLocked || _hasPassed) {
      return;
    }

    setState(() {
      _placements = createInitialPlacements(_pieces);
      _dragState = null;
      _isShaking = false;
    });
  }

  Color _strokeColorForPiece(String pieceId, PiecePlacement placement) {
    if (widget.phase == BuildPhase.guide && placement.snapped) {
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
    _guideCompleteTimer?.cancel();
    _shakeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drawing = _drawing;

    if (drawing == null || _pieces.isEmpty) {
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
        final padSize = buildPadSize(constraints.maxHeight, constraints.maxWidth);

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Center(
                child: _BuildPadShake(
                  isShaking: _isShaking,
                  child: SizedBox(
                    width: padSize,
                    height: padSize,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        if (_hasPassed)
                          DigitFoundBurst(
                            color: buildStickSnappedColor,
                            size: padSize,
                          ),
                        LayoutBuilder(
                          builder: (context, padConstraints) {
                            final size = Size(
                              padConstraints.maxWidth,
                              padConstraints.maxHeight,
                            );
                            final viewBoxSize =
                                parseZaitsevViewBoxSize(drawing.viewBox);

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
                                    if (widget.phase == BuildPhase.guide)
                                      for (final stroke in drawing.strokes)
                                        _BuildGhostStroke(
                                          path: stroke.path,
                                          strokeWidth: drawing.strokeWidth,
                                          size: size,
                                          viewBox: drawing.viewBox,
                                        ),
                                    for (var index = 0;
                                        index < _pieces.length;
                                        index++)
                                      _BuildStickPath(
                                        key: ValueKey(
                                          '${_pieces[index].id}-${widget.phase.name}',
                                        ),
                                        path: _pieces[index].path,
                                        strokeWidth: drawing.strokeWidth,
                                        viewBoxSize: viewBoxSize,
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
            ),
            const SizedBox(height: 16),
            BuildPhaseDots(
              hasPassed: _hasPassed,
              phase: widget.phase,
            ),
            if (widget.phase == BuildPhase.free && !_hasPassed) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BuildActionButton(
                    label: 'Стереть',
                    primary: false,
                    disabled: _isLocked || !_hasMovedSticks,
                    onPressed: _handleClear,
                  ),
                  const SizedBox(width: 12),
                  _BuildActionButton(
                    label: 'Проверить',
                    primary: true,
                    disabled: _isLocked,
                    onPressed: _handleCheck,
                  ),
                ],
              ),
            ],
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
    required this.viewBoxSize,
    required this.padSize,
    required this.offset,
    required this.stroke,
    required this.revealDelayMs,
  });

  final String path;
  final double strokeWidth;
  final double viewBoxSize;
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
                viewBoxSize: widget.viewBoxSize,
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
    required this.viewBoxSize,
    required this.offset,
    required this.stroke,
  });

  final String path;
  final double strokeWidth;
  final double viewBoxSize;
  final TracePoint offset;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / viewBoxSize;
    final sourcePath = buildZaitsevSvgPath(path);
    final paint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.scale(scale);
    canvas.translate(offset.x * viewBoxSize, offset.y * viewBoxSize);
    canvas.drawPath(sourcePath, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BuildStickPathPainter oldDelegate) {
    return oldDelegate.path != path ||
        oldDelegate.offset != offset ||
        oldDelegate.stroke != stroke;
  }
}

class _BuildGhostStroke extends StatefulWidget {
  const _BuildGhostStroke({
    required this.path,
    required this.strokeWidth,
    required this.size,
    required this.viewBox,
  });

  final String path;
  final double strokeWidth;
  final Size size;
  final String viewBox;

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
                viewBox: widget.viewBox,
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
    required this.viewBox,
  });

  final String path;
  final double strokeWidth;
  final String viewBox;

  @override
  void paint(Canvas canvas, Size size) {
    final viewBoxSize = parseZaitsevViewBoxSize(viewBox);
    final scale = size.width / viewBoxSize;
    final sourcePath = buildZaitsevSvgPath(path);
    final paint = Paint()
      ..color = buildGhostStrokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.scale(scale);
    canvas.drawPath(
      buildDashedPath(sourcePath, dashArray: const [10, 8]),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BuildGhostStrokePainter oldDelegate) {
    return oldDelegate.path != path;
  }
}

class _BuildPadShake extends StatefulWidget {
  const _BuildPadShake({
    required this.isShaking,
    required this.child,
  });

  final bool isShaking;
  final Widget child;

  @override
  State<_BuildPadShake> createState() => _BuildPadShakeState();
}

class _BuildPadShakeState extends State<_BuildPadShake>
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
  void didUpdateWidget(_BuildPadShake oldWidget) {
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

class _BuildActionButton extends StatelessWidget {
  const _BuildActionButton({
    required this.label,
    required this.primary,
    required this.disabled,
    required this.onPressed,
  });

  final String label;
  final bool primary;
  final bool disabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Material(
        color: primary ? ParentColors.shell : Colors.white.withValues(alpha: 0.85),
        shape: StadiumBorder(
          side: BorderSide(
            color: ParentColors.shell,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: disabled ? null : onPressed,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Text(
              label,
              style: GoogleFonts.onest(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: primary ? Colors.white : ParentColors.shell,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
