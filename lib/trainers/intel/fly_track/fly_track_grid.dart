import 'package:flutter/material.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/fly_glyph.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/fly_track_phase.dart';
import 'package:larnes_mobile/trainers/intel/fly_track/model.dart';
import 'package:larnes_mobile/trainers/mental_arithmetic/topic_chain_flash/answer_fireworks.dart';

/// Web: `FlyTrackGrid` in `platform/src/trainers/intel/fly-track/component.tsx`
class FlyTrackGrid extends StatefulWidget {
  const FlyTrackGrid({
    super.key,
    required this.fireworksKey,
    required this.gridSize,
    required this.onCellSelect,
    required this.phase,
    required this.replayPathIndex,
    required this.round,
    required this.selectedCell,
    required this.flyOpacity,
    required this.visibleCell,
    required this.visiblePosition,
  });

  final int fireworksKey;
  final int gridSize;
  final ValueChanged<FlyCell> onCellSelect;
  final FlyTrackPhase phase;
  final int replayPathIndex;
  final FlyTrackRound round;
  final FlyCell? selectedCell;
  final double flyOpacity;
  final FlyCell? visibleCell;
  final Offset? visiblePosition;

  @override
  State<FlyTrackGrid> createState() => _FlyTrackGridState();
}

class _FlyTrackGridState extends State<FlyTrackGrid> {
  static const _cellBg = Color(0xF2FFF8E7);
  static const _cellBorder = Color(0x73F2B84B);
  static const _answerBorder = Color(0xD9F2B84B);
  static const _answerBg = Color(0xFFFFF8E7);
  static const _wrongBorder = Color(0xFFF43F5E);
  static const _wrongBg = Color(0xFFFFF1F2);
  static const _correctBorder = Color(0xFF10B981);
  static const _correctBg = Color(0xFFECFDF5);

  bool get _canAnswer => widget.phase == FlyTrackPhase.answer;

  bool get _isFeedback => widget.phase == FlyTrackPhase.feedback;

  bool get _isCorrect => _sameCell(widget.selectedCell, widget.round.finish);

