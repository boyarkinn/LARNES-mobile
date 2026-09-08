import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/abacus_match_card.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/match_task_model.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/digit_target.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/match_hit_test.dart';
import 'package:larnes_mobile/trainers/runtime/trainer_play_hud_inset.dart';
import 'package:larnes_mobile/trainers/shared/dot_group.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

class _DrawLine {
  const _DrawLine({required this.from, required this.to});

  final Offset from;
  final Offset to;
}

class _ActiveDraw {
  const _ActiveDraw({
    required this.from,
    required this.sourceId,
    required this.to,
  });

  final Offset from;
  final String sourceId;
  final Offset to;
}

class _WrongFlash {
  const _WrongFlash({required this.from, required this.to});

  final Offset from;
  final Offset to;
}

class MatchTaskBoardLayout {
  const MatchTaskBoardLayout({
    required this.abacusHeight,
    required this.abacusWidth,
    required this.columnGap,
    required this.digitFontSize,
    required this.digitSize,
    required this.dotFrameHeight,
    required this.dotFrameWidth,
    required this.rowGap,
  });

  final double abacusHeight;
  final double abacusWidth;
  final double columnGap;
  final double digitFontSize;
  final double digitSize;
  final double dotFrameHeight;
  final double dotFrameWidth;
  final double rowGap;
}

MatchTaskBoardLayout computeMatchTaskBoardLayout({
  required double viewportWidth,
  required double viewportHeight,
  required int dotCount,
}) {
  final digitSize = math.min(viewportHeight * 0.12, 72.0);
  final digitFontSize = math.min(viewportHeight * 0.08, 48.0);
  final abacusHeight = math.min(viewportHeight * 0.12, 104.0);
  final abacusWidth = math.min(viewportWidth * 0.28, 176.0);
  final dotFrame = dotCount <= 9 ? 112.0 : 160.0;

  return MatchTaskBoardLayout(
    abacusHeight: abacusHeight,
    abacusWidth: abacusWidth,
    columnGap: math.max(8, viewportWidth * 0.02),
    digitFontSize: digitFontSize,
    digitSize: digitSize,
    dotFrameHeight: dotFrame,
    dotFrameWidth: dotFrame,
    rowGap: math.max(12, viewportHeight * 0.02),
  );
}

class MatchTaskBoard extends StatefulWidget {
  const MatchTaskBoard({
    super.key,
    required this.plan,
    required this.connections,
    this.disabled = false,
    required this.onConnect,
    required this.onAllConnected,
  });

  final MatchTaskPlan plan;
  final List<MatchTaskConnection> connections;
  final bool disabled;
  final ValueChanged<MatchTaskConnection> onConnect;
  final VoidCallback onAllConnected;

  @override
  State<MatchTaskBoard> createState() => _MatchTaskBoardState();
}

class _MatchTaskBoardState extends State<MatchTaskBoard> {
  final _boardKey = GlobalKey();
  final _dotsKey = GlobalKey();
  final _digitKeys = <String, GlobalKey>{};
  final _abacusKeys = <String, GlobalKey>{};

  _ActiveDraw? _activeDraw;
  _WrongFlash? _wrongFlash;
  String? _wrongTargetId;
  Timer? _wrongFlashTimer;
  var _layoutVersion = 0;
  var _completeNotified = false;

  @override
  void initState() {
    super.initState();
    _ensureKeys();
  }

  @override
  void didUpdateWidget(MatchTaskBoard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.plan != widget.plan) {
      _ensureKeys();
      _completeNotified = false;
    }

    if (oldWidget.connections != widget.connections) {
      _scheduleLineRelayout();
      if (!_completeNotified && isMatchTaskComplete(widget.connections)) {
        _completeNotified = true;
        widget.onAllConnected();
      }
    }

