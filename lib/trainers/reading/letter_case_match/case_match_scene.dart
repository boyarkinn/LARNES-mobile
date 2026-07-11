import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/flashcard_digit_match/match_hit_test.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_field_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_case_match/case_match_card.dart';
import 'package:larnes_mobile/trainers/reading/letter_case_match/case_match_layout.dart';
import 'package:larnes_mobile/trainers/reading/letter_case_match/case_match_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_case_match/case_match_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_case_match/case_match_size.dart';
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

/// Web: `platform/src/trainers/reading/letter-case-match/case-match-scene.tsx`
class CaseMatchScene extends StatefulWidget {
  const CaseMatchScene({
    super.key,
    required this.round,
    required this.connections,
    required this.colorByLeftId,
    required this.onConnect,
    this.disabled = false,
  });

  final LetterMatchRound round;
  final List<LetterMatchConnection> connections;
  final Map<String, String> colorByLeftId;
  final ValueChanged<LetterMatchConnection> onConnect;
  final bool disabled;

  @override
  State<CaseMatchScene> createState() => _CaseMatchSceneState();
}

class _CaseMatchSceneState extends State<CaseMatchScene> {
  final _boardKey = GlobalKey();
  final _leftKeys = <String, GlobalKey>{};
  final _rightKeys = <String, GlobalKey>{};

  _ActiveDraw? _activeDraw;
  _WrongFlash? _wrongFlash;
  String? _wrongFlashRightId;
  Timer? _wrongFlashTimer;
  Timer? _interactionTimer;
  var _isInteractionReady = false;
  var _layoutVersion = 0;

  @override
  void initState() {
    super.initState();
    _ensureKeys();
    _scheduleInteractionReady();
  }

