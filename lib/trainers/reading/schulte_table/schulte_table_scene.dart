import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/trainers/reading/schulte_table/model.dart';
import 'package:larnes_mobile/trainers/reading/schulte_table/schulte_table_sizes.dart';

const _cellBg = Color(0xFFFFF8EC);
const _cellBorder = Color(0x295C4020);
const _cellInk = Color(0xFF3A2A18);
const _wrongBg = Color(0xFFFFF1F2);
const _wrongBorder = Color(0xFFFB7185);
const _wrongInk = Color(0xFFBE123C);
const _foundBg = Color(0xFFECFDF5);
const _foundBorder = Color(0xB334D399);
const _foundInk = Color(0xFF065F46);
const _centerDot = Color(0xFF22C55E);
const _pressCurve = Cubic(0.2, 0.8, 0.2, 1);

/// Web: `platform/src/trainers/reading/schulte-table/schulte-table-scene.tsx`
class SchulteTableScene extends StatelessWidget {
  const SchulteTableScene({
    super.key,
    required this.disabled,
    required this.foundValues,
    required this.onCellTap,
    required this.showCenterDot,
    required this.showFound,
    required this.symbolOrientation,
    required this.table,
    required this.wrongCellId,
  });

  final bool disabled;
  final Set<String> foundValues;
  final ValueChanged<SchulteCell> onCellTap;
  final bool showCenterDot;
  final bool showFound;
  final String symbolOrientation;
  final SchulteTable table;
  final String? wrongCellId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = schulteGridBoxSize(
          constraints.maxHeight,
          constraints.maxWidth,
        );
        final gap = schulteGridGap(table.size);
        final fontSize = schulteCellFontSize(boxSize, table.size);
        final upsideDown = symbolOrientation == 'upside-down';

        return Center(
          child: SizedBox(
            width: boxSize,
            height: boxSize,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: table.cells.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: table.size,
                    crossAxisSpacing: gap,
                    mainAxisSpacing: gap,
                  ),
                  itemBuilder: (context, index) {
                    final cell = table.cells[index];
                    final id = schulteCellId(cell);
                    final isFound = foundValues.contains(cell.value);

                    return _SchulteCellButton(
                      key: ValueKey(id),
                      cell: cell,
                      disabled: disabled || isFound,
                      fontSize: fontSize,
                      highlightFound: showFound && isFound,
                      isWrong: wrongCellId == id,
                      onTap: () => onCellTap(cell),
                      upsideDown: upsideDown,
                    );
                  },
                ),
                ),
                if (showCenterDot)
                  const IgnorePointer(
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _centerDot,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x8C22C55E),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: SizedBox(width: 8, height: 8),
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

class _SchulteCellButton extends StatefulWidget {
  const _SchulteCellButton({
    super.key,
    required this.cell,
    required this.disabled,
    required this.fontSize,
    required this.highlightFound,
    required this.isWrong,
    required this.onTap,
    required this.upsideDown,
  });

  final SchulteCell cell;
  final bool disabled;
  final double fontSize;
  final bool highlightFound;
  final bool isWrong;
  final VoidCallback onTap;
  final bool upsideDown;

  @override
  State<_SchulteCellButton> createState() => _SchulteCellButtonState();
}

class _SchulteCellButtonState extends State<_SchulteCellButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;
  var _pressed = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: kSchulteWrongShakeMs),
    );
    _shakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -7), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -7, end: 7), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 7, end: -5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5, end: 5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    if (widget.isWrong) {
      _shakeController.forward();
    }
  }

  @override
  void didUpdateWidget(_SchulteCellButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWrong && !oldWidget.isWrong) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color border;
    final Color ink;

    if (widget.isWrong) {
      background = _wrongBg;
      border = _wrongBorder;
      ink = _wrongInk;
    } else if (widget.highlightFound) {
      background = _foundBg;
      border = _foundBorder;
      ink = _foundInk;
    } else {
      background = _cellBg;
      border = _cellBorder;
      ink = _cellInk;
    }

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeOffset.value, 0),
          child: child,
        );
      },
      child: Listener(
        onPointerDown: widget.disabled
            ? null
            : (_) => setState(() => _pressed = true),
        onPointerUp: widget.disabled
            ? null
            : (_) => setState(() => _pressed = false),
        onPointerCancel: widget.disabled
            ? null
            : (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: widget.disabled
              ? 1
              : _pressed
                  ? 0.97
                  : 1,
          duration: const Duration(milliseconds: 120),
          curve: _pressCurve,
          child: Material(
            color: background,
            borderRadius: BorderRadius.circular(5.6),
            child: InkWell(
              onTap: widget.disabled ? null : widget.onTap,
              borderRadius: BorderRadius.circular(5.6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5.6),
                  border: Border.all(color: border, width: 2),
                ),
                child: Center(
                  child: Transform.rotate(
                    angle: widget.upsideDown ? math.pi : 0,
                    child: Text(
                      widget.cell.value,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.onest(
                        fontSize: widget.fontSize,
                        fontWeight: FontWeight.w700,
                        color: ink,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
