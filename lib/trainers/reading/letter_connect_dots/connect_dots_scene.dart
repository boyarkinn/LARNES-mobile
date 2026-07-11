import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/trainers/math/digit_find_tap/digit_found_burst.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/digit_paths.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_color/color_letter_actions.dart';
import 'package:larnes_mobile/trainers/reading/letter_connect_dots/connect_dots_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_connect_dots/connect_dots_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_connect_dots/connect_dots_sizes.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_field_scene.dart';

const _wrongShakeMs = 450;
const _popCurve = Cubic(0.34, 1.2, 0.64, 1);

class _ConnectDragState {
  const _ConnectDragState({
    required this.currentX,
    required this.currentY,
    required this.pathDotIds,
  });

  final double currentX;
  final double currentY;
  final List<String> pathDotIds;
}

/// Web: `platform/src/trainers/reading/letter-connect-dots/connect-dots-scene.tsx`
class ConnectDotsScene extends StatefulWidget {
  const ConnectDotsScene({
    super.key,
    required this.guideLetter,
    required this.dotColor,
    required this.dotMode,
    required this.onComplete,
    this.disabled = false,
  });

  final String guideLetter;
  final Color dotColor;
  final String dotMode;
  final VoidCallback onComplete;
  final bool disabled;

  @override
  State<ConnectDotsScene> createState() => _ConnectDotsSceneState();
}

class _ConnectDotsSceneState extends State<ConnectDotsScene> {
  late ConnectDotsPuzzle _puzzle;

  final _drawnLines = <ConnectDrawnLine>[];
  _ConnectDragState? _dragState;
  String? _activeDotId;
  var _hasPassed = false;
  var _isInteractionReady = false;
  var _isShaking = false;

  Timer? _interactionTimer;
  Timer? _shakeTimer;

  @override
  void initState() {
    super.initState();
    _loadPuzzle();
    _scheduleInteractionReady();
  }