  @override
  void didUpdateWidget(CaseMatchScene oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.round, widget.round)) {
      _ensureKeys();
      _isInteractionReady = false;
      _scheduleInteractionReady();
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

  void _scheduleInteractionReady() {
    _interactionTimer?.cancel();
    _interactionTimer = Timer(
      Duration(
        milliseconds: getCaseMatchInteractionReadyMs(
          widget.round.leftItems.length,
        ),
      ),
      () {
        if (mounted) {
          setState(() => _isInteractionReady = true);
        }
      },
    );
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
    _interactionTimer?.cancel();
    super.dispose();
  }

  bool get _isLocked => widget.disabled || !_isInteractionReady;

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

    return boardPointToOffset(
      getElementAnchorPoint(
        itemBox,
        boardBox,
        rightSide: rightSide,
      ),
    );
  }

  Offset? _relativePoint(Offset globalPosition) {
    final boardBox = _boardBox;

    if (boardBox == null) {
      return null;
    }

    return globalPosition - boardBox.localToGlobal(Offset.zero);
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

  LetterMatchSideItem? _findRightTarget(List<Offset> points) {
    final boardBox = _boardBox;
    if (boardBox == null) {
      return null;
    }

    return pickTargetAtPoints<LetterMatchSideItem>(
      board: boardBox,
      elements: widget.round.rightItems,
      getElement: (item) {
        final key = _rightKeys[item.id];
        return key == null ? null : _itemBox(key);
      },
      isAvailable: (item) => !_connectedRightIds.contains(item.id),
      points: points.map(offsetToBoardPoint).toList(),
      padding: 20,
    );
  }

  void _handleLeftPointerDown(String leftId, PointerDownEvent event) {
    if (_isLocked || _connectedLeftIds.contains(leftId)) {
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

  void _handleLeftPointerEnd(String leftId, PointerEvent event) {
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
    if (_activeDraw == null || _isLocked) {
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

  void _handlePointerEnd(PointerEvent event) {
    if (_activeDraw == null) {
      return;
    }

    final point = _relativePoint(event.position);
    if (point != null) {
      _finishDraw(point);
    }
  }

  void _finishDraw(Offset releasePoint) {
    final activeDraw = _activeDraw;
    if (activeDraw == null) {
      return;
    }

    setState(() => _activeDraw = null);

    LetterMatchSideItem? leftItem;
    for (final item in widget.round.leftItems) {
      if (item.id == activeDraw.leftId) {
        leftItem = item;
        break;
      }
    }

    if (leftItem == null) {
      return;
    }

    final rightItem = _findRightTarget([releasePoint, activeDraw.to]);
    if (rightItem == null) {
      return;
    }

    if (isCorrectLetterMatch(leftItem.letter, rightItem.letter)) {
      widget.onConnect(
        LetterMatchConnection(
          leftId: leftItem.id,
          letter: leftItem.letter,
          rightId: rightItem.id,
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
        _wrongFlashRightId = rightItem.id;
      });
      _wrongFlashTimer = Timer(
        const Duration(milliseconds: TrainerTimings.wrongConnectionFlashMs),
        () {
          if (mounted) {
            setState(() {
              _wrongFlash = null;
              _wrongFlashRightId = null;
            });
          }
        },
      );
    }
  }

  Widget _buildLeftCard(
    LetterMatchSideItem item,
    double boxSize,
    double fontSize,
    int revealDelayMs,
  ) {
    return LowercaseCaseMatchCard(
      connected: _connectedLeftIds.contains(item.id),
      disabled: _isLocked,
      displayColor: letterDisplayColorFromHex(
        widget.colorByLeftId[item.id],
      ),
      displayLetter: item.displayLetter,
      boxSize: boxSize,
      fontSize: fontSize,
      revealDelayMs: revealDelayMs,
      onPointerDown: (event) => _handleLeftPointerDown(item.id, event),
      onPointerEnd: (event) => _handleLeftPointerEnd(item.id, event),
    );
  }

  Widget _buildRightCard(
    LetterMatchSideItem item,
    double boxSize,
    double fontSize,
    int revealDelayMs,
  ) {
    return UppercaseCaseMatchCard(
      connected: _connectedRightIds.contains(item.id),
      displayLetter: item.displayLetter,
      boxSize: boxSize,
      fontSize: fontSize,
      revealDelayMs: revealDelayMs,
      wrongFlash: _wrongFlashRightId == item.id,
    );
  }

  Widget _buildGridSide({
    required MatchSide side,
    required List<LetterMatchSideItem> items,
    required int pairCount,
    required double viewportHeight,
    required double viewportWidth,
    required double sideWidth,
  }) {
    final rowHeight = getCaseMatchGridRowHeight(viewportHeight);
    final rowGap = getCaseMatchGridRowGap(viewportHeight);
    final columnGap = getCaseMatchGridColumnGap(viewportHeight);
    final gridHeight = rowHeight * 2 + rowGap;
    final columnWidth = (sideWidth - columnGap) / 2;
    final boxSize = getCaseMatchLetterBoxSize(viewportHeight, viewportWidth, pairCount);
    final fontSize = getCaseMatchLetterFontSize(viewportHeight, viewportWidth, pairCount);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: side == MatchSide.left ? 4 : 0,
      ),
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: sideWidth,
          height: gridHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var index = 0; index < items.length; index++)
                () {
                  final item = items[index];
                  final slot = getCaseMatchGridSlotLayout(
                    index: index,
                    count: pairCount,
                    side: side,
                  );
                  final key = side == MatchSide.left
                      ? _leftKeys[item.id]!
                      : _rightKeys[item.id]!;
                  final left = slot.column * (columnWidth + columnGap);
                  final top = slot.row * (rowHeight + rowGap);
                  final width = columnWidth * slot.columnSpan +
                      columnGap * (slot.columnSpan - 1);
                  final height =
                      rowHeight * slot.rowSpan + rowGap * (slot.rowSpan - 1);
                  final revealDelayMs =
                      getCaseMatchCardRevealDelayMs(index, pairCount);
                  final card = side == MatchSide.left
                      ? _buildLeftCard(item, boxSize, fontSize, revealDelayMs)
                      : _buildRightCard(item, boxSize, fontSize, revealDelayMs);

                  return Positioned(
                    left: left,
                    top: top,
                    width: width,
                    height: height,
                    child: Align(
                      alignment: slot.alignment,
                      child: KeyedSubtree(
                        key: key,
                        child: card,
                      ),
                    ),
                  );
                }(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlexSide({
    required MatchSide side,
    required List<LetterMatchSideItem> items,
    required int pairCount,
    required double viewportHeight,
    required double viewportWidth,
  }) {
    final gap = getCaseMatchFlexColumnGap(viewportHeight);
    final paddingVertical =
        getCaseMatchFlexColumnPaddingVertical(viewportHeight);
    final boxSize = getCaseMatchLetterBoxSize(viewportHeight, viewportWidth, pairCount);
    final fontSize = getCaseMatchLetterFontSize(viewportHeight, viewportWidth, pairCount);

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: paddingVertical,
        horizontal: side == MatchSide.left ? 8 : 8,
      ),
      child: Align(
        alignment: getCaseMatchFlexColumnAlignment(side),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0) SizedBox(height: gap),
              Builder(
                builder: (context) {
                  final item = items[index];
                  final key = side == MatchSide.left
                      ? _leftKeys[item.id]!
                      : _rightKeys[item.id]!;
                  final revealDelayMs =
                      getCaseMatchCardRevealDelayMs(index, pairCount);
                  final card = side == MatchSide.left
                      ? _buildLeftCard(item, boxSize, fontSize, revealDelayMs)
                      : _buildRightCard(item, boxSize, fontSize, revealDelayMs);

                  return KeyedSubtree(key: key, child: card);
                },
              ),
            ],
          ],
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
        final pairCount = widget.round.leftItems.length;
        final useGrid = usesCaseMatchGridLayout(pairCount);
        final sideWidth = constraints.maxWidth / 2;

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerMove: _isLocked ? null : _handlePointerMove,
          onPointerUp: _isLocked ? null : _handlePointerEnd,
          onPointerCancel: _isLocked ? null : _handlePointerEnd,
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
                      child: useGrid
                          ? _buildGridSide(
                              side: MatchSide.left,
                              items: widget.round.leftItems,
                              pairCount: pairCount,
                              viewportHeight: constraints.maxHeight,
                              viewportWidth: constraints.maxWidth,
                              sideWidth: sideWidth,
                            )
                          : _buildFlexSide(
                              side: MatchSide.left,
                              items: widget.round.leftItems,
                              pairCount: pairCount,
                              viewportHeight: constraints.maxHeight,
                              viewportWidth: constraints.maxWidth,
                            ),
                    ),
                    Expanded(
                      child: useGrid
                          ? _buildGridSide(
                              side: MatchSide.right,
                              items: widget.round.rightItems,
                              pairCount: pairCount,
                              viewportHeight: constraints.maxHeight,
                              viewportWidth: constraints.maxWidth,
                              sideWidth: sideWidth,
                            )
                          : _buildFlexSide(
                              side: MatchSide.right,
                              items: widget.round.rightItems,
                              pairCount: pairCount,
                              viewportHeight: constraints.maxHeight,
                              viewportWidth: constraints.maxWidth,
                            ),
                    ),
                  ],
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _CaseMatchLinesPainter(
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

class _CaseMatchLinesPainter extends CustomPainter {
  _CaseMatchLinesPainter({
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
      ..color = caseMatchLineLockedColor
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
          ..color = caseMatchLineDraftColor
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }

    if (wrongFlash != null) {
      canvas.drawLine(
        wrongFlash!.from,
        wrongFlash!.to,
        Paint()
          ..color = caseMatchLineWrongColor
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
  bool shouldRepaint(covariant _CaseMatchLinesPainter oldDelegate) {
    return oldDelegate.lockedLines != lockedLines ||
        oldDelegate.activeDraw != activeDraw ||
        oldDelegate.wrongFlash != wrongFlash;
  }
}
