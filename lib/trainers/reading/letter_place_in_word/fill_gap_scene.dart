import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/gap_word_row.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/place_in_word_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/place_in_word_sizes.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/word_card_with_gap.dart';
import 'package:larnes_mobile/trainers/shared/first_words/play_first_word_audio.dart';

const _popCurve = Cubic(0.34, 1.2, 0.64, 1);
const _poolTileSize = 56.0;

class _TaskFillState {
  const _TaskFillState({this.filledLetter});

  final String? filledLetter;
}

class _FillGapDragState {
  const _FillGapDragState({
    required this.tileId,
    required this.x,
    required this.y,
  });

  final String tileId;
  final double x;
  final double y;

  _FillGapDragState copyWith({double? x, double? y}) {
    return _FillGapDragState(tileId: tileId, x: x ?? this.x, y: y ?? this.y);
  }
}

/// Web: `platform/src/trainers/reading/letter-place-in-word/fill-gap-scene.tsx`
class FillGapScene extends StatefulWidget {
  const FillGapScene({
    super.key,
    this.disabled = false,
    required this.onComplete,
    required this.onCorrect,
    required this.onWrong,
    required this.poolTiles,
    required this.tasks,
  });

  final bool disabled;
  final VoidCallback onComplete;
  final ValueChanged<int> onCorrect;
  final ValueChanged<int> onWrong;
  final List<LetterPoolTile> poolTiles;
  final List<FillGapTask> tasks;

  @override
  State<FillGapScene> createState() => _FillGapSceneState();
}

class _FillGapSceneState extends State<FillGapScene> {
  final _sceneKey = GlobalKey();

  late List<GlobalKey> _slotKeys;
  late List<LetterPoolTile> _tiles;
  late List<_TaskFillState> _fills;

  _FillGapDragState? _dragState;
  var _dragMoved = false;
  Offset _dragStart = Offset.zero;

  String? _selectedTileId;
  int? _wrongSlotIndex;
  var _activeIndex = 0;
  var _isCompleted = false;
  var _isTrayRevealComplete = false;
  var _isInteractionReady = false;

