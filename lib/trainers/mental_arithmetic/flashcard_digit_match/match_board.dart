import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/digit_target.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/flash_card.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/flashcard_digit_match_model.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/match_grid_layout.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/match_hit_test.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

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
  var _layoutVersion = 0;

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
    if (oldWidget.connections != widget.connections) {
      _scheduleLineRelayout();
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

  Set<String> get _connectedLeftIds =>
      widget.connections.map((connection) => connection.leftId).toSet();

  Set<String> get _connectedRightIds =>
      widget.connections.map((connection) => connection.rightId).toSet();

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

  MatchItem? _findRightTarget(List<Offset> points) {
    final boardBox = _boardBox;
    if (boardBox == null) {
      return null;
    }

    final boardPoints = points.map(offsetToBoardPoint).toList();

    return pickTargetAtPoints<MatchItem>(
      board: boardBox,
      elements: widget.round.rightItems,
      getElement: (item) {
        final key = _rightKeys[item.id];
        return key == null ? null : _itemBox(key);
      },
      isAvailable: (item) => !_connectedRightIds.contains(item.id),
      points: boardPoints,
      padding: 20,
    );
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

  void _handleLeftPointerUp(String leftId, PointerUpEvent event) {
    final activeDraw = _activeDraw;
    if (activeDraw == null || activeDraw.leftId != leftId) {
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
        leftId: _activeDraw!.leftId,
        to: to,
      );
    });
  }

  void _finishDraw(Offset releasePoint) {
    final activeDraw = _activeDraw;
    if (activeDraw == null) {
      return;
    }

    setState(() => _activeDraw = null);

    final leftItem = widget.round.leftItems
        .where((item) => item.id == activeDraw.leftId)
        .firstOrNull;

    if (leftItem == null) {
      return;
    }

    final rightItem = _findRightTarget([releasePoint, activeDraw.to]);

    if (rightItem == null) {
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
      return;
    }

    final rightKey = _rightKeys[rightItem.id];
    final wrongTo =
        rightKey == null ? null : _getAnchor(rightKey, rightSide: false);

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
    if (_activeDraw == null) {
      return;
    }

    final point = _relativePoint(event.position);
    if (point != null) {
      _finishDraw(point);
    }
  }

  Widget _buildSidePanel({
    required MatchSide side,
    required List<MatchItem> items,
    required int count,
    required MatchBoardLayout layout,
    required Widget Function(MatchItem item, GlobalKey key) buildItem,
  }) {
    final rowHeight = layout.rowHeight;
    final rowGap = layout.rowGap;
    final columnGap = layout.columnGap;
    final gridHeight = layout.gridHeight;

    return Padding(
      padding: EdgeInsets.only(
        top: layout.paddingTop,
        bottom: layout.paddingBottom,
        left: side == MatchSide.left ? 4 : 0,
        right: side == MatchSide.right ? 4 : 0,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columnWidth = (constraints.maxWidth - columnGap) / 2;

            return SizedBox(
              width: constraints.maxWidth,
              height: gridHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var index = 0; index < items.length; index++)
                    _buildGridSlot(
                      item: items[index],
                      index: index,
                      count: count,
                      side: side,
                      columnWidth: columnWidth,
                      rowHeight: rowHeight,
                      rowGap: rowGap,
                      columnGap: columnGap,
                      buildItem: buildItem,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGridSlot({
    required MatchItem item,
    required int index,
    required int count,
    required MatchSide side,
    required double columnWidth,
    required double rowHeight,
    required double rowGap,
    required double columnGap,
    required Widget Function(MatchItem item, GlobalKey key) buildItem,
  }) {
    final slot = getMatchGridSlotLayout(
      index: index,
      count: count,
      side: side,
    );
    final key = side == MatchSide.left ? _leftKeys[item.id]! : _rightKeys[item.id]!;

    final left = slot.column * (columnWidth + columnGap);
    final top = slot.row * (rowHeight + rowGap);
    final width = columnWidth * slot.columnSpan + columnGap * (slot.columnSpan - 1);
    final height = rowHeight * slot.rowSpan + rowGap * (slot.rowSpan - 1);

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Align(
        alignment: slot.alignment,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: slot.alignment,
          child: KeyedSubtree(
            key: key,
            child: buildItem(item, key),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lockedLines = _lockedLines();
    final missingAnchors = widget.connections.isNotEmpty &&
        lockedLines.length < widget.connections.length;

    if (missingAnchors) {
      _scheduleLineRelayout();
    }

    // Touch [_layoutVersion] so lines repaint after resize/connection updates.
    // ignore: unnecessary_statements
    _layoutVersion;

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = computeMatchBoardLayout(
          viewportWidth: constraints.maxWidth,
          viewportHeight: constraints.maxHeight,
        );
        final pairCount = widget.round.leftItems.length;

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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildSidePanel(
                        side: MatchSide.left,
                        items: widget.round.leftItems,
                        count: pairCount,
                        layout: layout,
                        buildItem: (item, _) => FlashCard(
                          abacusHeight: layout.abacusHeight,
                          connected: _connectedLeftIds.contains(item.id),
                          disabled: widget.disabled,
                          onPointerDown: (event) =>
                              _handleLeftPointerDown(item.id, event),
                          onPointerUp: (event) =>
                              _handleLeftPointerUp(item.id, event),
                          totalRods: widget.totalRods,
                          value: item.value,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _buildSidePanel(
                        side: MatchSide.right,
                        items: widget.round.rightItems,
                        count: pairCount,
                        layout: layout,
                        buildItem: (item, _) => DigitTarget(
                          connected: _connectedRightIds.contains(item.id),
                          digit: item.value,
                          fontSize: layout.digitFontSize,
                          size: layout.digitSize,
                        ),
                      ),
                    ),
                  ],
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
      },
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
