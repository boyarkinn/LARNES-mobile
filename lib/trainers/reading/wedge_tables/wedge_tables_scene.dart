import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:larnes_mobile/trainers/reading/wedge_tables/wedge_tables_sizes.dart';

const _fadeMs = 160;
const _fadeCurve = Cubic(0.22, 1, 0.36, 1);

/// Web: `platform/src/trainers/reading/wedge-tables/wedge-tables-scene.tsx`
class WedgeTablesScene extends StatelessWidget {
  const WedgeTablesScene({
    super.key,
    required this.left,
    required this.orientation,
    required this.right,
    required this.rowCount,
    required this.rowIndex,
    required this.rowKey,
  });

  final String left;
  final String orientation;
  final String right;
  final int rowCount;
  final int rowIndex;
  final String rowKey;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = wedgeSceneBoxSize(
          constraints.maxHeight,
          constraints.maxWidth,
        );
        final fontSize = wedgeTokenFontSize(
          constraints.maxHeight,
          constraints.maxWidth,
        );
        final shortSide = math.min(constraints.maxHeight, constraints.maxWidth);
        final armLength = getWedgeArmLength(rowIndex, rowCount, shortSide);
        final dotSize = wedgeDotSize(shortSide);
        final horizontal = orientation != 'vertical';

        return Center(
          child: SizedBox(
            width: boxSize,
            height: boxSize,
            child: Center(
              child: TweenAnimationBuilder<double>(
                key: ValueKey(rowKey),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: _fadeMs),
                curve: _fadeCurve,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: child,
                  );
                },
                child: Flex(
                  direction: horizontal ? Axis.horizontal : Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _WedgeToken(value: left, fontSize: fontSize),
                    _WedgeArm(horizontal: horizontal, length: armLength),
                    _WedgeDot(size: dotSize),
                    _WedgeArm(horizontal: horizontal, length: armLength),
                    _WedgeToken(value: right, fontSize: fontSize),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WedgeToken extends StatelessWidget {
  const _WedgeToken({required this.value, required this.fontSize});

  final String value;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: fontSize * 1.6),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: GoogleFonts.onest(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: kWedgeTokenColor,
          height: 1,
          shadows: const [
            Shadow(
              offset: Offset(0, 2),
              color: Color(0x1F1C1917),
            ),
          ],
        ),
      ),
    );
  }
}

class _WedgeArm extends StatelessWidget {
  const _WedgeArm({required this.horizontal, required this.length});

  final bool horizontal;
  final double length;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: horizontal ? length : kWedgeLineThickness,
      height: horizontal ? kWedgeLineThickness : length,
      margin: const EdgeInsets.all(2.8),
      color: kWedgeLineColor,
    );
  }
}

class _WedgeDot extends StatelessWidget {
  const _WedgeDot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: kWedgeCenterDotColor,
        shape: BoxShape.circle,
      ),
    );
  }
}
