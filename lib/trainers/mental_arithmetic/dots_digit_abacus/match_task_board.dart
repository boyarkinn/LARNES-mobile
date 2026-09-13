import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/abacus_match_card.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/dots_digit_abacus_sizes.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/dots_digit_abacus/match_task_model.dart';
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
  final columnGap = math.max(6.0, math.min(16.0, viewportWidth * 0.02));
  final columnWidth = math.max(54.0, (viewportWidth - columnGap * 2) / 3);
  final rowGap = math.max(6.0, math.min(16.0, viewportHeight * 0.02));
  final optionHeight = math.max(42.0, (viewportHeight - rowGap * 2) / 3);
  final digitSize = math.min(math.min(optionHeight, columnWidth), 72.0);
  final digitFontSize = math.min(digitSize * 0.67, 48.0);
  final abacusHeight = math.min(optionHeight, 104.0);
  final abacusWidth = math.min(columnWidth, 176.0);
  final dotFrame = math.min(
    math.min(dotCount <= 9 ? 112.0 : 160.0, columnWidth),
    viewportHeight * 0.42,
  );

  return MatchTaskBoardLayout(
    abacusHeight: abacusHeight,
    abacusWidth: abacusWidth,
    columnGap: columnGap,
    digitFontSize: digitFontSize,
    digitSize: digitSize,
    dotFrameHeight: dotFrame,
    dotFrameWidth: dotFrame,
    rowGap: rowGap,
  );
}

class MatchTaskBoard extends StatefulWidget {
  const MatchTaskBoard({
    super.key,
    required this.plan,
    required this.connections,
    this.disabled = false,
    this.completed = false,
    this.preview = false,
    this.renderSharedObjects = true,
    required this.onConnect,
    required this.onAllConnected,
    this.onWrongAttempt,
  });

  final MatchTaskPlan plan;
  final List<MatchTaskConnection> connections;
  final bool disabled;
  final bool completed;
  final bool preview;
  final bool renderSharedObjects;
  final ValueChanged<MatchTaskConnection> onConnect;
  final VoidCallback onAllConnected;
  final VoidCallback? onWrongAttempt;

  @override
  State<MatchTaskBoard> createState() => _MatchTaskBoardState();
}

