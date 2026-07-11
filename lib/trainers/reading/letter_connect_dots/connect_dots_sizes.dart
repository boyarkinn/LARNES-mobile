import 'dart:ui';

import 'package:larnes_mobile/app/theme/parent_theme.dart';
import 'package:larnes_mobile/trainers/math/digit_trace/trace_pad_size.dart';

/// Web: `platform/src/trainers/reading/letter-connect-dots/connect-dots-size.ts`

const connectDotsLineLockedColor = Color(0xFF22C55E);
const connectDotsLineWrongColor = Color(0xFFEF4444);
const connectDotsDotStrokeColor = Color(0xFF94A3B8);
const connectDotsDotActiveColor = ParentColors.shell;
const connectDotsLineDraftColor = ParentColors.shell;
const connectDotsDotNumberColor = ParentColors.shell;

double connectDotsPadSize(double viewportHeight, double viewportWidth) {
  return tracePadSize(viewportHeight, viewportWidth);
}