    if (oldWidget.disabled && !widget.disabled) {
      _completeNotified = false;
    }
  }

  void _ensureKeys() {
    for (final item in widget.plan.digitItems) {
      _digitKeys.putIfAbsent(item.id, GlobalKey.new);
    }
    for (final item in widget.plan.abacusItems) {
      _abacusKeys.putIfAbsent(item.id, GlobalKey.new);
    }
  }

  void _scheduleLineRelayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _layoutVersion++);
      }
    });
  }

  @override
  void dispose() {
    _wrongFlashTimer?.cancel();
    super.dispose();
  }

  MatchTaskStep get _step => getMatchTaskStep(widget.connections);

  MatchTaskConnection? get _dotsDigitConnection {
    for (final connection in widget.connections) {
      if (connection.kind == MatchTaskConnectionKind.dotsDigit) {
        return connection;
      }
    }
    return null;
  }

  RenderBox? get _boardBox =>
      _boardKey.currentContext?.findRenderObject() as RenderBox?;

  RenderBox? _itemBox(GlobalKey key) =>
      key.currentContext?.findRenderObject() as RenderBox?;

  Offset? _getAnchor(GlobalKey key, {required bool rightSide}) {
    final boardBox = _boardBox;
    final itemBox = _itemBox(key);

    if (boardBox == null || itemBox == null) {
      return null;
    }

    final anchor = getElementAnchorPoint(
      itemBox,
      boardBox,
      rightSide: rightSide,
    );

    return boardPointToOffset(anchor);
  }

  Offset? _relativePoint(Offset globalPosition) {
    final boardBox = _boardBox;

    if (boardBox == null) {
      return null;
    }

    final boardOrigin = boardBox.localToGlobal(Offset.zero);
    return globalPosition - boardOrigin;
  }

  int _colorForSource(String sourceId) {
    if (sourceId == dotsSourceId) {
      final target = widget.plan.digitItems
          .where((item) => item.id == widget.plan.targetDigitId)
          .firstOrNull;
      return target?.displayColor ?? 0xFFFB923C;
    }

    return widget.plan.digitItems
            .where((item) => item.id == sourceId)
            .firstOrNull
            ?.displayColor ??
        0xFFFB923C;
  }

  List<({Color color, _DrawLine line})> _lockedLines() {
    final lines = <({Color color, _DrawLine line})>[];

    for (final connection in widget.connections) {
      if (connection.kind == MatchTaskConnectionKind.dotsDigit) {
        final from = _getAnchor(_dotsKey, rightSide: true);
        final digitKey = _digitKeys[connection.toId];
        final to = digitKey == null
            ? null
            : _getAnchor(digitKey, rightSide: false);

        if (from != null && to != null) {
          final color = Color(
            widget.plan.digitItems
                    .where((item) => item.id == connection.toId)
                    .firstOrNull
                    ?.displayColor ??
                0xFF34D399,
          );
          lines.add((color: color, line: _DrawLine(from: from, to: to)));
        }
      }

      if (connection.kind == MatchTaskConnectionKind.digitAbacus) {
        final digitKey = _digitKeys[connection.fromId];
        final abacusKey = _abacusKeys[connection.toId];
        final from = digitKey == null
            ? null
            : _getAnchor(digitKey, rightSide: true);
        final to = abacusKey == null
            ? null
            : _getAnchor(abacusKey, rightSide: false);

        if (from != null && to != null) {
          final color = Color(
            widget.plan.digitItems
                    .where((item) => item.id == connection.fromId)
                    .firstOrNull
                    ?.displayColor ??
                0xFF34D399,
          );
          lines.add((color: color, line: _DrawLine(from: from, to: to)));
        }
      }
    }

    return lines;
  }

  MatchTaskItem? _findDigitTarget(List<Offset> points) {
    final boardBox = _boardBox;
    if (boardBox == null || _step != MatchTaskStep.dotsToDigit) {
      return null;
    }

    return pickTargetAtPoints<MatchTaskItem>(
      board: boardBox,
      elements: widget.plan.digitItems,
      getElement: (item) {
        final key = _digitKeys[item.id];
        return key == null ? null : _itemBox(key);
      },
      isAvailable: (_) => true,
      points: points.map(offsetToBoardPoint).toList(),
      padding: 20,
    );
  }

  MatchTaskItem? _findAbacusTarget(List<Offset> points) {
    final boardBox = _boardBox;
    if (boardBox == null || _step != MatchTaskStep.digitToAbacus) {
      return null;
    }

    return pickTargetAtPoints<MatchTaskItem>(
      board: boardBox,
      elements: widget.plan.abacusItems,
      getElement: (item) {
        final key = _abacusKeys[item.id];
        return key == null ? null : _itemBox(key);
      },
      isAvailable: (_) => true,
      points: points.map(offsetToBoardPoint).toList(),
      padding: 20,
    );
  }

  void _flashWrongTarget(String targetId, _WrongFlash flash) {
    _wrongFlashTimer?.cancel();
    setState(() {
      _wrongTargetId = targetId;
      _wrongFlash = flash;
    });
    _wrongFlashTimer = Timer(
      const Duration(milliseconds: TrainerTimings.wrongConnectionFlashMs),
      () {
        if (mounted) {
          setState(() {
            _wrongTargetId = null;
            _wrongFlash = null;
          });
        }
      },
    );
  }

  void _finishDraw(Offset releasePoint) {
    final activeDraw = _activeDraw;
    if (activeDraw == null) {
      return;
    }

    setState(() => _activeDraw = null);

    if (_step == MatchTaskStep.dotsToDigit &&
        activeDraw.sourceId == dotsSourceId) {
      final digitItem = _findDigitTarget([releasePoint, activeDraw.to]);
      if (digitItem == null) {
        return;
      }

      final digitKey = _digitKeys[digitItem.id];
      final wrongTo = digitKey == null
          ? null
          : _getAnchor(digitKey, rightSide: false);

      if (digitItem.id != widget.plan.targetDigitId) {
        if (wrongTo != null) {
          _flashWrongTarget(
            digitItem.id,
            _WrongFlash(from: activeDraw.from, to: wrongTo),
          );
        }
        return;
      }

      widget.onConnect(
        MatchTaskConnection(
          fromId: dotsSourceId,
          kind: MatchTaskConnectionKind.dotsDigit,
          toId: digitItem.id,
          value: widget.plan.targetValue,
        ),
      );
      return;
    }

    if (_step == MatchTaskStep.digitToAbacus &&
        activeDraw.sourceId == widget.plan.targetDigitId) {
      final abacusItem = _findAbacusTarget([releasePoint, activeDraw.to]);
      if (abacusItem == null) {
        return;
      }

      final abacusKey = _abacusKeys[abacusItem.id];
      final wrongTo = abacusKey == null
          ? null
          : _getAnchor(abacusKey, rightSide: false);

      if (abacusItem.id != widget.plan.targetAbacusId) {
        if (wrongTo != null) {
          _flashWrongTarget(
            abacusItem.id,
            _WrongFlash(from: activeDraw.from, to: wrongTo),
          );
        }
        return;
      }

      widget.onConnect(
        MatchTaskConnection(
          fromId: widget.plan.targetDigitId,
          kind: MatchTaskConnectionKind.digitAbacus,
          toId: abacusItem.id,
          value: widget.plan.targetValue,
        ),
      );
    }
  }

  void _handleDotsPointerDown(PointerDownEvent event) {
    if (widget.disabled || _step != MatchTaskStep.dotsToDigit) {
      return;
    }

    final from = _getAnchor(_dotsKey, rightSide: true);
    final to = _relativePoint(event.position);

    if (from == null || to == null) {
      return;
    }

    setState(() {
      _activeDraw = _ActiveDraw(from: from, sourceId: dotsSourceId, to: to);
    });
  }

  void _handleDotsPointerUp(PointerUpEvent event) {
    final activeDraw = _activeDraw;
    if (activeDraw == null || activeDraw.sourceId != dotsSourceId) {
      return;
    }

    final point = _relativePoint(event.position);
    if (point != null) {
      _finishDraw(point);
    }
  }

  void _handleDigitPointerDown(String digitId, PointerDownEvent event) {
    if (widget.disabled ||
        _step != MatchTaskStep.digitToAbacus ||
        digitId != widget.plan.targetDigitId) {
      return;
    }

    final digitKey = _digitKeys[digitId];
    if (digitKey == null) {
      return;
    }

    final from = _getAnchor(digitKey, rightSide: true);
    final to = _relativePoint(event.position);

    if (from == null || to == null) {
      return;
    }

    setState(() {
      _activeDraw = _ActiveDraw(from: from, sourceId: digitId, to: to);
    });
  }

  void _handleDigitPointerUp(String digitId, PointerUpEvent event) {
    final activeDraw = _activeDraw;
    if (activeDraw == null || activeDraw.sourceId != digitId) {
      return;
    }

    final point = _relativePoint(event.position);
    if (point != null) {
      _finishDraw(point);
    }
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
        sourceId: _activeDraw!.sourceId,
        to: to,
      );
    });
  }

  void _handlePointerEnd(PointerEvent event) {
    if (_activeDraw == null) {
      return;
    }

    final point = _relativePoint(event.position);
    if (point != null) {
      _finishDraw(point);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockedLines = _lockedLines();
    final missingAnchors =
        widget.connections.isNotEmpty &&
        lockedLines.length < widget.connections.length;

    if (missingAnchors) {
      _scheduleLineRelayout();
    }

    // Touch [_layoutVersion] so lines repaint after resize/connection updates.
    // ignore: unnecessary_statements
    _layoutVersion;

    final connectedDigitId = _dotsDigitConnection?.toId;
    final connectedAbacusId = widget.connections
        .where(
          (connection) =>
              connection.kind == MatchTaskConnectionKind.digitAbacus,
        )
        .map((connection) => connection.toId)
        .firstOrNull;

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = computeMatchTaskBoardLayout(
          viewportWidth: constraints.maxWidth,
          viewportHeight: constraints.maxHeight,
          dotCount: widget.plan.dotsValue,
        );
        final hudSideInset = computeTrainerPlayHudSideInset(context);

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerMove: widget.disabled ? null : _handlePointerMove,
          onPointerUp: widget.disabled ? null : _handlePointerEnd,
          onPointerCancel: widget.disabled ? null : _handlePointerEnd,
          child: SizedBox(
            key: _boardKey,
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hudSideInset),
                  child: Center(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(
                            child: Listener(
                              onPointerDown: _handleDotsPointerDown,
                              onPointerUp: _handleDotsPointerUp,
                              child: KeyedSubtree(
                                key: _dotsKey,
                                child: DotGroup(
                                  count: widget.plan.dotsValue,
                                  frameWidth: layout.dotFrameWidth,
                                  frameHeight: layout.dotFrameHeight,
                                  visibleCount: widget.plan.dotsValue,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: layout.columnGap),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (
                                var index = 0;
                                index < widget.plan.digitItems.length;
                                index++
                              ) ...[
                                if (index > 0) SizedBox(height: layout.rowGap),
                                _buildDigitItem(
                                  item: widget.plan.digitItems[index],
                                  layout: layout,
                                  connected:
                                      connectedDigitId ==
                                      widget.plan.digitItems[index].id,
                                  shake:
                                      _wrongTargetId ==
                                      widget.plan.digitItems[index].id,
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: layout.columnGap),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (
                                var index = 0;
                                index < widget.plan.abacusItems.length;
                                index++
                              ) ...[
                                if (index > 0) SizedBox(height: layout.rowGap),
                                KeyedSubtree(
                                  key:
                                      _abacusKeys[widget
                                          .plan
                                          .abacusItems[index]
                                          .id],
                                  child: AbacusMatchCard(
                                    connected:
                                        connectedAbacusId ==
                                        widget.plan.abacusItems[index].id,
                                    height: layout.abacusHeight,
                                    shake:
                                        _wrongTargetId ==
                                        widget.plan.abacusItems[index].id,
                                    value: widget.plan.abacusItems[index].value,
                                    width: layout.abacusWidth,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ConnectionLinesPainter(
                        activeDraw: _activeDraw,
                        activeDrawColor: Color(
                          _activeDraw == null
                              ? 0xFFFB923C
                              : _colorForSource(_activeDraw!.sourceId),
                        ),
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
      },
    );
  }

  Widget _buildDigitItem({
    required MatchTaskItem item,
    required MatchTaskBoardLayout layout,
    required bool connected,
    required bool shake,
  }) {
    final canDrag =
        _step == MatchTaskStep.digitToAbacus &&
        item.id == widget.plan.targetDigitId &&
        !widget.disabled;

    final digit = DigitTarget(
      color: Color(item.displayColor),
      connected: connected,
      digit: item.value,
      fontSize: layout.digitFontSize,
      size: layout.digitSize,
    );

    final wrapped = KeyedSubtree(
      key: _digitKeys[item.id],
      child: canDrag
          ? Listener(
              onPointerDown: (event) => _handleDigitPointerDown(item.id, event),
              onPointerUp: (event) => _handleDigitPointerUp(item.id, event),
              child: digit,
            )
          : digit,
    );

    if (!shake) {
      return wrapped;
    }

    return _ShakeDigit(active: shake, child: wrapped);
  }
}

class _ShakeDigit extends StatefulWidget {
  const _ShakeDigit({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_ShakeDigit> createState() => _ShakeDigitState();
}

class _ShakeDigitState extends State<_ShakeDigit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    if (widget.active) {
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(_ShakeDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
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
        final t = _controller.value;
        final dx = t <= 0.2
            ? -8 * (t / 0.2)
            : t <= 0.4
            ? -8 + 16 * ((t - 0.2) / 0.2)
            : t <= 0.6
            ? 8 - 13 * ((t - 0.4) / 0.2)
            : t <= 0.8
            ? -5 + 10 * ((t - 0.6) / 0.2)
            : 5 * (1 - ((t - 0.8) / 0.2));

        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

class _ConnectionLinesPainter extends CustomPainter {
  _ConnectionLinesPainter({
    required this.lockedLines,
    required this.activeDraw,
    required this.activeDrawColor,
    required this.wrongFlash,
  });

  final List<({Color color, _DrawLine line})> lockedLines;
  final _ActiveDraw? activeDraw;
  final Color activeDrawColor;
  final _WrongFlash? wrongFlash;

  @override
  void paint(Canvas canvas, Size size) {
    for (final entry in lockedLines) {
      canvas.drawLine(
        entry.line.from,
        entry.line.to,
        Paint()
          ..color = entry.color
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }

    if (activeDraw != null) {
      _drawDashedLine(
        canvas,
        activeDraw!.from,
        activeDraw!.to,
        Paint()
          ..color = activeDrawColor
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
        oldDelegate.activeDrawColor != activeDrawColor ||
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
