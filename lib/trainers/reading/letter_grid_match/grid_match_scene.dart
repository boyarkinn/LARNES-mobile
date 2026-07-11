import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_field_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_grid_match/grid_match_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_grid_match/grid_match_panel.dart';
import 'package:larnes_mobile/trainers/reading/letter_grid_match/grid_match_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_grid_match/grid_match_size.dart';
import 'package:larnes_mobile/trainers/shared/trainer_timings.dart';

const _popCurve = Cubic(0.34, 1.2, 0.64, 1);
const _dragClickThresholdPx = 8.0;
const _poolTileSize = 56.0;

/// Web: `platform/src/trainers/reading/letter-grid-match/grid-match-scene.tsx`
class GridMatchScene extends StatefulWidget {
  const GridMatchScene({
    super.key,
    required this.round,
    required this.tileColors,
    required this.onComplete,
    this.disabled = false,
  });

  final GridRound round;
  final Map<String, String> tileColors;
  final VoidCallback onComplete;
  final bool disabled;

  @override
  State<GridMatchScene> createState() => _GridMatchSceneState();
}

class _GridMatchSceneState extends State<GridMatchScene> {
  final _sceneKey = GlobalKey();
  late List<GlobalKey> _slotKeys;
  late List<GridPoolTile> _tiles;
  late Map<String, String?> _targetCells;
  late Map<String, String?> _targetColors;

  _GridDragState? _dragState;
  var _dragMoved = false;
  Offset _dragStart = Offset.zero;

  String? _selectedTileId;
  String? _wrongCellId;
  var _isCompleted = false;
  var _isPoolRevealStarted = false;
  var _isInteractionReady = false;