  @override
  Widget build(BuildContext context) {
    return AnswerFireworksBurst(
      burstKey: widget.fireworksKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = [
            constraints.maxWidth,
            constraints.maxHeight,
          ].reduce((a, b) => a < b ? a : b).clamp(0.0, 540.0);

          return Align(
            alignment: Alignment.center,
            child: SizedBox(
              key: const Key('fly-track-grid-field'),
              width: side,
              height: side,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _canAnswer
                      ? const Color(0x24173B73)
                      : const Color(0x1A173B73),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _canAnswer
                        ? const Color(0xB3F2B84B)
                        : const Color(0x40173B73),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _canAnswer
                          ? const Color(0x33295CB2)
                          : const Color(0x2B173B73),
                      blurRadius: _canAnswer ? 55 : 50,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _FlyTrackGridCells(
                    gridSize: widget.gridSize,
                    canAnswer: _canAnswer,
                    isFeedback: _isFeedback,
                    isCorrect: _isCorrect,
                    phase: widget.phase,
                    replayPathIndex: widget.replayPathIndex,
                    round: widget.round,
                    selectedCell: widget.selectedCell,
                    flyOpacity: widget.flyOpacity,
                    visibleCell: widget.visibleCell,
                    visiblePosition: widget.visiblePosition,
                    onCellSelect: widget.onCellSelect,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FlyTrackGridCells extends StatelessWidget {
  const _FlyTrackGridCells({
    required this.gridSize,
    required this.canAnswer,
    required this.isFeedback,
    required this.isCorrect,
    required this.phase,
    required this.replayPathIndex,
    required this.round,
    required this.selectedCell,
    required this.flyOpacity,
    required this.visibleCell,
    required this.visiblePosition,
    required this.onCellSelect,
  });

  static const _gap = 4.0;

  final int gridSize;
  final bool canAnswer;
  final bool isFeedback;
  final bool isCorrect;
  final FlyTrackPhase phase;
  final int replayPathIndex;
  final FlyTrackRound round;
  final FlyCell? selectedCell;
  final double flyOpacity;
  final FlyCell? visibleCell;
  final Offset? visiblePosition;
  final ValueChanged<FlyCell> onCellSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth =
            (constraints.maxWidth - _gap * (gridSize - 1)) / gridSize;
        final cellHeight =
            (constraints.maxHeight - _gap * (gridSize - 1)) / gridSize;
        final showTrail =
            (phase == FlyTrackPhase.replay ||
                phase == FlyTrackPhase.feedback) &&
            replayPathIndex > 0;
        final flyPosition =
            visiblePosition ??
            (visibleCell == null
                ? null
                : Offset(
                    visibleCell!.column.toDouble(),
                    visibleCell!.row.toDouble(),
                  ));

        return Stack(
          children: [
            Column(
              children: [
                for (var row = 0; row < gridSize; row++) ...[
                  if (row > 0) const SizedBox(height: _gap),
                  Expanded(
                    child: Row(
                      children: [
                        for (var column = 0; column < gridSize; column++) ...[
                          if (column > 0) const SizedBox(width: _gap),
                          Expanded(
                            child: _FlyTrackCell(
                              key: ValueKey('$row:$column'),
                              cell: FlyCell(row: row, column: column),
                              isSelected: _sameCell(
                                FlyCell(row: row, column: column),
                                selectedCell,
                              ),
                              isFinish: _sameCell(
                                FlyCell(row: row, column: column),
                                round.finish,
                              ),
                              canAnswer: canAnswer,
                              answerDelayMs: (row * gridSize + column) * 40,
                              isFeedback: isFeedback,
                              isCorrect: isCorrect,
                              onTap: () => onCellSelect(
                                FlyCell(row: row, column: column),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
            if (showTrail)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _FlyRoutePainter(
                      cellHeight: cellHeight,
                      cellWidth: cellWidth,
                      gap: _gap,
                      path: round.path.take(replayPathIndex + 1).toList(),
                    ),
                  ),
                ),
              ),
            if (flyPosition != null)
              AnimatedPositioned(
                duration: Duration(
                  milliseconds: phase == FlyTrackPhase.memorize
                      ? 240
                      : phase == FlyTrackPhase.tracking
                      ? 600
                      : 420,
                ),
                curve: const Cubic(0.77, 0, 0.175, 1),
                left: flyPosition.dx * (cellWidth + _gap),
                top: flyPosition.dy * (cellHeight + _gap),
                width: cellWidth,
                height: cellHeight,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  opacity: flyOpacity,
                  child: const IgnorePointer(child: Center(child: FlyGlyph())),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FlyRoutePainter extends CustomPainter {
  const _FlyRoutePainter({
    required this.cellHeight,
    required this.cellWidth,
    required this.gap,
    required this.path,
  });

  final double cellHeight;
  final double cellWidth;
  final double gap;
  final List<FlyCell> path;

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) {
      return;
    }

    Offset center(FlyCell cell) => Offset(
      cell.column * (cellWidth + gap) + cellWidth / 2,
      cell.row * (cellHeight + gap) + cellHeight / 2,
    );

    final route = Path()..moveTo(center(path.first).dx, center(path.first).dy);
    for (final cell in path.skip(1)) {
      final point = center(cell);
      route.lineTo(point.dx, point.dy);
    }

    final paint = Paint()
      ..color = const Color(0x73F2B84B)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final metric in route.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, (distance + 10).clamp(0, metric.length)),
          paint,
        );
        distance += 19;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FlyRoutePainter oldDelegate) {
    return oldDelegate.path != path ||
        oldDelegate.cellHeight != cellHeight ||
        oldDelegate.cellWidth != cellWidth;
  }
}

class _FlyTrackCell extends StatefulWidget {
  const _FlyTrackCell({
    super.key,
    required this.cell,
    required this.answerDelayMs,
    required this.isSelected,
    required this.isFinish,
    required this.canAnswer,
    required this.isFeedback,
    required this.isCorrect,
    required this.onTap,
  });

  final FlyCell cell;
  final int answerDelayMs;
  final bool isSelected;
  final bool isFinish;
  final bool canAnswer;
  final bool isFeedback;
  final bool isCorrect;
  final VoidCallback onTap;

  @override
  State<_FlyTrackCell> createState() => _FlyTrackCellState();
}

class _FlyTrackCellState extends State<_FlyTrackCell>
    with TickerProviderStateMixin {
  late final AnimationController _feedbackController;
  late final AnimationController _answerController;
  late final Animation<double> _shakeOffset;
  late final Animation<double> _scale;
  late final Animation<double> _answerScale;
  late final Animation<double> _answerLift;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeOffset =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -7.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 7.0, end: -4.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _feedbackController, curve: Curves.easeInOut),
        );
    _scale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _feedbackController, curve: Curves.easeInOut),
        );
    _answerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    final answerCurve = CurvedAnimation(
      parent: _answerController,
      curve: const Cubic(0.23, 1, 0.32, 1),
    );
    _answerScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.035), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.035, end: 1), weight: 1),
    ]).animate(answerCurve);
    _answerLift = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -3, end: 0), weight: 1),
    ]).animate(answerCurve);
  }

  @override
  void didUpdateWidget(_FlyTrackCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isFeedback && widget.isFeedback) {
      _maybeRunFeedbackAnimation();
    }
    if (!oldWidget.canAnswer && widget.canAnswer) {
      Future<void>.delayed(Duration(milliseconds: widget.answerDelayMs), () {
        if (mounted && widget.canAnswer) {
          _answerController.forward(from: 0);
        }
      });
    }
  }

  void _maybeRunFeedbackAnimation() {
    final isWrongSelection =
        widget.isFeedback && widget.isSelected && !widget.isCorrect;
    final isCorrectSelection =
        widget.isFeedback && widget.isFinish && widget.isCorrect;

    if (isWrongSelection || isCorrectSelection) {
      _feedbackController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWrongSelection =
        widget.isFeedback && widget.isSelected && !widget.isCorrect;
    final isCorrectSelection =
        widget.isFeedback && widget.isFinish && widget.isCorrect;

    Widget cell = AnimatedBuilder(
      animation: Listenable.merge([_feedbackController, _answerController]),
      builder: (context, child) {
        Color borderColor;
        Color backgroundColor;
        List<BoxShadow> shadows;

        if (widget.canAnswer) {
          borderColor = _FlyTrackGridState._answerBorder;
          backgroundColor = _FlyTrackGridState._answerBg;
          shadows = const [
            BoxShadow(
              color: Color(0x2EF2B84B),
              blurRadius: 22,
              offset: Offset(0, 8),
            ),
          ];
        } else if (isWrongSelection) {
          borderColor = _FlyTrackGridState._wrongBorder;
          backgroundColor = _FlyTrackGridState._wrongBg;
          shadows = const [
            BoxShadow(color: Color(0x47F43F5E), spreadRadius: 3),
          ];
        } else if (isCorrectSelection) {
          borderColor = _FlyTrackGridState._correctBorder;
          backgroundColor = _FlyTrackGridState._correctBg;
          shadows = const [
            BoxShadow(color: Color(0x4710B981), spreadRadius: 3),
          ];
        } else {
          borderColor = _FlyTrackGridState._cellBorder;
          backgroundColor = _FlyTrackGridState._cellBg;
          shadows = const [];
        }

        final feedbackScale = isCorrectSelection && widget.isCorrect
            ? _scale.value
            : 1.0;
        final scale =
            feedbackScale * (widget.canAnswer ? _answerScale.value : 1);
        final offset = isWrongSelection ? _shakeOffset.value : 0.0;

        return Transform.translate(
          offset: Offset(offset, widget.canAnswer ? _answerLift.value : 0),
          child: Transform.scale(
            scale: scale,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: borderColor, width: 2),
                boxShadow: shadows,
              ),
              child: child,
            ),
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isCorrectSelection)
            Padding(
              padding: const EdgeInsets.all(4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _FlyTrackGridState._correctBorder,
                    width: 3,
                  ),
                ),
              ),
            ),
          if (isCorrectSelection)
            const Positioned(
              right: 7,
              top: 7,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: _FlyTrackGridState._correctBorder,
                child: Icon(Icons.check_rounded, color: Colors.white, size: 17),
              ),
            ),
          if (isWrongSelection)
            Padding(
              padding: const EdgeInsets.all(4),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _FlyTrackGridState._wrongBorder,
                    width: 3,
                  ),
                ),
              ),
            ),
          if (isWrongSelection)
            const Positioned(
              right: 7,
              top: 7,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: _FlyTrackGridState._wrongBorder,
                child: Icon(Icons.close_rounded, color: Colors.white, size: 17),
              ),
            ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: widget.canAnswer ? widget.onTap : null,
        child: SizedBox.expand(child: cell),
      ),
    );
  }
}

bool _sameCell(FlyCell? left, FlyCell? right) {
  if (left == null || right == null) {
    return false;
  }

  return left.row == right.row && left.column == right.column;
}
