import 'dart:math' as math;
import 'dart:ui';

import 'package:larnes_mobile/app/theme/parent_theme.dart';

/// Web: `platform/src/trainers/reading/letter-build/build-pad-size.ts`

const buildPadSizeSvhFraction = 0.72;
const buildPadMaxWidthVwFraction = 0.85;

const buildStickColorHex = '#92400e';
const buildStickDragColorHex = '#78350f';
const buildStickSnappedColorHex = '#16a34a';
const buildGhostStrokeColorHex = '#cbd5e1';

const buildPhaseDoneColorHex = '#16A34A';
const buildPhasePendingColorHex = '#CBD5E1';
const buildPhaseActiveColorHex = '#3B6FD4';

const buildStickColor = Color(0xFF92400E);
const buildStickDragColor = Color(0xFF78350F);
const buildStickSnappedColor = Color(0xFF16A34A);
const buildGhostStrokeColor = Color(0xFFCBD5E1);
const buildPhaseDoneColor = Color(0xFF16A34A);
const buildPhasePendingColor = Color(0xFFCBD5E1);
const buildPhaseActiveColor = ParentColors.shell;

double buildPadSize(double viewportHeight, double viewportWidth) {
  final svh = viewportHeight * buildPadSizeSvhFraction;
  final vw = viewportWidth * buildPadMaxWidthVwFraction;
  return math.min(svh, vw);
}
