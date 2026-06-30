import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/digit_target.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/flash_card.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/flashcard_digit_match_model.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

const _hitRadius = 56.0;

class _DrawLine {
  const _DrawLine({required this.from, required this.to});

  final Offset from;
  final Offset to;
}

class _ActiveDraw {
  const _ActiveDraw({
    required this.from,
    required this.leftId,
    required this.to,
  });

  final Offset from;
  final String leftId;
  final Offset to;
}

class _WrongFlash {
  const _WrongFlash({
    required this.from,
    required this.to,
  });

  final Offset from;
  final Offset to;
}

class MatchBoard extends StatefulWidget {
  const MatchBoard({
    super.key,
    required this.round,
    required this.totalRods,
    required this.connections,
    this.disabled = false,
    required this.onConnect,
  });

  final MatchRound round;
  final int totalRods;
  final List<MatchConnection> connections;
  final bool disabled;
  final ValueChanged<MatchConnection> onConnect;

  @override
  State<MatchBoard> createState() => _MatchBoardState();
}

class _MatchBoardState extends State<MatchBoard> {
  final _boardKey = GlobalKey();
  final _leftKeys = <String, GlobalKey>{};
  final _rightKeys = <String, GlobalKey>{};

  _ActiveDraw? _activeDraw;
  _WrongFlash? _wrongFlash;
  Timer? _wrongFlashTimer;

  @override
  void initState() {
    super.initState();
    _ensureKeys();
  }

