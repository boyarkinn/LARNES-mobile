import 'package:larnes_mobile/trainers/math/digit_trace/digit_paths.dart';

/// Web: `platform/src/trainers/reading/letter-color/model.ts`
/// `DRAW_COLORS` — SSOT `platform/src/trainers/reading/letter-half-draw/model.ts`

typedef ColorStroke = List<TracePoint>;
typedef ColorStrokes = List<ColorStroke>;

const drawColors = [
  '#7c3aed',
  '#e11d48',
  '#2563eb',
  '#16a34a',
  '#ea580c',
  '#db2777',
];

const colorViewboxSize = 100.0;
const colorLetterFontSize = 72.0;
const colorLetterCenterX = 50.0;
const colorLetterCenterY = 56.0;

const colorOutlineStrokeHex = '#94a3b8';
const colorOutlineStrokeWidth = 1.4;
const colorOutlineDashPattern = [3.0, 3.0];
const colorStrokeWidth = 8.0;

const colorMinPointDistance = 1.2;