  @override
  void didUpdateWidget(ConnectDotsScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.guideLetter != widget.guideLetter) {
      _resetScene();
    }
  }

  void _loadPuzzle() {
    _puzzle = buildLetterDotPuzzle(widget.guideLetter);
  }

  void _resetScene() {
    _interactionTimer?.cancel();
    _shakeTimer?.cancel();
    _loadPuzzle();
    _drawnLines.clear();
    _dragState = null;
    _activeDotId = null;
    _hasPassed = false;
    _isInteractionReady = false;
    _isShaking = false;
    _scheduleInteractionReady();
  }

  void _scheduleInteractionReady() {
    _interactionTimer?.cancel();
    _interactionTimer = Timer(
      Duration(milliseconds: getConnectDotsInteractionReadyMs(_puzzle.dots.length)),
      () {
        if (mounted) {
          setState(() => _isInteractionReady = true);
        }
      },
    );
  }

  bool get _isLocked =>
      widget.disabled || !_isInteractionReady || _hasPassed;

  ConnectDot? _getDotById(String? id) {
    if (id == null) {
      return null;
    }

    for (final dot in _puzzle.dots) {
      if (dot.id == id) {
        return dot;
      }
    }

    return null;
  }

  List<String> _appendDotToPath(List<String> pathDotIds, String dotId) {
    if (pathDotIds.isEmpty) {
      return [dotId];
    }

    if (pathDotIds.last == dotId) {
      return pathDotIds;
    }

    return [...pathDotIds, dotId];
  }

  void _finishDrag(List<String> pathDotIds) {
    if (pathDotIds.length < 2) {
      return;
    }

    final next = addConnectDrawnLinesFromPath(_puzzle, _drawnLines, pathDotIds);

    setState(() {
      _drawnLines
        ..clear()
        ..addAll(next);
    });
  }

  void _handlePointerDown(PointerDownEvent event, double padSize) {
    if (_isLocked) {
      return;
    }

    final point = pointerToConnectViewboxPoint(
      localX: event.localPosition.dx,
      localY: event.localPosition.dy,
      padWidth: padSize,
      padHeight: padSize,
    );
    final dot = findConnectDotAtViewboxPoint(
      _puzzle.dots,
      point.dx,
      point.dy,
    );

    if (dot == null) {
      return;
    }

    setState(() {
      _activeDotId = dot.id;
      _dragState = _ConnectDragState(
        currentX: point.dx,
        currentY: point.dy,
        pathDotIds: [dot.id],
      );
    });
  }

  void _handlePointerMove(PointerMoveEvent event, double padSize) {
    if (_dragState == null || _isLocked) {
      return;
    }

    final point = pointerToConnectViewboxPoint(
      localX: event.localPosition.dx,
      localY: event.localPosition.dy,
      padWidth: padSize,
      padHeight: padSize,
    );
    final hoverDot = findConnectDotAtViewboxPoint(
      _puzzle.dots,
      point.dx,
      point.dy,
    );
    final nextPath = hoverDot != null
        ? _appendDotToPath(_dragState!.pathDotIds, hoverDot.id)
        : _dragState!.pathDotIds;

    setState(() {
      _dragState = _ConnectDragState(
        currentX: point.dx,
        currentY: point.dy,
        pathDotIds: nextPath,
      );
    });
  }

  void _handlePointerUp() {
    if (_dragState == null) {
      return;
    }

    _finishDrag(_dragState!.pathDotIds);
    setState(() {
      _dragState = null;
      _activeDotId = null;
    });
  }

  void _handleCheck() {
    final result = evaluateConnectShapeCoverage(_puzzle, _drawnLines);

    if (result.isSuccess) {
      setState(() => _hasPassed = true);
      widget.onComplete();
      return;
    }

    _triggerCheckErrorShake();
  }

  void _triggerCheckErrorShake() {
    _shakeTimer?.cancel();
    setState(() => _isShaking = true);
    _shakeTimer = Timer(const Duration(milliseconds: _wrongShakeMs), () {
      if (mounted) {
        setState(() => _isShaking = false);
      }
    });
  }

  void _handleClear() {
    setState(() {
      _drawnLines.clear();
      _dragState = null;
      _activeDotId = null;
    });
  }

  List<_ConnectPreviewLine> _buildPathPreviewLines() {
    if (_dragState == null || _dragState!.pathDotIds.length < 2) {
      return const [];
    }

    final lines = <_ConnectPreviewLine>[];

    for (var index = 1; index < _dragState!.pathDotIds.length; index++) {
      final start = _getDotById(_dragState!.pathDotIds[index - 1]);
      final end = _getDotById(_dragState!.pathDotIds[index]);

      if (start == null || end == null) {
        continue;
      }

      final a = connectDotToViewboxPoint(start);
      final b = connectDotToViewboxPoint(end);
      lines.add(
        _ConnectPreviewLine(
          x1: a.dx,
          y1: a.dy,
          x2: b.dx,
          y2: b.dy,
        ),
      );
    }

    return lines;
  }

  @override
  void dispose() {
    _interactionTimer?.cancel();
    _shakeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pathDotIdSet = _dragState?.pathDotIds.toSet() ?? const {};
    final dragStartDot = _getDotById(
      _dragState != null && _dragState!.pathDotIds.isNotEmpty
          ? _dragState!.pathDotIds.last
          : null,
    );
    final dragStartPoint =
        dragStartDot != null ? connectDotToViewboxPoint(dragStartDot) : null;
    final previewLines = _buildPathPreviewLines();
    final actionsDisabled = _isLocked || _drawnLines.isEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final padSize = connectDotsPadSize(
          constraints.maxHeight,
          constraints.maxWidth,
        );

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Center(
                child: Semantics(
                  label: 'Соедини точки',
                  child: SizedBox(
                    width: padSize,
                    height: padSize,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Listener(
                          behavior: HitTestBehavior.translucent,
                          onPointerDown: (event) =>
                              _handlePointerDown(event, padSize),
                          onPointerMove: (event) =>
                              _handlePointerMove(event, padSize),
                          onPointerUp: (_) => _handlePointerUp(),
                          onPointerCancel: (_) => _handlePointerUp(),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              CustomPaint(
                                size: Size(padSize, padSize),
                                painter: _ConnectDotsLinePainter(
                                  padSize: padSize,
                                  drawnLines: _drawnLines,
                                  dots: _puzzle.dots,
                                  previewLines: previewLines,
                                  draftFrom: dragStartPoint,
                                  draftTo: _dragState == null
                                      ? null
                                      : Offset(
                                          _dragState!.currentX,
                                          _dragState!.currentY,
                                        ),
                                ),
                              ),
                              for (var index = 0;
                                  index < _puzzle.dots.length;
                                  index++)
                                _ConnectDotNode(
                                  key: ValueKey(_puzzle.dots[index].id),
                                  dot: _puzzle.dots[index],
                                  dotColor: widget.dotColor,
                                  dotMode: widget.dotMode,
                                  padSize: padSize,
                                  isActive: _activeDotId ==
                                          _puzzle.dots[index].id ||
                                      pathDotIdSet
                                          .contains(_puzzle.dots[index].id),
                                  revealDelayMs: getConnectDotRevealDelayMs(
                                    index,
                                    _puzzle.dots.length,
                                  ),
                                ),
                              if (_hasPassed)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: DigitFoundBurst(
                                      color: widget.dotColor,
                                      size: padSize,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ConnectActionsShake(
              isShaking: _isShaking,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  ColorLetterActionButton(
                    disabled: actionsDisabled,
                    filled: true,
                    label: 'Проверить',
                    onPressed: _handleCheck,
                  ),
                  ColorLetterActionButton(
                    disabled: actionsDisabled,
                    filled: false,
                    label: 'Стереть',
                    onPressed: _handleClear,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class _ConnectPreviewLine {
  const _ConnectPreviewLine({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  final double x1;
  final double y1;
  final double x2;
  final double y2;
}

class _ConnectDotsLinePainter extends CustomPainter {
  _ConnectDotsLinePainter({
    required this.padSize,
    required this.drawnLines,
    required this.dots,
    required this.previewLines,
    required this.draftFrom,
    required this.draftTo,
  });

  final double padSize;
  final List<ConnectDrawnLine> drawnLines;
  final List<ConnectDot> dots;
  final List<_ConnectPreviewLine> previewLines;
  final Offset? draftFrom;
  final Offset? draftTo;

  double _scale(double viewboxValue) => viewboxValue / connectDotsViewboxSize * padSize;

  Offset _toLocal(double x, double y) => Offset(_scale(x), _scale(y));

  ConnectDot? _getDotById(String id) {
    for (final dot in dots) {
      if (dot.id == id) {
        return dot;
      }
    }

    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final lockedPaint = Paint()
      ..color = connectDotsLineLockedColor
      ..strokeWidth = _scale(3.5)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final wrongPaint = Paint()
      ..color = connectDotsLineWrongColor
      ..strokeWidth = _scale(3.5)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final previewPaint = Paint()
      ..color = connectDotsLineLockedColor
      ..strokeWidth = _scale(3)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final draftPaint = Paint()
      ..color = connectDotsLineDraftColor
      ..strokeWidth = _scale(3)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final line in drawnLines) {
      final start = _getDotById(line.aId);
      final end = _getDotById(line.bId);
      if (start == null || end == null) {
        continue;
      }

      final a = connectDotToViewboxPoint(start);
      final b = connectDotToViewboxPoint(end);
      canvas.drawLine(
        _toLocal(a.dx, a.dy),
        _toLocal(b.dx, b.dy),
        line.onGuide ? lockedPaint : wrongPaint,
      );
    }

    for (final line in previewLines) {
      canvas.drawLine(
        _toLocal(line.x1, line.y1),
        _toLocal(line.x2, line.y2),
        previewPaint,
      );
    }

    if (draftFrom != null && draftTo != null) {
      final from = _toLocal(draftFrom!.dx, draftFrom!.dy);
      final to = _toLocal(draftTo!.dx, draftTo!.dy);
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..lineTo(to.dx, to.dy);
      canvas.drawPath(
        buildDashedPath(path, dashArray: const [4, 3]),
        draftPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectDotsLinePainter oldDelegate) {
    return oldDelegate.padSize != padSize ||
        oldDelegate.drawnLines != drawnLines ||
        oldDelegate.previewLines != previewLines ||
        oldDelegate.draftFrom != draftFrom ||
        oldDelegate.draftTo != draftTo;
  }
}

class _ConnectDotNode extends StatefulWidget {
  const _ConnectDotNode({
    super.key,
    required this.dot,
    required this.dotColor,
    required this.dotMode,
    required this.padSize,
    required this.isActive,
    required this.revealDelayMs,
  });

  final ConnectDot dot;
  final Color dotColor;
  final String dotMode;
  final double padSize;
  final bool isActive;
  final int revealDelayMs;

  @override
  State<_ConnectDotNode> createState() => _ConnectDotNodeState();
}

class _ConnectDotNodeState extends State<_ConnectDotNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;
  late final Animation<double> _enterProgress;
  Timer? _enterTimer;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: kFruitPopDurationMs),
    );
    _enterProgress = CurvedAnimation(
      parent: _enterController,
      curve: _popCurve,
    );
    _scheduleEnterAnimation();
  }

  void _scheduleEnterAnimation() {
    if (widget.revealDelayMs <= 0) {
      _enterController.value = 1;
      return;
    }

    _enterTimer = Timer(Duration(milliseconds: widget.revealDelayMs), () {
      if (mounted) {
        _enterController.forward();
      }
    });
  }

  @override
  void didUpdateWidget(_ConnectDotNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revealDelayMs != widget.revealDelayMs) {
      _enterTimer?.cancel();
      _enterController.value = 0;
      _scheduleEnterAnimation();
    }
  }

  @override
  void dispose() {
    _enterTimer?.cancel();
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final point = connectDotToViewboxPoint(widget.dot);
    final scale = widget.padSize / connectDotsViewboxSize;
    final centerX = point.dx * scale;
    final centerY = point.dy * scale;
    final radius = (widget.isActive ? 6.5 : 5.5) * scale;
    final showNumber =
        widget.dotMode == 'numbered' && widget.dot.number != null;

    return Positioned(
      left: centerX - radius,
      top: centerY - radius,
      width: radius * 2,
      height: radius * 2,
      child: AnimatedBuilder(
        animation: _enterProgress,
        builder: (context, child) {
          final t = _enterProgress.value.clamp(0.0, 1.0);

          return Opacity(
            opacity: t,
            child: Transform.scale(
              scale: 0.88 + 0.12 * t,
              child: child,
            ),
          );
        },
        child: IgnorePointer(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isActive
                      ? connectDotsDotActiveColor
                      : Colors.white,
                  border: Border.all(
                    color: widget.isActive
                        ? connectDotsDotActiveColor
                        : connectDotsDotStrokeColor,
                    width: 2 * scale,
                  ),
                ),
              ),
              if (showNumber)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${widget.dot.number}',
                    style: GoogleFonts.onest(
                      fontSize: 5.5 * scale,
                      fontWeight: FontWeight.w700,
                      color: widget.isActive
                          ? Colors.white
                          : connectDotsDotNumberColor,
                      height: 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectActionsShake extends StatefulWidget {
  const _ConnectActionsShake({
    required this.isShaking,
    required this.child,
  });

  final bool isShaking;
  final Widget child;

  @override
  State<_ConnectActionsShake> createState() => _ConnectActionsShakeState();
}

class _ConnectActionsShakeState extends State<_ConnectActionsShake>
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
  }

  @override
  void didUpdateWidget(_ConnectActionsShake oldWidget) {
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
      animation: _offset,
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