  Timer? _trayRevealTimer;
  Timer? _interactionTimer;
  Timer? _wrongTimer;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _initFromProps();
    _scheduleTrayReveal();
  }

  @override
  void didUpdateWidget(FillGapScene oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.poolTiles, widget.poolTiles) ||
        !identical(oldWidget.tasks, widget.tasks)) {
      _resetFromProps();
    }
  }

  void _initFromProps() {
    _slotKeys = List.generate(widget.tasks.length, (_) => GlobalKey());
    _tiles = [...widget.poolTiles];
    _fills = List.generate(widget.tasks.length, (_) => const _TaskFillState());
  }

  void _resetFromProps() {
    _trayRevealTimer?.cancel();
    _interactionTimer?.cancel();
    _wrongTimer?.cancel();
    _completeTimer?.cancel();
    _initFromProps();
    _selectedTileId = null;
    _dragState = null;
    _dragMoved = false;
    _wrongSlotIndex = null;
    _activeIndex = 0;
    _isCompleted = false;
    _isTrayRevealComplete = false;
    _isInteractionReady = false;
    _scheduleTrayReveal();
  }

  bool get _isLocked => widget.disabled || _isCompleted || !_isInteractionReady;

  void _scheduleTrayReveal() {
    _trayRevealTimer?.cancel();
    _trayRevealTimer = Timer(
      Duration(milliseconds: getFruitRevealTotalMs(widget.tasks.length)),
      () {
        if (mounted) {
          setState(() => _isTrayRevealComplete = true);
          _scheduleInteractionReady();
        }
      },
    );
  }

  void _scheduleInteractionReady() {
    _interactionTimer?.cancel();
    _interactionTimer = Timer(
      Duration(milliseconds: getAnswerRevealTotalMs(_tiles.length)),
      () {
        if (mounted) {
          setState(() => _isInteractionReady = true);
        }
      },
    );
  }

  void _advanceAfterCorrect() {
    final completedWords = _activeIndex + 1;
    widget.onCorrect(completedWords);
    _completeTimer?.cancel();
    _completeTimer = Timer(
      const Duration(milliseconds: fillGapCompleteDelayMs),
      () {
        if (!mounted) {
          return;
        }
        if (completedWords < widget.tasks.length) {
          setState(() {
            _activeIndex = completedWords;
            _selectedTileId = null;
            _wrongSlotIndex = null;
          });
          return;
        }
        setState(() => _isCompleted = true);
        widget.onComplete();
      },
    );
  }

  bool _attemptPlace(String tileId, int targetIndex) {
    LetterPoolTile? tile;

    for (final item in _tiles) {
      if (item.id == tileId) {
        tile = item;
        break;
      }
    }

    if (tile == null || tile.used || _isLocked) {
      return false;
    }

    if (targetIndex != _activeIndex ||
        _fills[targetIndex].filledLetter != null) {
      return false;
    }

    final expected = widget.tasks[targetIndex].correctLetter;

    if (tile.letter != expected) {
      widget.onWrong(_activeIndex);
      setState(() => _wrongSlotIndex = targetIndex);
      _wrongTimer?.cancel();
      _wrongTimer = Timer(
        const Duration(milliseconds: fillGapWrongFeedbackMs),
        () {
          if (mounted) {
            setState(() {
              if (_wrongSlotIndex == targetIndex) {
                _wrongSlotIndex = null;
              }
            });
          }
        },
      );
      return false;
    }

    final nextFills = [
      for (var index = 0; index < _fills.length; index++)
        index == targetIndex
            ? _TaskFillState(filledLetter: tile.letter)
            : _fills[index],
    ];

    setState(() {
      _fills = nextFills;
      _tiles = [
        for (final item in _tiles)
          item.id == tileId ? item.copyWith(used: true) : item,
      ];
      if (_selectedTileId == tileId) {
        _selectedTileId = null;
      }
    });

    _advanceAfterCorrect();
    return true;
  }

  int? _findSlotIndexAtPoint(Offset global) {
    for (var index = 0; index < _slotKeys.length; index++) {
      final context = _slotKeys[index].currentContext;

      if (context == null) {
        continue;
      }

      final box = context.findRenderObject() as RenderBox?;

      if (box == null) {
        continue;
      }

      final topLeft = box.localToGlobal(Offset.zero);
      final rect = Rect.fromLTWH(
        topLeft.dx,
        topLeft.dy,
        box.size.width,
        box.size.height,
      );

      if (rect.contains(global)) {
        return index;
      }
    }

    return null;
  }

  void _handleTileTap(String tileId) {
    if (_isLocked || _dragMoved || _dragState != null) {
      _dragMoved = false;
      return;
    }

    LetterPoolTile? tile;

    for (final item in _tiles) {
      if (item.id == tileId) {
        tile = item;
        break;
      }
    }

    if (tile == null || tile.used) {
      return;
    }

    setState(() {
      _selectedTileId = _selectedTileId == tileId ? null : tileId;
    });
  }

  void _handleSlotTap(int slotIndex) {
    if (_selectedTileId == null || _isLocked) {
      return;
    }

    _attemptPlace(_selectedTileId!, slotIndex);
  }

  void _handlePointerDown(PointerDownEvent event, String tileId) {
    LetterPoolTile? tile;

    for (final item in _tiles) {
      if (item.id == tileId) {
        tile = item;
        break;
      }
    }

    if (tile == null || tile.used || _isLocked || _dragState != null) {
      return;
    }

    _dragMoved = false;
    _dragStart = event.position;

    setState(() {
      _dragState = _FillGapDragState(
        tileId: tileId,
        x: event.position.dx,
        y: event.position.dy,
      );
    });
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_dragState == null || _isLocked) {
      return;
    }

    if (_hasDragMovedBeyondClickThreshold(_dragStart, event.position)) {
      _dragMoved = true;
    }

    setState(() {
      _dragState = _dragState!.copyWith(
        x: event.position.dx,
        y: event.position.dy,
      );
    });
  }

  void _handlePointerEnd(PointerEvent event) {
    final dragState = _dragState;

    if (dragState == null) {
      return;
    }

    final slotIndex = _findSlotIndexAtPoint(event.position);

    if (slotIndex != null) {
      _attemptPlace(dragState.tileId, slotIndex);
    }

    setState(() => _dragState = null);
  }

  bool _hasDragMovedBeyondClickThreshold(Offset start, Offset current) {
    final dx = current.dx - start.dx;
    final dy = current.dy - start.dy;
    return math.sqrt(dx * dx + dy * dy) > fillGapDragClickThresholdPx;
  }

  Offset? _dragGhostLocalPosition() {
    final dragState = _dragState;
    final sceneContext = _sceneKey.currentContext;

    if (dragState == null || sceneContext == null) {
      return null;
    }

    final box = sceneContext.findRenderObject() as RenderBox?;
    if (box == null) {
      return null;
    }

    final local = box.globalToLocal(Offset(dragState.x, dragState.y));

    return Offset(local.dx - _poolTileSize / 2, local.dy - _poolTileSize / 2);
  }

  LetterPoolTile? get _activeDragTile {
    final dragState = _dragState;
    if (dragState == null) {
      return null;
    }

    for (final tile in _tiles) {
      if (tile.id == dragState.tileId) {
        return tile;
      }
    }

    return null;
  }

  @override
  void dispose() {
    _trayRevealTimer?.cancel();
    _interactionTimer?.cancel();
    _wrongTimer?.cancel();
    _completeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dragGhostPosition = _dragGhostLocalPosition();
    final activeTile = _activeDragTile;
    final task = widget.tasks[_activeIndex];
    final fill = _fills[_activeIndex];
    final availableTiles = _tiles.where((tile) => !tile.used).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          key: _sceneKey,
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                if (widget.tasks.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        for (
                          var index = 0;
                          index < widget.tasks.length;
                          index++
                        )
                          Expanded(
                            child: Container(
                              height: 6,
                              margin: EdgeInsets.only(
                                right: index == widget.tasks.length - 1 ? 0 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: index <= _activeIndex
                                    ? const Color(0xFF2F7D59)
                                    : const Color(0x292F7D59),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            WordCardWithGap(
                              displayWord: task.displayWord,
                              enterDelayMs: getFruitRevealDelayMs(0, 1),
                              onPlay: () =>
                                  unawaited(playFirstWordAudio(task.slug)),
                              slug: task.slug,
                              success: fill.filledLetter != null,
                            ),
                            const SizedBox(height: 8),
                            GapWordRow(
                              after: task.after,
                              before: task.before,
                              filledLetter: fill.filledLetter,
                              isAwaitingPlacement:
                                  _selectedTileId != null &&
                                  fill.filledLetter == null,
                              onSlotClick: () => _handleSlotTap(_activeIndex),
                              slotKey: _slotKeys[_activeIndex],
                              wrongFlash: _wrongSlotIndex == _activeIndex,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isTrayRevealComplete)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (
                          var index = 0;
                          index < availableTiles.length;
                          index++
                        )
                          _FillGapPoolTile(
                            isDragging:
                                _dragState?.tileId == availableTiles[index].id,
                            isLocked: _isLocked,
                            isSelected:
                                _selectedTileId == availableTiles[index].id,
                            onPointerCancel: _handlePointerEnd,
                            onPointerDown: (event) => _handlePointerDown(
                              event,
                              availableTiles[index].id,
                            ),
                            onPointerMove: _handlePointerMove,
                            onPointerUp: _handlePointerEnd,
                            onTap: () =>
                                _handleTileTap(availableTiles[index].id),
                            revealDelayMs: getAnswerRevealDelayMs(
                              index,
                              availableTiles.length,
                            ),
                            tile: availableTiles[index],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            if (dragGhostPosition != null && activeTile != null)
              Positioned(
                left: dragGhostPosition.dx,
                top: dragGhostPosition.dy,
                child: IgnorePointer(
                  child: _FillGapPoolTileVisual(
                    isSelected: false,
                    letter: activeTile.letter,
                    opacity: 1,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FillGapPoolTile extends StatefulWidget {
  const _FillGapPoolTile({
    required this.isDragging,
    required this.isLocked,
    required this.isSelected,
    required this.onPointerCancel,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
    required this.onTap,
    required this.revealDelayMs,
    required this.tile,
  });

  final bool isDragging;
  final bool isLocked;
  final bool isSelected;
  final ValueChanged<PointerEvent> onPointerCancel;
  final ValueChanged<PointerDownEvent> onPointerDown;
  final ValueChanged<PointerMoveEvent> onPointerMove;
  final ValueChanged<PointerEvent> onPointerUp;
  final VoidCallback onTap;
  final int revealDelayMs;
  final LetterPoolTile tile;

  @override
  State<_FillGapPoolTile> createState() => _FillGapPoolTileState();
}

class _FillGapPoolTileState extends State<_FillGapPoolTile>
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
    _progress = CurvedAnimation(parent: _controller, curve: _popCurve);
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
    final opacity = widget.tile.used
        ? 0.3
        : widget.isDragging
        ? 0.35
        : 1.0;

    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final t = _progress.value.clamp(0.0, 1.0);

        return Opacity(
          opacity: t * opacity,
          child: Transform.scale(
            scale: (0.88 + 0.12 * t) * (widget.isSelected ? 1.06 : 1),
            child: child,
          ),
        );
      },
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: widget.tile.used || widget.isLocked
            ? null
            : widget.onPointerDown,
        onPointerMove: widget.tile.used || widget.isLocked
            ? null
            : widget.onPointerMove,
        onPointerUp: widget.tile.used || widget.isLocked
            ? null
            : widget.onPointerUp,
        onPointerCancel: widget.tile.used || widget.isLocked
            ? null
            : widget.onPointerCancel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.tile.used || widget.isLocked ? null : widget.onTap,
            borderRadius: BorderRadius.circular(18),
            child: _FillGapPoolTileVisual(
              isSelected: widget.isSelected,
              letter: widget.tile.letter,
              opacity: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _FillGapPoolTileVisual extends StatelessWidget {
  const _FillGapPoolTileVisual({
    required this.isSelected,
    required this.letter,
    required this.opacity,
  });

  final bool isSelected;
  final String letter;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _poolTileSize,
      height: _poolTileSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7).withValues(alpha: 0.95 * opacity),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? const Color(0xFF2F7D59) : const Color(0x24274F3C),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF234C38).withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        letter,
        style: GoogleFonts.onest(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF20352D),
        ),
      ),
    );
  }
}