  @override
  void didUpdateWidget(MatchBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.round != widget.round) {
      _ensureKeys();
    }
  }

  void _ensureKeys() {
    for (final item in widget.round.leftItems) {
      _leftKeys.putIfAbsent(item.id, GlobalKey.new);
    }
    for (final item in widget.round.rightItems) {
      _rightKeys.putIfAbsent(item.id, GlobalKey.new);
    }
  }

  @override
  void dispose() {
    _wrongFlashTimer?.cancel();
    super.dispose();
  }

  Set<String> get _connectedLeftIds =>
      widget.connections.map((connection) => connection.leftId).toSet();

  Set<String> get _connectedRightIds =>
      widget.connections.map((connection) => connection.rightId).toSet();

  Offset? _getAnchor(GlobalKey key, {required bool rightSide}) {
    final boardBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    final itemBox = key.currentContext?.findRenderObject() as RenderBox?;

    if (boardBox == null || itemBox == null) {
      return null;
    }

    final itemOrigin = itemBox.localToGlobal(Offset.zero);
    final boardOrigin = boardBox.localToGlobal(Offset.zero);
    final x = rightSide
        ? itemOrigin.dx + itemBox.size.width - boardOrigin.dx
        : itemOrigin.dx - boardOrigin.dx;
    final y = itemOrigin.dy - boardOrigin.dy + itemBox.size.height / 2;

    return Offset(x, y);
  }

  Offset? _relativePoint(Offset globalPosition) {
    final boardBox = _boardKey.currentContext?.findRenderObject() as RenderBox?;

    if (boardBox == null) {
      return null;
    }

    final boardOrigin = boardBox.localToGlobal(Offset.zero);
    return globalPosition - boardOrigin;
  }

  List<_DrawLine> _lockedLines() {
    final lines = <_DrawLine>[];

    for (final connection in widget.connections) {
      final leftKey = _leftKeys[connection.leftId];
      final rightKey = _rightKeys[connection.rightId];

      if (leftKey == null || rightKey == null) {
        continue;
      }

      final from = _getAnchor(leftKey, rightSide: true);
      final to = _getAnchor(rightKey, rightSide: false);

      if (from != null && to != null) {
        lines.add(_DrawLine(from: from, to: to));
      }
    }

    return lines;
  }

  MatchItem? _findRightTarget(Offset point) {
    MatchItem? closest;
    var closestDistance = double.infinity;

    for (final item in widget.round.rightItems) {
      if (_connectedRightIds.contains(item.id)) {
        continue;
      }

      final key = _rightKeys[item.id];
      if (key == null) {
        continue;
      }

      final anchor = _getAnchor(key, rightSide: false);
      if (anchor == null) {
        continue;
      }

      final distance = (anchor - point).distance;
      if (distance <= _hitRadius && distance < closestDistance) {
        closest = item;
        closestDistance = distance;
      }
    }

    return closest;
  }

  void _handleLeftPointerDown(String leftId, PointerDownEvent event) {
    if (widget.disabled || _connectedLeftIds.contains(leftId)) {
      return;
    }

    final leftKey = _leftKeys[leftId];
    if (leftKey == null) {
      return;
    }

    final from = _getAnchor(leftKey, rightSide: true);
    final to = _relativePoint(event.position);

    if (from == null || to == null) {
      return;
    }

    setState(() {
      _activeDraw = _ActiveDraw(from: from, leftId: leftId, to: to);
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_activeDraw == null) {
      return;
    }

    final to = _relativePoint(event.position);
    if (to == null) {
      return;
    }

    setState(() {
      _activeDraw = _ActiveDraw(
        from: _activeDraw!.from,
        leftId: _activeDraw!.leftId,
        to: to,
      );
    });
  }

  void _finishDraw(Offset point) {
    final activeDraw = _activeDraw;
    if (activeDraw == null) {
      return;
    }

    final leftItem = widget.round.leftItems
        .where((item) => item.id == activeDraw.leftId)
        .firstOrNull;

    if (leftItem == null) {
      setState(() => _activeDraw = null);
      return;
    }

    final rightItem = _findRightTarget(point);

    if (rightItem == null) {
      setState(() => _activeDraw = null);
      return;
    }

    if (isCorrectConnection(leftItem.value, rightItem.value)) {
      widget.onConnect(
        MatchConnection(
          leftId: leftItem.id,
          rightId: rightItem.id,
          value: leftItem.value,
        ),
      );
      setState(() => _activeDraw = null);
      return;
    }

    final rightKey = _rightKeys[rightItem.id];
    final wrongTo =
        rightKey == null ? null : _getAnchor(rightKey, rightSide: false);

    setState(() => _activeDraw = null);

    if (wrongTo != null) {
      _wrongFlashTimer?.cancel();
      setState(() {
        _wrongFlash = _WrongFlash(from: activeDraw.from, to: wrongTo);
      });
      _wrongFlashTimer = Timer(
        const Duration(milliseconds: TrainerTimings.wrongConnectionFlashMs),
        () {
          if (mounted) {
            setState(() => _wrongFlash = null);
          }
        },
      );
    }
  }

  void _handlePointerEnd(PointerEvent event) {
    final point = _relativePoint(event.position);
    if (point != null) {
      _finishDraw(point);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockedLines = _lockedLines();
    final missingAnchors = widget.connections.isNotEmpty &&
        lockedLines.length < widget.connections.length;

    if (missingAnchors) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
        }
      });
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerEnd,
      onPointerCancel: _handlePointerEnd,
      child: DecoratedBox(
        key: _boardKey,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFEDD5)),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xCCFFF7ED),
              Colors.white,
            ],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        for (final item in widget.round.leftItems) ...[
                          KeyedSubtree(
                            key: _leftKeys[item.id],
                            child: FlashCard(
                              connected: _connectedLeftIds.contains(item.id),
                              disabled: widget.disabled,
                              onPointerDown: (event) =>
                                  _handleLeftPointerDown(item.id, event),
                              totalRods: widget.totalRods,
                              value: item.value,
                            ),
                          ),
                          if (item != widget.round.leftItems.last)
                            const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'соедини',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final item in widget.round.rightItems) ...[
                          KeyedSubtree(
                            key: _rightKeys[item.id],
                            child: DigitTarget(
                              connected: _connectedRightIds.contains(item.id),
                              digit: item.value,
                            ),
                          ),
                          if (item != widget.round.rightItems.last)
                            const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ConnectionLinesPainter(
                    activeDraw: _activeDraw,
                    lockedLines: lockedLines,
                    wrongFlash: _wrongFlash,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionLinesPainter extends CustomPainter {
  _ConnectionLinesPainter({
    required this.lockedLines,
    required this.activeDraw,
    required this.wrongFlash,
  });

  final List<_DrawLine> lockedLines;
  final _ActiveDraw? activeDraw;
  final _WrongFlash? wrongFlash;

  @override
  void paint(Canvas canvas, Size size) {
    final lockedPaint = Paint()
      ..color = const Color(0xFF34D399)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    for (final line in lockedLines) {
      canvas.drawLine(line.from, line.to, lockedPaint);
    }

    if (activeDraw != null) {
      _drawDashedLine(
        canvas,
        activeDraw!.from,
        activeDraw!.to,
        Paint()
          ..color = const Color(0xFFFB923C)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }

    if (wrongFlash != null) {
      canvas.drawLine(
        wrongFlash!.from,
        wrongFlash!.to,
        Paint()
          ..color = const Color(0xFFF87171)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx, to.dy);

    const dashWidth = 8.0;
    const dashSpace = 6.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionLinesPainter oldDelegate) {
    return oldDelegate.lockedLines != lockedLines ||
        oldDelegate.activeDraw != activeDraw ||
        oldDelegate.wrongFlash != wrongFlash;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) {
      return null;
    }
    return iterator.current;
  }
}
