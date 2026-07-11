import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/trainers/math/fruit_count_tap/fruit_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_find_tap/letter_field_scene.dart';
import 'package:larnes_mobile/trainers/reading/letter_grid_match/grid_match_model.dart';
import 'package:larnes_mobile/trainers/reading/letter_grid_match/grid_match_reveal.dart';
import 'package:larnes_mobile/trainers/reading/letter_grid_match/grid_match_size.dart';

enum GridMatchPanelMode { reference, target }

const _popCurve = Cubic(0.34, 1.2, 0.64, 1);
const _emptySlotColor = Color(0xFFCBD5E1);
const _referenceLetterColor = Color(0xFF475569);

/// Web: `platform/src/trainers/reading/letter-grid-match/grid-match-panel.tsx`
class GridMatchPanel extends StatelessWidget {
  const GridMatchPanel({
    super.key,
    required this.cells,
    required this.filledCells,
    required this.filledCount,
    required this.gridSize,
    required this.mode,
    required this.panelSize,
    this.cellColors = const {},
    this.isAwaitingPlacement = false,
    this.onCellClick,
    this.slotKeys,
    this.wrongCellId,
  });

  final List<GridCell> cells;
  final Map<String, String?> filledCells;
  final int filledCount;
  final int gridSize;
  final GridMatchPanelMode mode;
  final double panelSize;
  final Map<String, String?> cellColors;
  final bool isAwaitingPlacement;
  final ValueChanged<String>? onCellClick;
  final List<GlobalKey>? slotKeys;
  final String? wrongCellId;

  @override
  Widget build(BuildContext context) {
    var filledRevealIndex = 0;
    final fontSize = getGridCellFontSize(gridSize);

    final grid = GridView.count(
      crossAxisCount: gridSize,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: [
        for (var index = 0; index < cells.length; index++)
          _GridMatchCell(
            key: slotKeys?[index],
            cell: cells[index],
            letter: filledCells[cells[index].id],
            mode: mode,
            fontSize: fontSize,
            letterColor: cellColors[cells[index].id] != null
                ? letterDisplayColorFromHex(cellColors[cells[index].id])
                : _referenceLetterColor,
            isAwaitingPlacement: isAwaitingPlacement,
            isWrong: wrongCellId == cells[index].id,
            revealDelayMs: mode == GridMatchPanelMode.reference &&
                    filledCells[cells[index].id] != null
                ? getReferenceRevealDelayMs(
                    filledRevealIndex++,
                    filledCount,
                  )
                : 0,
            onTap: onCellClick == null
                ? null
                : () => onCellClick!(cells[index].id),
          ),
      ],
    );

    final panel = Container(
      width: panelSize,
      height: panelSize,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB).withValues(alpha: 0.8)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 23, 42, 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: grid,
    );

    if (mode == GridMatchPanelMode.target) {
      return _GridMatchTargetPanelReveal(
        delayMs: getTargetGridRevealStartMs(filledCount),
        child: panel,
      );
    }

    return panel;
  }
}

class _GridMatchTargetPanelReveal extends StatefulWidget {
  const _GridMatchTargetPanelReveal({
    required this.delayMs,
    required this.child,
  });

  final int delayMs;
  final Widget child;

  @override
  State<_GridMatchTargetPanelReveal> createState() =>
      _GridMatchTargetPanelRevealState();
}