  Timer? _poolRevealTimer;
  Timer? _interactionTimer;
  Timer? _wrongTimer;
  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _initFromRound();
    _scheduleReveal();
  }

  @override
  void didUpdateWidget(GridMatchScene oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.round, widget.round)) {
      _resetFromRound();
    }
  }

  void _initFromRound() {
    _slotKeys = List.generate(widget.round.cells.length, (_) => GlobalKey());
    _tiles = [...widget.round.poolTiles];
    _targetCells = {
      for (final cell in widget.round.cells) cell.id: null,
    };
    _targetColors = {
      for (final cell in widget.round.cells) cell.id: null,
    };
  }

  void _resetFromRound() {
    _poolRevealTimer?.cancel();
    _interactionTimer?.cancel();
    _wrongTimer?.cancel();
    _completeTimer?.cancel();
    _initFromRound();
    _selectedTileId = null;
    _dragState = null;
    _dragMoved = false;
    _wrongCellId = null;
    _isCompleted = false;
    _isPoolRevealStarted = false;
    _isInteractionReady = false;
    _scheduleReveal();
  }

  int get _filledCount =>
      widget.round.reference.values.where((letter) => letter != null).length;

  bool get _isLocked =>
      widget.disabled || _isCompleted || !_isInteractionReady;

  void _scheduleReveal() {
    _poolRevealTimer?.cancel();
    _poolRevealTimer = Timer(
      Duration(milliseconds: getPoolRevealStartMs(_filledCount)),
      () {
        if (mounted) {
          setState(() => _isPoolRevealStarted = true);
          _scheduleInteractionReady();
        }
      },
    );
  }

  void _scheduleInteractionReady() {
    _interactionTimer?.cancel();
    final readyMs = getGridMatchInteractionReadyMs(_filledCount, _tiles.length);
    final poolStartMs = getPoolRevealStartMs(_filledCount);

    _interactionTimer = Timer(
      Duration(milliseconds: readyMs - poolStartMs),
      () {
        if (mounted) {
          setState(() => _isInteractionReady = true);
        }
      },
    );
  }

  void _tryComplete(Map<String, String?> nextTarget) {
    if (isGridMatch(widget.round.reference, nextTarget)) {
      setState(() => _isCompleted = true);
      _completeTimer = Timer(
        const Duration(milliseconds: TrainerTimings.completeDelayMs),
        () {
          if (mounted) {
            widget.onComplete();
          }
        },
      );
    }
  }

  bool _attemptPlace(String tileId, String cellId) {
    GridPoolTile? tile;

    for (final item in _tiles) {
      if (item.id == tileId) {
        tile = item;
        break;
      }
    }

    if (tile == null || tile.used || _isLocked) {
      return false;
    }

    if (_targetCells[cellId] != null) {
      return false;
    }

    final expectedLetter = widget.round.reference[cellId];

    if (expectedLetter == null || tile.letter != expectedLetter) {
      setState(() => _wrongCellId = cellId);
      _wrongTimer?.cancel();
      _wrongTimer = Timer(
        const Duration(milliseconds: TrainerTimings.wrongFeedbackMs),
        () {
          if (mounted) {
            setState(() {
              if (_wrongCellId == cellId) {
                _wrongCellId = null;
              }
            });
          }
        },
      );
      return false;
    }

    final tileColor = widget.tileColors[tileId] ?? '#1F2937';
    final nextTarget = Map<String, String?>.from(_targetCells)
      ..[cellId] = tile.letter;
    final nextColors = Map<String, String?>.from(_targetColors)
      ..[cellId] = tileColor;

    setState(() {
      _targetCells = nextTarget;
      _targetColors = nextColors;
      _tiles = [
        for (final item in _tiles)
          item.id == tileId ? item.copyWith(used: true) : item,
      ];
      if (_selectedTileId == tileId) {
        _selectedTileId = null;
      }
    });

    _tryComplete(nextTarget);
    return true;
  }

  String? _findCellIdAtPoint(Offset global) {
    for (var index = 0; index < _slotKeys.length; index++) {
      final context = _slotKeys[index].currentContext;

      if (context == null) {
        continue;
      }

      final box = context.findRenderObject() as RenderBox?;
      final cell = widget.round.cells[index];

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
        return cell.id;
      }
    }

    return null;
  }

  void _handleTileTap(String tileId) {
    if (_isLocked || _dragMoved || _dragState != null) {
      _dragMoved = false;
      return;
    }

    GridPoolTile? tile;

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

  void _handleCellTap(String cellId) {
    if (_selectedTileId == null || _isLocked) {
      return;
    }

    _attemptPlace(_selectedTileId!, cellId);
  }

  void _handlePointerDown(PointerDownEvent event, String tileId) {
    GridPoolTile? tile;

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
      _dragState = _GridDragState(
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

    final cellId = _findCellIdAtPoint(event.position);

    if (cellId != null) {
      _attemptPlace(dragState.tileId, cellId);
    }

    setState(() => _dragState = null);
  }

  bool _hasDragMovedBeyondClickThreshold(Offset start, Offset current) {
    final dx = current.dx - start.dx;
    final dy = current.dy - start.dy;
    return math.sqrt(dx * dx + dy * dy) > _dragClickThresholdPx;
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

  GridPoolTile? get _activeDragTile {
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
    _poolRevealTimer?.cancel();
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
        final panelSize = gridPanelSize(constraints.maxHeight, constraints.maxWidth);
        final useRowLayout = constraints.maxWidth >= panelSize * 2 + 48;

        return Stack(
          key: _sceneKey,
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      child: Flex(
                        direction: useRowLayout ? Axis.horizontal : Axis.vertical,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GridMatchPanel(
                            cells: widget.round.cells,
                            filledCells: widget.round.reference,
                            filledCount: _filledCount,
                            gridSize: widget.round.gridSize,
                            mode: GridMatchPanelMode.reference,
                            panelSize: panelSize,
                          ),
                          SizedBox(
                            width: useRowLayout ? 24 : 0,
                            height: useRowLayout ? 0 : 16,
                          ),
                          GridMatchPanel(
                            cells: widget.round.cells,
                            filledCells: _targetCells,
                            filledCount: _filledCount,
                            gridSize: widget.round.gridSize,
                            mode: GridMatchPanelMode.target,
                            panelSize: panelSize,
                            cellColors: _targetColors,
                            isAwaitingPlacement: _selectedTileId != null,
                            onCellClick: _handleCellTap,
                            slotKeys: _slotKeys,
                            wrongCellId: _wrongCellId,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isPoolRevealStarted)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var index = 0; index < _tiles.length; index++)
                          _GridPoolTile(
                            tile: _tiles[index],
                            color: letterDisplayColorFromHex(
                              widget.tileColors[_tiles[index].id],
                            ),
                            isSelected: _selectedTileId == _tiles[index].id,
                            isDragging: _dragState?.tileId == _tiles[index].id,
                            isLocked: _isLocked,
                            revealDelayMs: getAnswerRevealDelayMs(
                              index,
                              _tiles.length,
                            ),
                            onTap: () => _handleTileTap(_tiles[index].id),
                            onPointerDown: (event) =>
                                _handlePointerDown(event, _tiles[index].id),
                            onPointerMove: _handlePointerMove,
                            onPointerUp: _handlePointerEnd,
                            onPointerCancel: _handlePointerEnd,
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
                  child: _GridPoolTileVisual(
                    letter: activeTile.letter,
                    color: activeColor,
                    opacity: 1,
                    isSelected: false,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GridDragState {
  const _GridDragState({
    required this.tileId,
    required this.x,
    required this.y,
  });

  final String tileId;
  final double x;
  final double y;

  _GridDragState copyWith({
    double? x,
    double? y,
  }) {
    return _GridDragState(
      tileId: tileId,
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }
}

class _GridPoolTile extends StatefulWidget {
  const _GridPoolTile({
    required this.tile,
    required this.color,
    required this.isSelected,
    required this.isDragging,
    required this.isLocked,
    required this.revealDelayMs,
    required this.onTap,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerUp,
    required this.onPointerCancel,
  });

  final GridPoolTile tile;
  final Color color;
  final bool isSelected;
  final bool isDragging;
  final bool isLocked;
  final int revealDelayMs;
  final VoidCallback onTap;
  final ValueChanged<PointerDownEvent> onPointerDown;
  final ValueChanged<PointerMoveEvent> onPointerMove;
  final ValueChanged<PointerEvent> onPointerUp;
  final ValueChanged<PointerEvent> onPointerCancel;

  @override
  State<_GridPoolTile> createState() => _GridPoolTileState();
}

class _GridPoolTileState extends State<_GridPoolTile>
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
            child: _GridPoolTileVisual(
              letter: widget.tile.letter,
              color: widget.color,
              opacity: 1,
              isSelected: widget.isSelected,
            ),
          ),
        ),
      ),
    );
  }
}

class _GridPoolTileVisual extends StatelessWidget {
  const _GridPoolTileVisual({
    required this.letter,
    required this.color,
    required this.opacity,
    required this.isSelected,
  });

  final String letter;
  final Color color;
  final double opacity;
  final bool isSelected;

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
