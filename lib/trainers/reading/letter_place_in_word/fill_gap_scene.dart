import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_field_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/gap_word_row.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/place_in_word_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/place_in_word_sizes.dart';
import 'package:larnes_mobile/trainers/reading/letter_place_in_word/word_card_with_gap.dart';

const _popCurve = Cubic(0.34, 1.2, 0.64, 1);
const _poolTileSize = 56.0;

class _TaskFillState {
  const _TaskFillState({
    this.filledColor,
    this.filledLetter,
  });

  final Color? filledColor;
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

  _FillGapDragState copyWith({
    double? x,
    double? y,
  }) {
    return _FillGapDragState(
      tileId: tileId,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}

/// Web: `platform/src/trainers/reading/letter-place-in-word/fill-gap-scene.tsx`
class FillGapScene extends StatefulWidget {
  const FillGapScene({
    super.key,
    this.disabled = false,
    required this.onComplete,
    required this.poolTiles,
    required this.tasks,
    required this.tileColors,
  });

  final bool disabled;
  final VoidCallback onComplete;
  final List<LetterPoolTile> poolTiles;
  final List<FillGapTask> tasks;
  final Map<String, String> tileColors;

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
    _isCompleted = false;
    _isTrayRevealComplete = false;
    _isInteractionReady = false;
    _scheduleTrayReveal();
  }

  bool get _isLocked =>
      widget.disabled || _isCompleted || !_isInteractionReady;

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

  void _tryComplete(List<_TaskFillState> nextFills) {
    if (nextFills.every((fill) => fill.filledLetter != null)) {
      setState(() => _isCompleted = true);
      _completeTimer = Timer(
        const Duration(milliseconds: fillGapCompleteDelayMs),
        () {
          if (mounted) {
            widget.onComplete();
          }
        },
      );
    }
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

    if (_fills[targetIndex].filledLetter != null) {
      return false;
    }

    final expected = widget.tasks[targetIndex].correctLetter;

    if (tile.letter != expected) {
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

    final tileColorHex = widget.tileColors[tileId] ?? '#1F2937';
    final tileColor = letterDisplayColorFromHex(tileColorHex);
    final nextFills = [
      for (var index = 0; index < _fills.length; index++)
        index == targetIndex
            ? _TaskFillState(
                filledColor: tileColor,
                filledLetter: tile.letter,
              )
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

    _tryComplete(nextFills);
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

    return Offset(
      local.dx - _poolTileSize / 2,
      local.dy - _poolTileSize / 2,
    );
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

  int _gridCrossAxisCount(double width) {
    if (widget.tasks.length == 1) {
      return 1;
    }

    if (widget.tasks.length == 2) {
      return width >= 640 ? 2 : 1;
    }

    if (width >= 1024) {
      return 3;
    }

    if (width >= 640) {
      return 2;
    }

    return 1;
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
    final activeColor = activeTile == null
        ? const Color(0xFF1F2937)
        : letterDisplayColorFromHex(widget.tileColors[activeTile.id]);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _gridCrossAxisCount(constraints.maxWidth);

        return Stack(
          key: _sceneKey,
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 896),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.95,
                          ),
                          itemCount: widget.tasks.length,
                          itemBuilder: (context, index) {
                            final task = widget.tasks[index];
                            final fill = _fills[index];

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                WordCardWithGap(
                                  displayWord: task.displayWord,
                                  enterDelayMs: getFruitRevealDelayMs(
                                    index,
                                    widget.tasks.length,
                                  ),
                                  slug: task.slug,
                                ),
                                const SizedBox(height: 12),
                                GapWordRow(
                                  after: task.after,
                                  before: task.before,
                                  filledColor: fill.filledColor,
                                  filledLetter: fill.filledLetter,
                                  isAwaitingPlacement: _selectedTileId != null &&
                                      fill.filledLetter == null,
                                  onSlotClick: () => _handleSlotTap(index),
                                  slotKey: _slotKeys[index],
                                  wrongFlash: _wrongSlotIndex == index,
                                ),
                              ],
                            );
                          },
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
                        for (var index = 0; index < _tiles.length; index++)
                          _FillGapPoolTile(
                            color: letterDisplayColorFromHex(
                              widget.tileColors[_tiles[index].id],
                            ),
                            isDragging: _dragState?.tileId == _tiles[index].id,
                            isLocked: _isLocked,
                            isSelected: _selectedTileId == _tiles[index].id,
                            onPointerCancel: _handlePointerEnd,
                            onPointerDown: (event) =>
                                _handlePointerDown(event, _tiles[index].id),
                            onPointerMove: _handlePointerMove,
                            onPointerUp: _handlePointerEnd,
                            onTap: () => _handleTileTap(_tiles[index].id),
                            revealDelayMs: getAnswerRevealDelayMs(
                              index,
                              _tiles.length,
                            ),
                            tile: _tiles[index],
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
                    color: activeColor,
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
    required this.color,
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

  final Color color;
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
            borderRadius: BorderRadius.circular(16),
            child: _FillGapPoolTileVisual(
              color: widget.color,
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
    required this.color,
    required this.isSelected,
    required this.letter,
    required this.opacity,
  });

  final Color color;
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
        color: Colors.white.withValues(alpha: 0.95 * opacity),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? ParentColors.shell : const Color(0xFFE5E7EB),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        letter,
        style: GoogleFonts.onest(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
