import 'dart:math' as math;

import 'package:larnes_mobile/trainers/reading/letter_color/letter_color_model.dart';

/// Web: `platform/src/trainers/reading/letter-color/color-pad-size.ts`

const colorPadSizeSvhFraction = 0.72;
const colorPadMaxWidthVwFraction = 0.85;

double colorPadSize(double viewportHeight, double viewportWidth) {
  final svh = viewportHeight * colorPadSizeSvhFraction;
  final vw = viewportWidth * colorPadMaxWidthVwFraction;
  return math.min(svh, vw);
}

double colorPadSizeFromSide(double side) => colorPadSize(side, side);