class _GridMatchTargetPanelRevealState extends State<_GridMatchTargetPanelReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: targetGridPopMs),
    );
    _progress = CurvedAnimation(parent: _controller, curve: _popCurve);
    _delayTimer = Timer(Duration(milliseconds: widget.delayMs), () {
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
            scale: 0.94 + 0.06 * t,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _GridMatchCell extends StatefulWidget {
  const _GridMatchCell({
    super.key,
    required this.cell,
    required this.letter,
    required this.mode,
    required this.fontSize,
    required this.letterColor,
    required this.isAwaitingPlacement,
    required this.isWrong,
    required this.revealDelayMs,
    this.onTap,
  });

  final GridCell cell;
  final String? letter;
  final GridMatchPanelMode mode;
  final double fontSize;
  final Color letterColor;
  final bool isAwaitingPlacement;
  final bool isWrong;
  final int revealDelayMs;
  final VoidCallback? onTap;

  @override
  State<_GridMatchCell> createState() => _GridMatchCellState();
}

class _GridMatchCellState extends State<_GridMatchCell>
    with SingleTickerProviderStateMixin {
  AnimationController? _revealController;
  AnimationController? _shakeController;
  Animation<double>? _revealProgress;
  Animation<double>? _shakeOffset;
  Timer? _revealDelayTimer;

  @override
  void initState() {
    super.initState();
    _setupReveal();
    _setupShake();
  }

  @override
  void didUpdateWidget(_GridMatchCell oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isWrong != widget.isWrong && widget.isWrong) {
      _shakeController?.forward(from: 0);
    }
  }

  void _setupReveal() {
    final shouldReveal = widget.mode == GridMatchPanelMode.reference &&
        widget.letter != null;

    if (!shouldReveal) {
      return;
    }

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: kFruitPopDurationMs),
    );
    _revealProgress = CurvedAnimation(
      parent: _revealController!,
      curve: _popCurve,
    );
    _revealDelayTimer = Timer(Duration(milliseconds: widget.revealDelayMs), () {
      if (mounted) {
        _revealController?.forward();
      }
    });
  }

  void _setupShake() {
    if (widget.mode != GridMatchPanelMode.target) {
      return;
    }

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: -5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeController!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _revealDelayTimer?.cancel();
    _revealController?.dispose();
    _shakeController?.dispose();
    super.dispose();
  }

  BoxDecoration _decoration() {
    if (widget.mode == GridMatchPanelMode.reference) {
      if (widget.letter != null) {
        return BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB).withValues(alpha: 0.7)),
        );
      }

      return BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      );
    }

    if (widget.letter != null) {
      return BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB).withValues(alpha: 0.8),
          width: 2,
        ),
      );
    }

    if (widget.isWrong) {
      return BoxDecoration(
        color: const Color(0xFFFEF2F2).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF87171), width: 2, strokeAlign: BorderSide.strokeAlignInside),
      );
    }

    if (widget.isAwaitingPlacement) {
      return BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ParentColors.shell, width: 2, strokeAlign: BorderSide.strokeAlignInside),
      );
    }

    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _emptySlotColor, width: 2, strokeAlign: BorderSide.strokeAlignInside),
    );
  }

  Widget _content() {
    if (widget.mode == GridMatchPanelMode.target && widget.letter == null) {
      return Container(
        width: widget.fontSize * 0.36,
        height: widget.fontSize * 0.12,
        decoration: BoxDecoration(
          color: _emptySlotColor,
          borderRadius: BorderRadius.circular(999),
        ),
      );
    }

    if (widget.letter == null) {
      return const SizedBox.shrink();
    }

    return Text(
      widget.letter!,
      style: GoogleFonts.onest(
        fontSize: widget.fontSize,
        fontWeight: FontWeight.w700,
        color: widget.mode == GridMatchPanelMode.target
            ? widget.letterColor
            : _referenceLetterColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget cell = DecoratedBox(
      decoration: _decoration(),
      child: Center(child: _content()),
    );

    if (_revealController != null && _revealProgress != null) {
      cell = AnimatedBuilder(
        animation: _revealProgress!,
        builder: (context, child) {
          final t = _revealProgress!.value.clamp(0.0, 1.0);

          return Opacity(
            opacity: t,
            child: Transform.scale(
              scale: 0.88 + 0.12 * t,
              child: child,
            ),
          );
        },
        child: cell,
      );
    }

    if (_shakeController != null && _shakeOffset != null) {
      cell = AnimatedBuilder(
        animation: _shakeController!,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeOffset!.value, 0),
            child: child,
          );
        },
        child: cell,
      );
    }

    if (widget.onTap != null && widget.letter == null) {
      cell = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: cell,
        ),
      );
    }

    return cell;
  }
}