class _MatchTaskBoardState extends State<MatchTaskBoard>
    with TickerProviderStateMixin {
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
  late final AnimationController _lockedLineController;
  late final AnimationController _wrongLineController;

  @override
  void initState() {
    super.initState();
    _lockedLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
      value: widget.connections.isEmpty ? 0 : 1,
    )..addListener(_repaintLines);
    _wrongLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..addListener(_repaintLines);
    _ensureKeys();
  }

  void _repaintLines() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(MatchTaskBoard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.plan != widget.plan) {
      _ensureKeys();
      _completeNotified = false;
    }

    if (oldWidget.connections != widget.connections) {
      if (widget.connections.length > oldWidget.connections.length) {
        _lockedLineController.forward(from: 0);
      }
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
    _lockedLineController.dispose();
    _wrongLineController.dispose();
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
          lines.add((
            color: const Color(kDotsDigitAbacusLockedLineColor),
            line: _DrawLine(from: from, to: to),
          ));
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
          lines.add((
            color: const Color(kDotsDigitAbacusLockedLineColor),
            line: _DrawLine(from: from, to: to),
          ));
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
    _wrongLineController.forward(from: 0);
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
        widget.onWrongAttempt?.call();
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
        widget.onWrongAttempt?.call();
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
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
    final visibleDigitItems = widget.preview
        ? widget.plan.digitItems.where((item) => item.isTarget).toList()
        : widget.plan.digitItems;
    final visibleAbacusItems = widget.preview
        ? widget.plan.abacusItems.where((item) => item.isTarget).toList()
        : widget.plan.abacusItems;

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = computeMatchTaskBoardLayout(
          viewportWidth: constraints.maxWidth,
          viewportHeight: constraints.maxHeight,
          dotCount: widget.plan.dotsValue,
        );
        final hudSideInset = computeTrainerPlayHudSideInset(context);

        return AnimatedScale(
          scale: widget.completed && !reduceMotion ? 0.985 : 1,
          duration: Duration(milliseconds: reduceMotion ? 0 : 310),
          curve: Curves.easeOutCubic,
          child: Listener(
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
                              child: DecoratedBox(
                                decoration:
                                    _step == MatchTaskStep.dotsToDigit &&
                                        !widget.disabled
                                    ? BoxDecoration(
                                        borderRadius: BorderRadius.circular(28),
                                        border: Border.all(
                                          color: const Color(
                                            kDotsDigitAbacusDraftLineColor,
                                          ).withValues(alpha: 0.25),
                                          width: 2,
                                        ),
                                      )
                                    : const BoxDecoration(),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Listener(
                                    onPointerDown: _handleDotsPointerDown,
                                    onPointerUp: _handleDotsPointerUp,
                                    child: Opacity(
                                      opacity: widget.renderSharedObjects
                                          ? 1
                                          : 0,
                                      child: KeyedSubtree(
                                        key: _dotsKey,
                                        child: DotGroup(
                                          count: widget.plan.dotsValue,
                                          dotColor: const Color(
                                            kDotsDigitAbacusObjectColor,
                                          ),
                                          frameWidth: layout.dotFrameWidth,
                                          frameHeight: layout.dotFrameHeight,
                                          framed: false,
                                          materialChips: false,
                                          visibleCount: widget.plan.dotsValue,
                                        ),
                                      ),
                                    ),
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
                                  index < visibleDigitItems.length;
                                  index++
                                ) ...[
                                  if (index > 0)
                                    SizedBox(height: layout.rowGap),
                                  _buildDigitItem(
                                    item: visibleDigitItems[index],
                                    layout: layout,
                                    connected:
                                        connectedDigitId ==
                                        visibleDigitItems[index].id,
                                    shake:
                                        _wrongTargetId ==
                                        visibleDigitItems[index].id,
                                    entranceIndex: widget.plan.digitItems
                                        .indexOf(visibleDigitItems[index]),
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
                                  index < visibleAbacusItems.length;
                                  index++
                                ) ...[
                                  if (index > 0)
                                    SizedBox(height: layout.rowGap),
                                  _OptionEntrance(
                                    key: ValueKey(
                                      'abacus-option-${visibleAbacusItems[index].id}',
                                    ),
                                    animate:
                                        !visibleAbacusItems[index].isTarget,
                                    delayIndex: widget.plan.abacusItems.indexOf(
                                      visibleAbacusItems[index],
                                    ),
                                    child: Opacity(
                                      opacity:
                                          widget.renderSharedObjects ||
                                              !visibleAbacusItems[index]
                                                  .isTarget
                                          ? 1
                                          : 0,
                                      child: KeyedSubtree(
                                        key:
                                            _abacusKeys[visibleAbacusItems[index]
                                                .id],
                                        child: AbacusMatchCard(
                                          connected:
                                              connectedAbacusId ==
                                              visibleAbacusItems[index].id,
                                          height: layout.abacusHeight,
                                          shake:
                                              _wrongTargetId ==
                                              visibleAbacusItems[index].id,
                                          value:
                                              visibleAbacusItems[index].value,
                                          width: layout.abacusWidth,
                                        ),
                                      ),
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
                          activeDrawColor: const Color(
                            kDotsDigitAbacusDraftLineColor,
                          ),
                          lockedLines: lockedLines,
                          lockedProgress: reduceMotion
                              ? 1
                              : Curves.easeInOut.transform(
                                  _lockedLineController.value,
                                ),
                          wrongFlash: _wrongFlash,
                          wrongProgress: reduceMotion
                              ? 0.5
                              : _wrongLineController.value,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
    required int entranceIndex,
  }) {
    final canDrag =
        _step == MatchTaskStep.digitToAbacus &&
        item.id == widget.plan.targetDigitId &&
        !widget.disabled;

    final digit = _MatchDigitTarget(
      color: Color(item.displayColor),
      connected: connected,
      digit: item.value,
      fontSize: layout.digitFontSize,
      size: layout.digitSize,
      active: canDrag,
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

    final shaken = !shake || MediaQuery.disableAnimationsOf(context)
        ? wrapped
        : _ShakeDigit(active: shake, child: wrapped);
    final visible = Opacity(
      opacity: widget.renderSharedObjects || !item.isTarget ? 1 : 0,
      child: shaken,
    );
    return _OptionEntrance(
      key: ValueKey('digit-option-${item.id}'),
      animate: !item.isTarget,
      delayIndex: entranceIndex,
      child: visible,
    );
  }
}

class _OptionEntrance extends StatelessWidget {
  const _OptionEntrance({
    super.key,
    required this.animate,
    required this.child,
    required this.delayIndex,
  });

  final bool animate;
  final Widget child;
  final int delayIndex;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!animate || reduceMotion) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + delayIndex * 50),
      curve: Curves.easeOutBack,
      builder: (context, progress, child) => Opacity(
        opacity: progress.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - progress)),
          child: Transform.scale(scale: 0.92 + 0.08 * progress, child: child),
        ),
      ),
      child: child,
    );
  }
}

