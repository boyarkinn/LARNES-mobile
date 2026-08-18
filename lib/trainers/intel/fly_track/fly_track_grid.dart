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
    required this.round,
    required this.selectedCell,
    required this.visibleCell,
  });

  final int fireworksKey;
  final int gridSize;
  final ValueChanged<FlyCell> onCellSelect;
  final FlyTrackPhase phase;
  final FlyTrackRound round;
  final FlyCell? selectedCell;
  final FlyCell visibleCell;

  @override
  State<FlyTrackGrid> createState() => _FlyTrackGridState();
}

class _FlyTrackGridState extends State<FlyTrackGrid> with TickerProviderStateMixin {
  static const _cellBg = Color(0xFFF0FDFA);
  static const _cellBorder = Color(0x3313424A);
  static const _answerBorder = Color(0xB214B8A6);
  static const _answerBg = Color(0xFFCCFBF1);
  static const _wrongBorder = Color(0xFFF43F5E);
  static const _wrongBg = Color(0xFFFFF1F2);
  static const _correctBorder = Color(0xFF10B981);
  static const _correctBg = Color(0xFFECFDF5);

  AnimationController? _pulseController;

  bool get _canAnswer => widget.phase == FlyTrackPhase.answer;

  bool get _isFeedback => widget.phase == FlyTrackPhase.feedback;

  bool get _isCorrect =>
      _sameCell(widget.selectedCell, widget.round.finish);

  @override
  void didUpdateWidget(FlyTrackGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulseController();
  }

  @override
  void initState() {
    super.initState();
    _syncPulseController();
  }

  void _syncPulseController() {
    if (_canAnswer) {
      _pulseController ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..repeat(reverse: true);
      return;
    }

    _pulseController?.dispose();
    _pulseController = null;
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pulse = _pulseController;
    final grid = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(0.0, 540.0);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width),
            child: AspectRatio(
              aspectRatio: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0x2601344E),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x290F766E),
                      blurRadius: 50,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: widget.gridSize,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: widget.gridSize * widget.gridSize,
                    itemBuilder: (context, index) {
                      final cell = FlyCell(
                        row: index ~/ widget.gridSize,
                        column: index % widget.gridSize,
                      );

                      return _FlyTrackCell(
                        key: ValueKey('${cell.row}:${cell.column}'),
                        cell: cell,
                        hasFly: _sameCell(cell, widget.visibleCell),
                        isSelected: _sameCell(cell, widget.selectedCell),
                        isFinish: _sameCell(cell, widget.round.finish),
                        canAnswer: _canAnswer,
                        isFeedback: _isFeedback,
                        isCorrect: _isCorrect,
                        pulse: pulse,
                        onTap: () => widget.onCellSelect(cell),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    return AnswerFireworksBurst(
      burstKey: widget.fireworksKey,
      child: grid,
    );
  }
}

class _FlyTrackCell extends StatefulWidget {
  const _FlyTrackCell({
    super.key,
    required this.cell,
    required this.hasFly,
    required this.isSelected,
    required this.isFinish,
    required this.canAnswer,
    required this.isFeedback,
    required this.isCorrect,
    required this.pulse,
    required this.onTap,
  });

  final FlyCell cell;
  final bool hasFly;
  final bool isSelected;
  final bool isFinish;
  final bool canAnswer;
  final bool isFeedback;
  final bool isCorrect;
  final AnimationController? pulse;
  final VoidCallback onTap;

  @override
  State<_FlyTrackCell> createState() => _FlyTrackCellState();
}

class _FlyTrackCellState extends State<_FlyTrackCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _feedbackController;
  late final Animation<double> _shakeOffset;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 7.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: -4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.easeInOut),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_FlyTrackCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isFeedback && widget.isFeedback) {
      _maybeRunFeedbackAnimation();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWrongSelection =
        widget.isFeedback && widget.isSelected && !widget.isCorrect;
    final isCorrectSelection =
        widget.isFeedback && widget.isFinish && widget.isCorrect;

    Widget cell = AnimatedBuilder(
      animation: Listenable.merge([
        if (widget.pulse != null) widget.pulse!,
        _feedbackController,
      ]),
      builder: (context, child) {
        final pulseValue = widget.canAnswer && widget.pulse != null
            ? widget.pulse!.value
            : 0.0;

        Color borderColor;
        Color backgroundColor;
        List<BoxShadow> shadows;

        if (widget.canAnswer) {
          borderColor = Color.lerp(
            _FlyTrackGridState._cellBorder,
            _FlyTrackGridState._answerBorder,
            0.35 + pulseValue * 0.65,
          )!;
          backgroundColor = Color.lerp(
            _FlyTrackGridState._cellBg,
            _FlyTrackGridState._answerBg,
            0.25 + pulseValue * 0.75,
          )!;
          shadows = [
            BoxShadow(
              color: Color.lerp(
                Colors.transparent,
                const Color(0x4714B8A6),
                0.2 + pulseValue * 0.8,
              )!,
              blurRadius: 18,
            ),
          ];
        } else if (isWrongSelection) {
          borderColor = _FlyTrackGridState._wrongBorder;
          backgroundColor = _FlyTrackGridState._wrongBg;
          shadows = const [
            BoxShadow(
              color: Color(0x47F43F5E),
              spreadRadius: 3,
            ),
          ];
        } else if (isCorrectSelection) {
          borderColor = _FlyTrackGridState._correctBorder;
          backgroundColor = _FlyTrackGridState._correctBg;
          shadows = const [
            BoxShadow(
              color: Color(0x4710B981),
              spreadRadius: 3,
            ),
          ];
        } else {
          borderColor = _FlyTrackGridState._cellBorder;
          backgroundColor = _FlyTrackGridState._cellBg;
          shadows = const [];
        }

        final scale = isCorrectSelection && widget.isCorrect
            ? _scale.value
            : 1.0;
        final offset = isWrongSelection ? _shakeOffset.value : 0.0;

        return Transform.translate(
          offset: Offset(offset, 0),
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
          if (widget.hasFly)
            const IgnorePointer(
              child: Center(child: FlyGlyph()),
            ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: widget.canAnswer ? widget.onTap : null,
        child: cell,
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