class _MatchDigitTarget extends StatelessWidget {
  const _MatchDigitTarget({
    required this.active,
    required this.color,
    required this.connected,
    required this.digit,
    required this.fontSize,
    required this.size,
  });

  final bool active;
  final Color color;
  final bool connected;
  final int digit;
  final double fontSize;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0x59F8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: connected
              ? const Color(kDotsDigitAbacusLockedLineColor)
              : active
              ? const Color(
                  kDotsDigitAbacusDraftLineColor,
                ).withValues(alpha: 0.45)
              : const Color(0xFFCBD5E1),
          width: connected || active ? 2 : 1,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: const Color(
                    kDotsDigitAbacusDraftLineColor,
                  ).withValues(alpha: 0.1),
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$digit',
          style: TextStyle(
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
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
    required this.lockedProgress,
    required this.activeDraw,
    required this.activeDrawColor,
    required this.wrongFlash,
    required this.wrongProgress,
  });

  final List<({Color color, _DrawLine line})> lockedLines;
  final double lockedProgress;
  final _ActiveDraw? activeDraw;
  final Color activeDrawColor;
  final _WrongFlash? wrongFlash;
  final double wrongProgress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final entry in lockedLines) {
      final endpoint = Offset.lerp(
        entry.line.from,
        entry.line.to,
        lockedProgress,
      )!;
      canvas.drawLine(
        entry.line.from,
        endpoint,
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
      final to = _wrongEndpoint(wrongFlash!, wrongProgress);
      canvas.drawLine(
        wrongFlash!.from,
        to,
        Paint()
          ..color = const Color(kDotsDigitAbacusWrongLineColor).withValues(
            alpha: wrongProgress > 0.76 ? (1 - wrongProgress) / 0.24 : 1,
          )
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  Offset _wrongEndpoint(_WrongFlash flash, double progress) {
    if (progress <= 0.42) {
      return Offset.lerp(flash.from, flash.to, progress / 0.42)!;
    }
    if (progress <= 0.76) {
      final phase = (progress - 0.42) / 0.34;
      final shake = math.sin(phase * math.pi * 4) * (1 - phase) * 9;
      return flash.to + Offset(shake, -shake * 0.45);
    }
    return Offset.lerp(flash.to, flash.from, (progress - 0.76) / 0.24)!;
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
        oldDelegate.lockedProgress != lockedProgress ||
        oldDelegate.activeDraw != activeDraw ||
        oldDelegate.activeDrawColor != activeDrawColor ||
        oldDelegate.wrongFlash != wrongFlash ||
        oldDelegate.wrongProgress != wrongProgress;
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
